"""Single source of UI state. Mirrors renderer/store.ts one-to-one."""

from __future__ import annotations

from typing import Any

from PySide6.QtCore import Property, QObject, QSettings, Signal


# Fields that survive restarts (matches Zustand `persist` behavior in store.ts).
_PERSISTED: set[str] = {
    "darkMode",
    "lightStatus",
    "light2Status",
    "fan1Status",
    "fan2Status",
    "autoMode",
    "airMode",
    "ventilMode",
    "valve1Status",
    "valve2Status",
    "playing",
    "chillerSetTemp",
}


class AppState(QObject):
    """The Zustand store, ported to a single QObject.

    Each field is exposed as a QProperty + matching `<field>Changed` Signal.
    Persisted fields are written through `QSettings("soylu", "rsp-qt")`.
    """

    # -- signals declared once at class level so QML bindings can find them --
    darkModeChanged = Signal()
    connectedChanged = Signal()
    currentTimeChanged = Signal()
    currentTime2Changed = Signal()
    showAuxPanelChanged = Signal()
    showCalibrationModalChanged = Signal()
    showErrorModalChanged = Signal()
    showSeatAlarmModalChanged = Signal()
    showChillerModalChanged = Signal()
    calibrationProgressChanged = Signal()
    calibrationStatusChanged = Signal()
    errorMessageChanged = Signal()
    lightStatusChanged = Signal()
    light2StatusChanged = Signal()
    fan1StatusChanged = Signal()
    fan2StatusChanged = Signal()
    autoModeChanged = Signal()
    airModeChanged = Signal()
    ventilModeChanged = Signal()
    valve1StatusChanged = Signal()
    valve2StatusChanged = Signal()
    playingChanged = Signal()
    chillerRunningChanged = Signal()
    chillerCurrentTempChanged = Signal()
    chillerSetTempChanged = Signal()
    chillerCommErrorChanged = Signal()
    lp1StatusChanged = Signal()
    lp2StatusChanged = Signal()
    hp1StatusChanged = Signal()
    hpCylinderPressureChanged = Signal()
    airTankPressureChanged = Signal()
    nitrogen1PressureChanged = Signal()
    nitrogen2PressureChanged = Signal()
    mainFssLevelChanged = Signal()
    mainFssPressureChanged = Signal()
    mainFssActiveChanged = Signal()
    anteFssLevelChanged = Signal()
    anteFssPressureChanged = Signal()
    anteFssActiveChanged = Signal()
    anteFssWarningChanged = Signal()
    primaryO2PressureChanged = Signal()
    secondaryO2PressureChanged = Signal()
    liquidO2PressureChanged = Signal()
    primaryO2ActiveChanged = Signal()
    secondaryO2ActiveChanged = Signal()
    liquidO2ActiveChanged = Signal()
    mainFssAlarmChanged = Signal()
    anteFssAlarmChanged = Signal()
    mainFlameDetectedChanged = Signal()
    mainSmokeDetectedChanged = Signal()
    anteSmokeDetectedChanged = Signal()
    mainHighO2Changed = Signal()
    anteHighO2Changed = Signal()
    seatPressuresChanged = Signal()
    activeSeatAlarmChanged = Signal()
    # ---- New Qt-only fields ----
    mainPressureChanged = Signal()
    mainO2Changed = Signal()
    mainTempChanged = Signal()
    mainHumidityChanged = Signal()
    antePressureChanged = Signal()
    anteO2Changed = Signal()
    anteTempChanged = Signal()
    anteHumidityChanged = Signal()
    techO2PressureChanged = Signal()
    anteFssNitrogenPressureChanged = Signal()

    def __init__(self) -> None:
        super().__init__()
        self._settings = QSettings(
            QSettings.defaultFormat(), QSettings.UserScope, "soylu", "rsp-qt"
        )
        # ---- Defaults from renderer/store.ts:170-228 ----
        defaults: dict[str, Any] = {
            "darkMode": True,
            "connected": False,
            "currentTime": "",
            "currentTime2": "",
            "showAuxPanel": False,
            "showCalibrationModal": False,
            "showErrorModal": False,
            "showSeatAlarmModal": False,
            "showChillerModal": False,
            "calibrationProgress": 0,
            "calibrationStatus": "",
            "errorMessage": "",
            "lightStatus": 0,
            "light2Status": 0,
            "fan1Status": 0,
            "fan2Status": 0,
            "autoMode": False,
            "airMode": False,
            "ventilMode": 0,
            "valve1Status": False,
            "valve2Status": False,
            "playing": False,
            "chillerRunning": False,
            "chillerCurrentTemp": 20.0,
            "chillerSetTemp": 20.0,
            "chillerCommError": False,
            "lp1Status": True,
            "lp2Status": True,
            "hp1Status": True,
            "hpCylinderPressure": 120,
            "airTankPressure": 12.1,
            "nitrogen1Pressure": 120,
            "nitrogen2Pressure": 120,
            "mainFssLevel": 60,
            "mainFssPressure": 12.1,
            "mainFssActive": True,
            "anteFssLevel": 60,
            "anteFssPressure": 12.1,
            "anteFssActive": False,
            "anteFssWarning": True,
            "primaryO2Pressure": 120,
            "secondaryO2Pressure": 120,
            "liquidO2Pressure": 120,
            "primaryO2Active": True,
            "secondaryO2Active": False,
            "liquidO2Active": False,
            "mainFssAlarm": False,
            "anteFssAlarm": False,
            "mainFlameDetected": False,
            "mainSmokeDetected": False,
            "anteSmokeDetected": False,
            "mainHighO2": False,
            "anteHighO2": False,
            # ---- New Qt-only chamber + tech sensor fields ----
            "mainPressure": 0.0,
            "mainO2": 0.0,
            "mainTemp": 0.0,
            "mainHumidity": 0.0,
            "antePressure": 0.0,
            "anteO2": 0.0,
            "anteTemp": 0.0,
            "anteHumidity": 0.0,
            "techO2Pressure": 0.0,
            "anteFssNitrogenPressure": 0.0,
        }
        for name, default in defaults.items():
            if name in _PERSISTED:
                value = self._settings.value(name, default)
                if value is None:
                    value = default
                elif not isinstance(value, type(default)):
                    if isinstance(default, bool):
                        value = str(value).lower() == "true"
                    else:
                        try:
                            value = type(default)(value)
                        except (TypeError, ValueError):
                            value = default
            else:
                value = default
            setattr(self, f"_{name}", value)
        self._seatPressures: list[float] = [0.5] * 12
        self._activeSeatAlarm: dict | None = None

    # ---------- generic setter helper ----------
    def _set(self, name: str, value: Any, signal: Signal) -> None:
        attr = f"_{name}"
        if getattr(self, attr) == value:
            return
        setattr(self, attr, value)
        if name in _PERSISTED:
            self._settings.setValue(name, value)
            self._settings.sync()
        signal.emit()


# Programmatically attach a Property for each declared signal. This avoids
# 50 nearly-identical @Property blocks while keeping QML introspection happy.
_SCALAR_TYPES: dict[str, type] = {
    "darkMode": bool, "connected": bool, "currentTime": str, "currentTime2": str,
    "showAuxPanel": bool, "showCalibrationModal": bool, "showErrorModal": bool,
    "showSeatAlarmModal": bool, "showChillerModal": bool,
    "calibrationProgress": int, "calibrationStatus": str, "errorMessage": str,
    "lightStatus": int, "light2Status": int, "fan1Status": int, "fan2Status": int,
    "autoMode": bool, "airMode": bool, "ventilMode": int,
    "valve1Status": bool, "valve2Status": bool, "playing": bool,
    "chillerRunning": bool, "chillerCurrentTemp": float, "chillerSetTemp": float,
    "chillerCommError": bool,
    "lp1Status": bool, "lp2Status": bool, "hp1Status": bool,
    "hpCylinderPressure": float, "airTankPressure": float,
    "nitrogen1Pressure": float, "nitrogen2Pressure": float,
    "mainFssLevel": float, "mainFssPressure": float, "mainFssActive": bool,
    "anteFssLevel": float, "anteFssPressure": float, "anteFssActive": bool,
    "anteFssWarning": bool,
    "primaryO2Pressure": float, "secondaryO2Pressure": float, "liquidO2Pressure": float,
    "primaryO2Active": bool, "secondaryO2Active": bool, "liquidO2Active": bool,
    "mainFssAlarm": bool, "anteFssAlarm": bool,
    "mainFlameDetected": bool, "mainSmokeDetected": bool, "anteSmokeDetected": bool,
    "mainHighO2": bool, "anteHighO2": bool,
    # New Qt-only sensor fields (all raw floats; calibration in Phase 2)
    "mainPressure": float, "mainO2": float, "mainTemp": float, "mainHumidity": float,
    "antePressure": float, "anteO2": float, "anteTemp": float, "anteHumidity": float,
    "techO2Pressure": float, "anteFssNitrogenPressure": float,
}


def _make_property(name: str, py_type: type) -> Property:
    signal_name = f"{name}Changed"
    signal = getattr(AppState, signal_name)

    def _getter(self):
        return getattr(self, f"_{name}")

    def _setter(self, value):
        # Resolve the *bound* signal on the instance (the class-level
        # attribute is an unbound Signal descriptor without .emit()).
        self._set(name, value, getattr(self, signal_name))

    return Property(py_type, _getter, _setter, notify=signal)


for _name, _ty in _SCALAR_TYPES.items():
    setattr(AppState, _name, _make_property(_name, _ty))


# seatPressures (list[float]) and activeSeatAlarm (dict|None) — handled as `object`
def _seat_pressures_getter(self):
    return list(self._seatPressures)


def _seat_pressures_setter(self, value):
    new = [float(x) for x in value]
    if new == self._seatPressures:
        return
    self._seatPressures = new
    self.seatPressuresChanged.emit()


AppState.seatPressures = Property(  # type: ignore[assignment]
    "QVariantList",
    _seat_pressures_getter,
    _seat_pressures_setter,
    notify=AppState.seatPressuresChanged,
)


def _alarm_getter(self):
    return self._activeSeatAlarm


def _alarm_setter(self, value):
    if value == self._activeSeatAlarm:
        return
    self._activeSeatAlarm = value
    self.activeSeatAlarmChanged.emit()


AppState.activeSeatAlarm = Property(  # type: ignore[assignment]
    "QVariant",
    _alarm_getter,
    _alarm_setter,
    notify=AppState.activeSeatAlarmChanged,
)
