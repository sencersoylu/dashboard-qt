"""PLC `data` event array → AppState field mapping.

Index source-of-truth: memory file `reference_socket_data_mapping.md`
(live-verified 2026-05-22 and 2026-05-26).

Raw PLC values are written through unchanged in Phase 1; per-sensor calibration
(linearConversion using `json.php?i=main,tech` records) is Phase 2's job. This
keeps `PlcClient` free of conversion logic.

Indices intentionally NOT in DATA_INDEX:
    8  — deprecated (air tank moved to 30 on 2026-05-23)
   14, 17, 18, 25, 26 — meaning still TBD per memory file
   16 — also carried by the `seatAlarm` event; PlcClient prefers that path
   27, 28, 29 — chiller link/setTemp/runFlag; correlated logic lives in
                PlcClient, not here
"""

from __future__ import annotations

import logging
from typing import Sequence

log = logging.getLogger(__name__)


DATA_INDEX: dict[str, int] = {
    # ---- Main chamber ----
    "mainPressure":            0,
    "mainO2":                  1,
    "mainTemp":                2,
    # ---- Ante chamber ----
    "anteHumidity":            3,
    "antePressure":            4,
    "anteO2":                  5,
    "anteTemp":                6,
    "mainHumidity":            7,
    # ---- Tech ----
    "techO2Pressure":          9,
    "mainFssPressure":        10,
    "mainFssLevel":           11,
    "anteFssPressure":        12,
    "anteFssLevel":           13,
    # ---- Chiller PV (raw; converted to chillerCurrentTemp = /10 below) ----
    "chillerCurrentTempRaw":  15,
    # ---- O2 / Nitrogen banks ----
    "primaryO2Pressure":      20,
    "secondaryO2Pressure":    21,
    "nitrogen1Pressure":      22,
    "nitrogen2Pressure":      23,
    "anteFssNitrogenPressure": 24,
    # ---- Air tank (moved 2026-05-23 from 8 → 30) ----
    "airTankPressure":        30,
}

_CHILLER_PV_INDEX = 15
_CHILLER_PV_DIVISOR = 10.0

_ALARM_BITS_INDEX = 19
_ALARM_BITS: dict[int, str] = {
    2: "mainFssAlarm",
    3: "anteFssAlarm",
    4: "mainFlameDetected",
    5: "mainSmokeDetected",
    6: "anteSmokeDetected",
    7: "mainHighO2",
    8: "anteHighO2",
}

_UNMAPPED_INDICES = (14, 17, 18, 25, 26)


def apply_data_array(state, payload: Sequence[float]) -> None:
    """Write every mapped index onto `state` in place. Safe with short payloads."""
    n = len(payload)
    for attr, idx in DATA_INDEX.items():
        # chillerCurrentTempRaw is documentation-only; the divide-by-10
        # transform below writes the real `chillerCurrentTemp` field.
        if attr == "chillerCurrentTempRaw":
            continue
        if idx < n:
            setattr(state, attr, payload[idx])
    if _CHILLER_PV_INDEX < n:
        state.chillerCurrentTemp = float(payload[_CHILLER_PV_INDEX]) / _CHILLER_PV_DIVISOR
    if _ALARM_BITS_INDEX < n:
        _apply_alarm_bits(state, int(payload[_ALARM_BITS_INDEX]))
    if log.isEnabledFor(logging.DEBUG):
        for idx in _UNMAPPED_INDICES:
            if idx < n and payload[idx]:
                log.debug("PLC data[%d] = %r (still unmapped)", idx, payload[idx])


def _apply_alarm_bits(state, bits: int) -> None:
    for bit, attr in _ALARM_BITS.items():
        setattr(state, attr, bool(bits & (1 << bit)))
