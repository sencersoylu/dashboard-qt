import asyncio
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.vitals_client import VitalsClient


def test_vital_signs_emits(qapp):
    c = VitalsClient()
    received = []
    c.vitalSignsReceived.connect(lambda p: received.append(p))
    c._on_vital_signs_sync({"heartRate": "72", "oxygenSaturation": "98", "bloodPressure": "120/80"})
    assert received == [
        {"heartRate": "72", "oxygenSaturation": "98", "bloodPressure": "120/80"}
    ]


def test_serial_data_emits(qapp):
    c = VitalsClient()
    received = []
    c.serialDataReceived.connect(lambda p: received.append(p))
    c._on_serial_data_sync("RAW123")
    assert received == ["RAW123"]


@pytest.mark.asyncio
async def test_send_command(qapp):
    c = VitalsClient()
    c._sio = MagicMock()
    c._sio.emit = AsyncMock()
    c.serialSend("M")
    await asyncio.sleep(0)
    await asyncio.sleep(0)
    c._sio.emit.assert_called_with("serialSend", "M")
