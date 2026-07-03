# Config-driven On/Off mode for Fan & Lights

**Date:** 2026-07-03
**Status:** Approved design

## Problem

The Fan and Lighting cards on the Dashboard currently expose a 4-level control
(Off / Low / Med / High) that writes a PLC register with one of `[0, 85, 170,
255]`. Some cabinets only have simple on/off fans and lights, where the
intermediate levels are meaningless. We want to *selectively* (per window /
cabinet) collapse these controls to a plain **Off / On** toggle, configurable
from the existing per-window config file — with no code redeploy needed to flip
a given cabinet between modes.

## Approach

Reuse the established `o2Generator` per-window config pattern. Panels already
read cabinet-specific flags from `Window.window.cfg` (see
`qml/panels/O2GeneratorPanel.qml`, which keys off `cfg.o2Generator === true`).
The `ToggleSwitch` widget is already state-count agnostic and renders a 2-state
Off/On toggle in `O2GeneratorPanel`, so no widget changes are required.

This is a **view-mode switch** only: no new Python state, no new PLC registers,
no new persisted settings keys.

### Considered alternatives

- **One combined flag** (`simpleFanLight`) for fan + both lights — rejected:
  doesn't honor the "selectively" requirement (no independent choice).
- **Three per-control flags** (fan / main light / ante light) — rejected as
  over-granular (YAGNI); the two cards are the natural units.
- **Chosen: two flags** — `fanOnOff` (Fan card) and `lightOnOff` (both Main and
  Ante lights on the Lighting card). Independent selection with minimal config.

## Config schema

Two new **optional** booleans per window entry in
`~/.config/rsp-qt/windows-config.json`. Absent or `false` preserves today's
4-level behavior (fully backward-compatible):

```json
{
  "id": "main",
  "page": "Dashboard",
  "display": 0,
  "fullscreen": true,
  "fanOnOff": true,
  "lightOnOff": true
}
```

- `fanOnOff: true`  → Fan card renders a 2-state **Off / On** toggle.
- `lightOnOff: true` → Lighting card's **Main** and **Ante** both render
  **Off / On** toggles.

## Register write mapping

Registers are unchanged (`R01700` main light, `R01702` ante light, `R01704`
fan). Only the value set narrows:

| Mode              | Off      | On                     |
|-------------------|----------|------------------------|
| 4-level (default) | 0        | 85 / 170 / 255         |
| On/Off            | write 0  | write **255** (= High) |

## State fields

No changes to `app/state.py`. `fan1Status` / `lightStatus` / `light2Status`
remain ints. In On/Off mode they hold `0` (Off) or `1` (On). No new fields, no
new persisted keys.

### Persisted-value carryover (edge case)

These indices are persisted via `QSettings`. If a cabinet last ran in 4-level
mode at value `3` (High) and config then flips to On/Off (2 states), the raw
`3` is out of range for a 2-item toggle (the pill would render off-screen). Each
panel therefore displays a **normalized** value:

```
displayValue = onOff ? (status > 0 ? 1 : 0) : status
```

Any nonzero status shows as **On**. Clicking On stores `1`; clicking Off stores
`0`.

## Per-panel implementation shape

Each panel (`FanPanel.qml`, `LightingPanel.qml`) gains:

- `readonly property bool onOff: Window.window && Window.window.cfg && Window.window.cfg.<flag> === true`
  (`fanOnOff` for the fan, `lightOnOff` for the lights). Requires
  `import QtQuick.Window`.
- An `onOffStates` array: `[{label:"Off", color: Theme.slate500}, {label:"On", color: "#3b82f6"}]`
  (blue `#3b82f6` matches the existing active-level color for these controls).
- `activeStates`: `onOff ? onOffStates : <existing 4-level states>`, bound to the
  `ToggleSwitch.states`.
- `apply(idx)` branches on `onOff`:
  - On/Off: `writeRegister(reg, idx > 0 ? 255 : 0)`, then store `idx` (0 or 1).
  - 4-level: unchanged (`levelValues[clamp(idx,0,3)]`).
- `ToggleSwitch.value` bound to the normalized `displayValue`.

`LightingPanel` applies the same `onOff` flag to both the Main and Ante rows.

## Files touched

1. `qml/panels/FanPanel.qml` — add On/Off mode.
2. `qml/panels/LightingPanel.qml` — add On/Off mode for Main + Ante.
3. `app/window_config.py` — extend the docstring config example so the new
   optional flags are documented (JSON stays the documented source of truth).

## Testing

No QML unit tests exist (the `tests/` suite is Python and no state changes are
needed here). Verification is manual:

1. Edit `~/.config/rsp-qt/windows-config.json`, set `"fanOnOff": true` and
   `"lightOnOff": true` on the Dashboard window.
2. Launch the app; confirm the Fan card and both Lighting rows show a two-cell
   **Off / On** toggle instead of four cells.
3. Toggle On → verify register write of `255` (via PLC log / write queue);
   toggle Off → verify `0`.
4. Remove the flags (or set `false`); confirm the 4-level Off/Low/Med/High
   toggle returns.
5. Cross-mode carryover: with a persisted High (3), enable `fanOnOff`; confirm
   the pill shows **On** (not off-screen/blank).
