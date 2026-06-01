"""Vital-signs socket client (currently the ngrok endpoint)."""

from __future__ import annotations

import asyncio
import logging
from typing import Any

import socketio
from PySide6.QtCore import QObject, Signal, Slot

from app import config

log = logging.getLogger(__name__)


class VitalsClient(QObject):
    vitalSignsReceived = Signal("QVariant")
    serialDataReceived = Signal("QVariant")
    connectionChanged = Signal(bool)

    def __init__(self) -> None:
        super().__init__()
        self._sio: socketio.AsyncClient | None = None

    async def start(self, url: str | None = None) -> None:
        url = url or config.VITAL_SIGNS_URL
        self._sio = socketio.AsyncClient(
            reconnection=True, reconnection_delay=1, reconnection_delay_max=5
        )
        self._sio.on("connect", lambda: self.connectionChanged.emit(True))
        self._sio.on("disconnect", lambda: self.connectionChanged.emit(False))
        self._sio.on("vitalSigns", self._on_vital_signs)
        self._sio.on("serialData", self._on_serial_data)
        asyncio.create_task(self._connect_forever(url))

    async def _connect_forever(self, url: str) -> None:
        delay = 1.0
        while self._sio is not None and not self._sio.connected:
            try:
                await self._sio.connect(url, transports=["websocket"])
                log.info("vitals connected to %s", url)
                return
            except Exception as exc:
                log.warning("vitals connect to %s failed: %s — retry in %.1fs", url, exc, delay)
                await asyncio.sleep(delay)
                delay = min(delay * 1.7, 30.0)

    async def _on_vital_signs(self, payload: Any) -> None:
        self._on_vital_signs_sync(payload)

    async def _on_serial_data(self, payload: Any) -> None:
        self._on_serial_data_sync(payload)

    def _on_vital_signs_sync(self, payload: Any) -> None:
        self.vitalSignsReceived.emit(payload)

    def _on_serial_data_sync(self, payload: Any) -> None:
        self.serialDataReceived.emit(payload)

    @Slot(str)
    def serialSend(self, command: str) -> None:
        if self._sio is None:
            log.warning("serialSend called before start()")
            return
        asyncio.create_task(self._sio.emit("serialSend", command))
