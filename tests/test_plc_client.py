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


# ---- Reconnect replay / command-delivery race ----
#
# python-socketio sets `sio.connected = True` only at the very END of its
# connect() coroutine — AFTER it has registered the namespace and fired our
# `connect` handler (which replays the offline queue). So at replay time the
# flag still reads False even though emit() already works. Gating _safe_emit on
# sio.connected therefore re-queued every replayed command forever: the root
# cause of "socket.io sometimes doesn't transmit commands".

@pytest.mark.asyncio
async def test_safe_emit_sends_even_when_connected_flag_false(qapp):
    """_safe_emit must not gate on sio.connected. During the connect event the
    namespace is registered (emit succeeds) but the flag still reads False."""
    s = AppState()
    client = PlcClient(s)
    sio = MagicMock()
    sio.connected = False           # the connect-race condition
    sio.emit = AsyncMock()
    client._sio = sio
    await client._safe_emit("writeRegister", {"register": "R01700", "value": 200})
    sio.emit.assert_awaited_once_with(
        "writeRegister", {"register": "R01700", "value": 200}
    )
    assert client._pending_emits == []


@pytest.mark.asyncio
async def test_reconnect_replays_and_delivers_queued_command(qapp):
    """A command queued while offline must actually be delivered on the next
    connect — even though sio.connected is still False when the replay runs."""
    s = AppState()
    client = PlcClient(s)
    client._pending_emits = [("writeRegister", {"register": "R01704", "value": 255})]
    sio = MagicMock()
    sio.connected = False
    sio.emit = AsyncMock()
    client._sio = sio
    client._on_connect_sync()       # schedules the replay via create_task
    await asyncio.sleep(0)
    await asyncio.sleep(0)
    sio.emit.assert_awaited_once_with(
        "writeRegister", {"register": "R01704", "value": 255}
    )
    assert client._pending_emits == []
    client._stop_keepalive()


@pytest.mark.asyncio
async def test_safe_emit_requeues_when_emit_raises(qapp):
    """When the socket is genuinely down, emit raises and the command must be
    stashed for the next replay (not silently lost)."""
    s = AppState()
    client = PlcClient(s)
    sio = MagicMock()
    sio.connected = False
    sio.emit = AsyncMock(side_effect=RuntimeError("/ is not a connected namespace"))
    client._sio = sio
    await client._safe_emit("writeBit", {"register": "M0072", "value": 1})
    sio.emit.assert_awaited_once()
    assert client._pending_emits == [("writeBit", {"register": "M0072", "value": 1})]
