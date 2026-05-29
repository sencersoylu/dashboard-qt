"""Socket.io client for the PLC bridge at 192.168.3.100:4000.

Public surface (callable from QML):
- writeRegister(register: str, value: int)
- writeBit(register: str, value: int)

Inbound events update AppState via sync helpers (`_on_*_sync`) so they can be
unit-tested without an event loop.
"""

from __future__ import annotations

import asyncio
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

    async def start(self, url: str | None = None) -> None:
        url = url or config.PLC_URL
        self._sio = socketio.AsyncClient(
            reconnection=True,
            reconnection_delay=1,
            reconnection_delay_max=5,
        )
        self._sio.on("connect", self._on_connect)
        self._sio.on("disconnect", self._on_disconnect)
        self._sio.on("data", self._on_data)
        self._sio.on("chillerData", self._on_chiller_data)
        self._sio.on("calibrationProgress", self._on_calibration)
        self._sio.on("seatAlarm", self._on_seat_alarm)
        try:
            await self._sio.connect(url, transports=["websocket", "polling"])
        except Exception as exc:
            log.warning("PLC initial connect failed (library will keep retrying): %s", exc)

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

    def _on_disconnect_sync(self) -> None:
        self._state.connected = False
        self.connectionChanged.emit(False)

    def _on_data_sync(self, payload: Any) -> None:
        if not isinstance(payload, dict):
            log.warning("PLC data: unexpected payload type %s", type(payload))
            return
        data = payload.get("data") or []
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
        if not isinstance(payload, dict):
            return
        if "currentTemp" in payload:
            self._state.chillerCurrentTemp = float(payload["currentTemp"]) / 10.0

    def _on_calibration_sync(self, payload: Any) -> None:
        if not isinstance(payload, dict):
            return
        if "progress" in payload:
            self._state.calibrationProgress = int(payload["progress"])
        if "status" in payload:
            self._state.calibrationStatus = str(payload["status"])

    def _on_seat_alarm_sync(self, payload: Any) -> None:
        if not isinstance(payload, dict):
            return
        self._state.activeSeatAlarm = payload
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
            self._sio.emit("writeRegister", {"register": register, "value": value})
        )

    @Slot(str, int)
    def writeBit(self, register: str, value: int) -> None:
        """Emit a writeBit command. See `writeRegister` for the loop note."""
        if self._sio is None:
            log.warning("writeBit called before start()")
            return
        asyncio.create_task(
            self._sio.emit("writeBit", {"register": register, "value": value})
        )
