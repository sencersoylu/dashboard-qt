from app.plc_data_map import apply_data_array, DATA_INDEX
from app.state import AppState


def test_index_constants():
    assert DATA_INDEX["mainPressure"] == 0
    assert DATA_INDEX["mainO2"] == 1
    assert DATA_INDEX["mainTemp"] == 2
    assert DATA_INDEX["anteHumidity"] == 3
    assert DATA_INDEX["antePressure"] == 4
    assert DATA_INDEX["anteO2"] == 5
    assert DATA_INDEX["anteTemp"] == 6
    assert DATA_INDEX["mainHumidity"] == 7
    assert DATA_INDEX["techO2Pressure"] == 9
    assert DATA_INDEX["mainFssPressure"] == 10
    assert DATA_INDEX["mainFssLevel"] == 11
    assert DATA_INDEX["anteFssPressure"] == 12
    assert DATA_INDEX["anteFssLevel"] == 13
    assert DATA_INDEX["chillerCurrentTempRaw"] == 15
    assert DATA_INDEX["primaryO2Pressure"] == 20
    assert DATA_INDEX["secondaryO2Pressure"] == 21
    assert DATA_INDEX["nitrogen1Pressure"] == 22
    assert DATA_INDEX["nitrogen2Pressure"] == 23
    assert DATA_INDEX["anteFssNitrogenPressure"] == 24
    assert DATA_INDEX["airTankPressure"] == 30
    assert "data8_deprecated" not in DATA_INDEX
    assert all(k not in DATA_INDEX for k in ("seatAlarmRaw", "chillerLink", "chillerSetTempRaw", "chillerStatusFlag"))


def test_apply_data_array_writes_chamber_fields(qapp):
    s = AppState()
    payload = [0.0] * 31
    payload[0] = 1.5
    payload[1] = 21.0
    payload[2] = 22.5
    payload[3] = 55.0
    payload[4] = 1.6
    payload[5] = 20.9
    payload[6] = 23.1
    payload[7] = 50.0
    apply_data_array(s, payload)
    assert s.mainPressure == 1.5
    assert s.mainO2 == 21.0
    assert s.mainTemp == 22.5
    assert s.anteHumidity == 55.0
    assert s.antePressure == 1.6
    assert s.anteO2 == 20.9
    assert s.anteTemp == 23.1
    assert s.mainHumidity == 50.0


def test_apply_data_array_writes_tech_fields(qapp):
    s = AppState()
    payload = [0.0] * 31
    payload[9]  = 200
    payload[10] = 4.2
    payload[11] = 75
    payload[12] = 4.0
    payload[13] = 70
    payload[20] = 250
    payload[21] = 240
    payload[22] = 230
    payload[23] = 220
    payload[24] = 210
    payload[30] = 12.5
    apply_data_array(s, payload)
    assert s.techO2Pressure == 200
    assert s.mainFssPressure == 4.2
    assert s.mainFssLevel == 75
    assert s.anteFssPressure == 4.0
    assert s.anteFssLevel == 70
    assert s.primaryO2Pressure == 250
    assert s.secondaryO2Pressure == 240
    assert s.nitrogen1Pressure == 230
    assert s.nitrogen2Pressure == 220
    assert s.anteFssNitrogenPressure == 210
    assert s.airTankPressure == 12.5


def test_chiller_current_temp_from_data15_divided_by_10(qapp):
    s = AppState()
    payload = [0.0] * 31
    payload[15] = 185
    apply_data_array(s, payload)
    assert s.chillerCurrentTemp == 18.5


def test_apply_data_array_short_payload_is_safe(qapp):
    s = AppState()
    apply_data_array(s, [1.0] * 10)
    assert s.nitrogen1Pressure == 120
    assert s.airTankPressure == 12.1


def test_apply_alarm_bits_unpacks_data19(qapp):
    s = AppState()
    payload = [0] * 31
    payload[19] = (1 << 2) | (1 << 5) | (1 << 8)
    apply_data_array(s, payload)
    assert s.mainFssAlarm is True
    assert s.anteFssAlarm is False
    assert s.mainSmokeDetected is True
    assert s.anteHighO2 is True
    assert s.mainFlameDetected is False


def test_alarm_master_gate_opens_error_modal(qapp):
    """Master bit (0) + error bit (4 = main flame) opens the error modal
    with the matching message."""
    s = AppState()
    payload = [0.0] * 31
    payload[19] = (1 << 0) | (1 << 4)  # master + main flame
    apply_data_array(s, payload)
    assert s.showErrorModal is True
    assert "Flame" in s.errorMessage
    assert s.mainFlameDetected is True


def test_alarm_master_off_closes_error_modal(qapp):
    """When the master gate drops the modal state resets, but per-bit
    flags continue to reflect the raw word."""
    s = AppState()
    s.showErrorModal = True
    s.errorMessage = "stale"
    s.showSeatAlarmModal = True
    payload = [0.0] * 31
    payload[19] = 1 << 4  # bit 4 set but master (bit 0) is 0
    apply_data_array(s, payload)
    assert s.showErrorModal is False
    assert s.errorMessage == ""
    assert s.showSeatAlarmModal is False
    # raw bit still mirrors
    assert s.mainFlameDetected is True


def test_alarm_seat_bit_opens_seat_modal(qapp):
    """Bit 1 (seat) + data[16] seat ID populates activeSeatAlarm."""
    s = AppState()
    payload = [0.0] * 31
    payload[19] = (1 << 0) | (1 << 1)  # master + seat
    payload[16] = 21  # nurse
    apply_data_array(s, payload)
    assert s.showSeatAlarmModal is True
    assert s.activeSeatAlarm.get("seatNumber") == "Nurse"


def test_alarm_first_bit_wins_modal_slot(qapp):
    """When several error bits are set together, the lowest one (per
    the React elif chain) decides the displayed message."""
    s = AppState()
    payload = [0.0] * 31
    # master + bit 5 (main smoke) + bit 7 (main high O2) — smoke wins
    payload[19] = (1 << 0) | (1 << 5) | (1 << 7)
    apply_data_array(s, payload)
    assert s.showErrorModal is True
    assert "Smoke" in s.errorMessage


def test_alarm_suppression_holds_modal_closed(qapp):
    """After the user dismisses, errorModalSuppressed stays set until
    the master gate (bit 0) drops, even if error bits are still high."""
    s = AppState()
    # Simulate: alarm active, user dismissed (suppressed=True, modal closed)
    s.errorModalSuppressed = True
    s.showErrorModal = False
    payload = [0.0] * 31
    payload[19] = (1 << 0) | (1 << 4)  # master still high + main flame
    apply_data_array(s, payload)
    # Modal must stay closed because of suppression
    assert s.showErrorModal is False
    assert s.errorModalSuppressed is True
    # Now master drops to 0
    payload[19] = 0
    apply_data_array(s, payload)
    # Suppression lifted, modal still closed (no bit set)
    assert s.errorModalSuppressed is False
    # Next master-on alarm reopens
    payload[19] = (1 << 0) | (1 << 4)
    apply_data_array(s, payload)
    assert s.showErrorModal is True


def test_data8_is_not_written_anymore(qapp):
    s = AppState()
    s.airTankPressure = 99.0
    payload = [0.0] * 31
    payload[8] = 1.0
    payload[30] = 8.0
    apply_data_array(s, payload)
    assert s.airTankPressure == 8.0
