import asyncio
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.bcontrol_client import BControlClient


def test_telemetry_emits_signal(qapp):
    c = BControlClient()
    received = []
    c.telemetryReceived.connect(lambda payload: received.append(payload))
    c._on_telemetry_sync({"pressure": 1.4, "temp": 22.0})
    assert received == [{"pressure": 1.4, "temp": 22.0}]


def test_status_emits_signal(qapp):
    c = BControlClient()
    received = []
    c.statusReceived.connect(lambda payload: received.append(payload))
    c._on_status_sync({"connected": True, "profile": "default"})
    assert received == [{"connected": True, "profile": "default"}]


@pytest.mark.asyncio
async def test_control_emits_command(qapp):
    c = BControlClient()
    c._sio = MagicMock()
    c._sio.emit = AsyncMock()
    c.control("ON")
    await asyncio.sleep(0)
    await asyncio.sleep(0)
    c._sio.emit.assert_called_with("control", {"cmd": "ON"})
