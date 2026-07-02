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
   31 — o2GeneratorOn coil (0/1); coerced to bool below, not a raw passthrough
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

# O2 generator on/off — the PLC mirrors the M0072 coil into data[31] as 0/1.
# The UI commands it via writeBit("M0072", ...); this index is the read-back.
_O2GEN_INDEX = 31

_ALARM_BITS_INDEX = 19
_SEAT_INDEX = 16
_BIT_MASTER = 0
_BIT_SEAT = 1
_ALARM_BITS: dict[int, str] = {
    2: "mainFssAlarm",
    3: "anteFssAlarm",
    4: "mainFlameDetected",
    5: "mainSmokeDetected",
    6: "anteSmokeDetected",
    7: "mainHighO2",
    8: "anteHighO2",
}

# Bit → (transient-flag-attr-or-None, modal-message). Order matches React's
# `if / elif` chain in dashboard.tsx so the first-active bit wins the modal
# message slot.
_ERROR_BIT_MESSAGES: tuple[tuple[int, str | None, str], ...] = (
    (2, None,                  "Main FSS Activated"),
    (3, None,                  "Ante FSS Activated"),
    (4, "mainFlameDetected",   "Main Flame Detected"),
    (5, "mainSmokeDetected",   "Main Smoke Detected"),
    (6, "anteSmokeDetected",   "Ante Smoke Detected"),
    (7, None,                  "Main High O₂"),
    (8, None,                  "Ante High O₂"),
    (9, None,                  "Ante High O₂"),  # duplicate kept from React
)

# data[16] → human-readable seat label (mirrors dashboardI18n keys).
_SEAT_LABELS: dict[int, str] = {
    21: "Nurse",
    22: "Ante 1",
    23: "Ante 2",
    24: "Ante Nurse",
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
    if _O2GEN_INDEX < n:
        try:
            state.o2GeneratorOn = bool(int(payload[_O2GEN_INDEX]))
        except (TypeError, ValueError):
            log.warning("PLC data[31] not numeric: %r", payload[_O2GEN_INDEX])
    if _ALARM_BITS_INDEX < n:
        _apply_alarm_bits(state, int(payload[_ALARM_BITS_INDEX]), payload)
    if log.isEnabledFor(logging.DEBUG):
        for idx in _UNMAPPED_INDICES:
            if idx < n and payload[idx]:
                log.debug("PLC data[%d] = %r (still unmapped)", idx, payload[idx])


def _apply_alarm_bits(state, bits: int, payload: Sequence[float]) -> None:
    """Mirror dashboard.tsx error-word handling.

    `bits` is data[19], a 16-bit error word. Bit 0 is the master gate —
    when it falls to 0, the modals close and transient flags reset.
    When it's 1, the seat-bit (1) and error-bit chain (2..9) decide what
    to show.
    """
    # Always reflect the per-bit flags onto state so panels/dots can react
    # to them even while the master modal is gated.
    for bit, attr in _ALARM_BITS.items():
        setattr(state, attr, bool(bits & (1 << bit)))

    master = bool(bits & (1 << _BIT_MASTER))
    if not master:
        # Master gate dropped — only the *modal* state resets. Per-bit
        # flags above still mirror the raw word so panels/dots stay
        # honest (test_plc_data_map.py enforces this).
        state.showErrorModal = False
        state.errorMessage = ""
        state.activeSeatAlarm = {}
        state.showSeatAlarmModal = False
        # Master is back to 0: lift the post-dismiss suppression so the
        # next *new* alarm can open the modal again.
        state.errorModalSuppressed = False
        return

    # Master gate is on. Seat alarms (bit 1) open the seat modal; data[16]
    # carries the seat ID.
    if bits & (1 << _BIT_SEAT) and not state.showSeatAlarmModal:
        seat_id = int(payload[_SEAT_INDEX]) if len(payload) > _SEAT_INDEX else 0
        label = _SEAT_LABELS.get(seat_id, str(seat_id))
        state.activeSeatAlarm = {"seatNumber": label}
        state.showSeatAlarmModal = True

    # First matching error bit wins the modal slot — mirrors React's elif
    # chain. We don't re-open the modal if the user already dismissed it
    # (errorModalSuppressed stays true until the master gate drops back to
    # 0, see the early return above). The flag attrs (mainFlameDetected,
    # etc.) are already set by the raw bit-mirror loop above, so this only
    # manages modal + message.
    if not state.showErrorModal and not state.errorModalSuppressed:
        for bit, _flag_attr, message in _ERROR_BIT_MESSAGES:
            if bits & (1 << bit):
                state.errorMessage = message
                state.showErrorModal = True
                break
