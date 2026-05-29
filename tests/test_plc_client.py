import asyncio
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.plc_client import PlcClient
from app.state import AppState


def test_data_event_writes_state(qapp):
    s = AppState()
    client = PlcClient(s)
    payload = {"isConnectedPLC": 1, "data": [0.0] * 31}
    payload["data"][10] = 3.3
    payload["data"][11] = 50
    client._on_data_sync(payload)
    assert s.mainFssPressure == 3.3
    assert s.mainFssLevel == 50


def test_chiller_data_event_only_uses_current_temp(qapp):
    s = AppState()
    client = PlcClient(s)
    s.chillerRunning = False
    client._on_chiller_data_sync({"currentTemp": 185, "running": True})
    assert s.chillerCurrentTemp == 18.5
    assert s.chillerRunning is False


def test_chiller_comm_error_when_data27_is_10(qapp):
    s = AppState()
    client = PlcClient(s)
    payload = {"isConnectedPLC": 1, "data": [0.0] * 31}
    payload["data"][27] = 10
    payload["data"][28] = 55
    payload["data"][29] = 1
    client._on_data_sync(payload)
    assert s.chillerCommError is True


def test_chiller_set_temp_and_run_flag_from_data(qapp):
    s = AppState()
    client = PlcClient(s)
    payload = {"isConnectedPLC": 1, "data": [0.0] * 31}
    payload["data"][27] = 0
    payload["data"][28] = 55
    payload["data"][29] = 1
    client._on_data_sync(payload)
    assert s.chillerCommError is False
    assert s.chillerSetTemp == 5.5
    assert s.chillerRunning is True


def test_chiller_not_running_when_data29_bit0_clear(qapp):
    s = AppState()
    client = PlcClient(s)
    payload = {"isConnectedPLC": 1, "data": [0.0] * 31}
    payload["data"][27] = 0
    payload["data"][28] = 200
    payload["data"][29] = 0b10
    client._on_data_sync(payload)
    assert s.chillerRunning is False
    assert s.chillerSetTemp == 20.0


def test_chiller_pv_from_data15(qapp):
    s = AppState()
    client = PlcClient(s)
    payload = {"isConnectedPLC": 1, "data": [0.0] * 31}
    payload["data"][15] = 192
    payload["data"][27] = 0
    client._on_data_sync(payload)
    assert s.chillerCurrentTemp == 19.2


def test_calibration_progress(qapp):
    s = AppState()
    client = PlcClient(s)
    client._on_calibration_sync({"progress": 42, "status": "Calibrating..."})
    assert s.calibrationProgress == 42
    assert s.calibrationStatus == "Calibrating..."


def test_seat_alarm(qapp):
    s = AppState()
    client = PlcClient(s)
    client._on_seat_alarm_sync({"seatNumber": 21})
    assert s.activeSeatAlarm == {"seatNumber": 21}
    assert s.showSeatAlarmModal is True


def test_connection_state_tracks_socket(qapp):
    s = AppState()
    client = PlcClient(s)
    client._on_connect_sync()
    assert s.connected is True
    client._on_disconnect_sync()
    assert s.connected is False


@pytest.mark.asyncio
async def test_write_register_emits(qapp):
    s = AppState()
    client = PlcClient(s)
    client._sio = MagicMock()
    client._sio.emit = AsyncMock()
    client.writeRegister("R01700", 200)
    await asyncio.sleep(0)
    await asyncio.sleep(0)
    client._sio.emit.assert_called_with(
        "writeRegister", {"register": "R01700", "value": 200}
    )


@pytest.mark.asyncio
async def test_write_bit_emits(qapp):
    s = AppState()
    client = PlcClient(s)
    client._sio = MagicMock()
    client._sio.emit = AsyncMock()
    client.writeBit("M0202", 1)
    await asyncio.sleep(0)
    await asyncio.sleep(0)
    client._sio.emit.assert_called_with(
        "writeBit", {"register": "M0202", "value": 1}
    )


def test_chiller_state_skips_on_string_payload(qapp):
    """data[28] / data[29] arriving as non-numeric strings must not crash."""
    s = AppState()
    client = PlcClient(s)
    payload = {"isConnectedPLC": 1, "data": [0.0] * 31}
    payload["data"][27] = 0           # link OK
    payload["data"][28] = "abc"       # garbage (float("NaN") returns nan, not raises)
    payload["data"][29] = "??"        # garbage
    # Must not raise
    client._on_data_sync(payload)
    # chillerCommError still False, setTemp/running untouched (defaults)
    assert s.chillerCommError is False
    assert s.chillerSetTemp == 20.0    # default unchanged
    assert s.chillerRunning is False   # default unchanged


def test_chiller_state_skips_when_data27_is_string(qapp):
    s = AppState()
    client = PlcClient(s)
    payload = {"isConnectedPLC": 1, "data": [0.0] * 31}
    payload["data"][27] = "bad"
    payload["data"][28] = 55
    payload["data"][29] = 1
    client._on_data_sync(payload)
    # Bailed early; nothing chiller-related changed.
    assert s.chillerCommError is False
    assert s.chillerSetTemp == 20.0
    assert s.chillerRunning is False
