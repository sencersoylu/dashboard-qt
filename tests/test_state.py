from app.state import AppState


def test_default_values(qapp):
    s = AppState()
    # Verified against renderer/store.ts lines 170–228.
    assert s.darkMode is True
    assert s.connected is False
    assert s.lightStatus == 0
    assert s.fan1Status == 0
    assert s.fan2Status == 0
    assert s.autoMode is False
    assert s.airMode is False
    assert s.ventilMode == 0
    assert s.light2Status == 0
    assert s.valve1Status is False
    assert s.valve2Status is False
    assert s.playing is False
    assert s.showAuxPanel is False
    assert s.showCalibrationModal is False
    assert s.showErrorModal is False
    assert s.showSeatAlarmModal is False
    assert s.showChillerModal is False
    assert s.calibrationProgress == 0
    assert s.calibrationStatus == ""
    assert s.errorMessage == ""
    assert s.chillerRunning is False
    assert s.chillerCurrentTemp == 20.0
    assert s.chillerSetTemp == 20.0
    assert s.chillerCommError is False
    assert s.lp1Status is True
    assert s.lp2Status is True
    assert s.hp1Status is True
    assert s.hpCylinderPressure == 120
    assert s.airTankPressure == 12.1
    assert s.nitrogen1Pressure == 120
    assert s.nitrogen2Pressure == 120
    assert s.mainFssLevel == 60
    assert s.mainFssPressure == 12.1
    assert s.mainFssActive is True
    assert s.anteFssLevel == 60
    assert s.anteFssPressure == 12.1
    assert s.anteFssActive is False
    assert s.anteFssWarning is True
    assert s.primaryO2Pressure == 120
    assert s.secondaryO2Pressure == 120
    assert s.liquidO2Pressure == 120
    assert s.primaryO2Active is True
    assert s.secondaryO2Active is False
    assert s.liquidO2Active is False
    assert s.mainFssAlarm is False
    assert s.anteFssAlarm is False
    assert s.mainFlameDetected is False
    assert s.mainSmokeDetected is False
    assert s.anteSmokeDetected is False
    assert s.mainHighO2 is False
    assert s.anteHighO2 is False
    assert s.currentTime == ""
    assert s.currentTime2 == ""
    assert s.seatPressures == [0.5] * 12
    assert s.activeSeatAlarm is None
    # ---- New Qt-only fields (chamber sensors + tech) — start at 0.0 ----
    assert s.mainPressure == 0.0
    assert s.mainO2 == 0.0
    assert s.mainTemp == 0.0
    assert s.mainHumidity == 0.0
    assert s.antePressure == 0.0
    assert s.anteO2 == 0.0
    assert s.anteTemp == 0.0
    assert s.anteHumidity == 0.0
    assert s.techO2Pressure == 0.0
    assert s.anteFssNitrogenPressure == 0.0


def test_setter_emits_signal(qapp):
    s = AppState()
    calls = []
    s.darkModeChanged.connect(lambda: calls.append(s.darkMode))
    s.darkMode = False
    assert calls == [False]
    # No re-emit when value unchanged
    s.darkMode = False
    assert calls == [False]


def test_persistence_round_trip(qapp):
    s1 = AppState()
    s1.darkMode = False
    s1.lightStatus = 200
    s1.fan1Status = 128
    s1.autoMode = True
    s1.valve1Status = True

    s2 = AppState()
    assert s2.darkMode is False
    assert s2.lightStatus == 200
    assert s2.fan1Status == 128
    assert s2.autoMode is True
    assert s2.valve1Status is True


def test_ephemeral_not_persisted(qapp):
    s1 = AppState()
    s1.connected = True
    s1.calibrationProgress = 42
    s1.errorMessage = "boom"

    s2 = AppState()
    # Ephemeral fields reset to defaults
    assert s2.connected is False
    assert s2.calibrationProgress == 0
    assert s2.errorMessage == ""


def test_seat_pressures_list(qapp):
    s = AppState()
    captured = []
    s.seatPressuresChanged.connect(lambda: captured.append(list(s.seatPressures)))
    s.seatPressures = [1.0] * 12
    assert captured == [[1.0] * 12]
    assert s.seatPressures == [1.0] * 12


def test_active_seat_alarm(qapp):
    s = AppState()
    assert s.activeSeatAlarm is None
    s.activeSeatAlarm = {"seatNumber": 21}
    assert s.activeSeatAlarm == {"seatNumber": 21}
    s.activeSeatAlarm = None
    assert s.activeSeatAlarm is None
