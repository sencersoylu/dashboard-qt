"""Socket.io client for the PLC bridge at 192.168.77.100:4000.

Public surface (callable from QML):
- writeRegister(register: str, value: int)
- writeBit(register: str, value: int)

Inbound events update AppState via sync helpers (`_on_*_sync`) so they can be
unit-tested without an event loop.
"""

from __future__ import annotations

import asyncio
import json
import logging
from typing import Any

import socketio
from PySide6.QtCore import QObject, Signal, Slot

from app import config
from app.plc_data_map import apply_data_array
from app.state import AppState

log = logging.getLogger(__name__)

# Chiller indices (memory: "Chiller link / run state (2026-05-26)").
_CHILLER_LINK_INDEX = 27          # === 10 -> comm error
_CHILLER_LINK_COMM_ERROR = 10
_CHILLER_SET_TEMP_INDEX = 28      # raw / 10 = C
_CHILLER_SET_TEMP_DIVISOR = 10.0
_CHILLER_STATUS_FLAG_INDEX = 29   # bit 0 = running


class PlcClient(QObject):
    connectionChanged = Signal(bool)

    def __init__(self, state: AppState) -> None:
        super().__init__()
        self._state = state
        self._sio: socketio.AsyncClient | None = None
        # Commands invoked while the socket is briefly down (during a
        # reconnect cycle) are queued here and replayed in order on the
        # next successful connect. Without this, the underlying emit
        # would raise BadNamespaceError, the create_task would swallow
        # the failure, and the operator's button press would silently
        # vanish.
        self._pending_emits: list[tuple[str, dict]] = []

    async def start(self, url: str | None = None) -> None:
        url = url or config.PLC_URL
        self._sio = socketio.AsyncClient(
            reconnection=True,
            reconnection_delay=1,
            reconnection_delay_max=5,
            randomization_factor=0.5,
        )
        self._sio.on("connect", self._on_connect)
        self._sio.on("disconnect", self._on_disconnect)
        self._sio.on("data", self._on_data)
        self._sio.on("chillerData", self._on_chiller_data)
        self._sio.on("calibrationProgress", self._on_calibration)
        self._sio.on("seatAlarm", self._on_seat_alarm)
        # Spawn a background task that keeps retrying the initial connect
        # until it lands. Once connected, python-socketio's own reconnection
        # loop takes over for any later drops.
        asyncio.create_task(self._connect_forever(url))

    async def _connect_forever(self, url: str) -> None:
        delay = 1.0
        while self._sio is not None and not self._sio.connected:
            try:
                # websocket-only avoids the polling → websocket upgrade
                # dance that surfaces as transient disconnect+connect blips
                # on the UI badge.
                await self._sio.connect(url, transports=["websocket"])
                log.info("PLC connected to %s", url)
                return
            except Exception as exc:
                log.warning("PLC connect to %s failed: %s — retry in %.1fs", url, exc, delay)
                await asyncio.sleep(delay)
                delay = min(delay * 1.7, 30.0)

    async def _on_connect(self) -> None:
        self._on_connect_sync()

    async def _on_disconnect(self) -> None:
        self._on_disconnect_sync()

    async def _on_data(self, payload: Any) -> None:
        self._on_data_sync(payload)

    async def _on_chiller_data(self, payload: Any) -> None:
        self._on_chiller_data_sync(payload)

    async def _on_calibration(self, payload: Any) -> None:
        self._on_calibration_sync(payload)

    async def _on_seat_alarm(self, payload: Any) -> None:
        self._on_seat_alarm_sync(payload)

    def _on_connect_sync(self) -> None:
        self._state.connected = True
        self.connectionChanged.emit(True)
        log.info("PLC socket connected")
        # Flush any commands that arrived while we were offline.
        if self._pending_emits:
            log.info("Replaying %d queued PLC commands", len(self._pending_emits))
            queued = self._pending_emits
            self._pending_emits = []
            for event, payload in queued:
                asyncio.create_task(self._safe_emit(event, payload))

    def _on_disconnect_sync(self) -> None:
        self._state.connected = False
        self.connectionChanged.emit(False)
        log.info("PLC socket disconnected")

    async def _safe_emit(self, event: str, payload: dict) -> None:
        """Emit, but on any socket-level failure stash the call for replay
        when we reconnect. Keeps fire-and-forget call sites simple while
        guaranteeing the command isn't silently lost."""
        sio = self._sio
        if sio is None or not sio.connected:
            self._pending_emits.append((event, payload))
            log.info("PLC offline — queued %s %s (q=%d)",
                     event, payload, len(self._pending_emits))
            return
        try:
            await sio.emit(event, payload)
        except Exception as exc:
            self._pending_emits.append((event, payload))
            log.warning("PLC emit %s %s failed (%s); requeued (q=%d)",
                        event, payload, exc, len(self._pending_emits))

    @staticmethod
    def _as_dict(payload: Any) -> dict | None:
        """Bridge sends JSON-encoded strings on some events; mirror the
        React app's `JSON.parse(data)` step. Returns None on anything that
        isn't a dict or a JSON string that decodes to a dict."""
        if isinstance(payload, dict):
            return payload
        if isinstance(payload, str):
            try:
                parsed = json.loads(payload)
            except (ValueError, TypeError):
                return None
            if isinstance(parsed, dict):
                return parsed
        return None

    def _on_data_sync(self, payload: Any) -> None:
        doc = self._as_dict(payload)
        if doc is None:
            log.warning("PLC data: unexpected payload type %s", type(payload))
            return
        data = doc.get("data") or []
        if not isinstance(data, list):
            log.warning("PLC data: 'data' is not a list")
            return
        apply_data_array(self._state, data)
        self._apply_chiller_state(data)

    def _apply_chiller_state(self, data: list) -> None:
        """Three-index correlated logic for chiller link / set / run.

        Contract: when `data[27] == 10` (bridge unreachable) we hold the last
        known `chillerSetTemp` and `chillerRunning` values rather than zeroing
        them. QML must gate display on `chillerCommError` so users don't see
        stale numbers. This matches the React app's "mask as `--- °C`" pattern.

        Defensive: malformed (non-numeric) entries are logged and skipped so a
        single bad frame doesn't take down the socket handler.
        """
        n = len(data)
        if n <= _CHILLER_LINK_INDEX:
            return
        try:
            link = int(data[_CHILLER_LINK_INDEX])
        except (TypeError, ValueError):
            log.warning("PLC data[27] not numeric: %r", data[_CHILLER_LINK_INDEX])
            return
        if link == _CHILLER_LINK_COMM_ERROR:
            self._state.chillerCommError = True
            return
        self._state.chillerCommError = False
        if n > _CHILLER_SET_TEMP_INDEX:
            try:
                self._state.chillerSetTemp = (
                    float(data[_CHILLER_SET_TEMP_INDEX]) / _CHILLER_SET_TEMP_DIVISOR
                )
            except (TypeError, ValueError):
                log.warning("PLC data[28] not numeric: %r", data[_CHILLER_SET_TEMP_INDEX])
        if n > _CHILLER_STATUS_FLAG_INDEX:
            try:
                self._state.chillerRunning = bool(
                    int(data[_CHILLER_STATUS_FLAG_INDEX]) & 1
                )
            except (TypeError, ValueError):
                log.warning("PLC data[29] not numeric: %r", data[_CHILLER_STATUS_FLAG_INDEX])

    def _on_chiller_data_sync(self, payload: Any) -> None:
        """Only `currentTemp` is used. `running` is read from data[29] instead."""
        doc = self._as_dict(payload)
        if doc is None:
            return
        if "currentTemp" in doc:
            self._state.chillerCurrentTemp = float(doc["currentTemp"]) / 10.0

    def _on_calibration_sync(self, payload: Any) -> None:
        doc = self._as_dict(payload)
        if doc is None:
            return
        if "progress" in doc:
            self._state.calibrationProgress = int(doc["progress"])
        if "status" in doc:
            self._state.calibrationStatus = str(doc["status"])

    def _on_seat_alarm_sync(self, payload: Any) -> None:
        doc = self._as_dict(payload)
        if doc is None:
            return
        self._state.activeSeatAlarm = doc
        self._state.showSeatAlarmModal = True

    @Slot(str, int)
    def writeRegister(self, register: str, value: int) -> None:
        """Emit a writeRegister command.

        Phase 3 gating note: this schedules with `asyncio.create_task`, which
        requires a running asyncio loop on the calling thread. With qasync
        wired in Bundle E the Qt thread IS the asyncio thread, so this works
        from QML slots. If a future refactor moves QML invocations off the
        main loop, switch to `asyncio.run_coroutine_threadsafe(..., loop)`.
        """
        if self._sio is None:
            log.warning("writeRegister called before start()")
            return
        asyncio.create_task(
            self._safe_emit("writeRegister", {"register": register, "value": value})
        )

    @Slot(str, int)
    def writeBit(self, register: str, value: int) -> None:
        """Emit a writeBit command. See `writeRegister` for the loop note."""
        if self._sio is None:
            log.warning("writeBit called before start()")
            return
        asyncio.create_task(
            self._safe_emit("writeBit", {"register": register, "value": value})
        )
