# Fan & Lights On/Off Config Mode — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add per-window config flags (`fanOnOff`, `lightOnOff`) that collapse the 4-level Fan and Lighting controls into a plain Off/On toggle.

**Architecture:** Pure QML view-mode switch. Each panel reads its flag from `Window.window.cfg` (same mechanism as `O2GeneratorPanel`'s `cfg.o2Generator`). When the flag is set, the panel feeds a 2-item Off/On state array to the existing `ToggleSwitch`, writes `0`/`255` to the same PLC register, and normalizes the persisted `0..3` status into the toggle's index range. No changes to `app/state.py`, no new registers, no new persisted keys.

**Tech Stack:** PySide6 / Qt Quick (QML), qasync. Config is JSON at `~/.config/rsp-qt/windows-config.json`.

**Design doc:** `docs/plans/2026-07-03-fan-light-onoff-config-design.md`

**Note on testing:** This repo has no QML test harness (the `tests/` suite is pure Python and no Python behavior changes here). The automated gate per task is `pyside6-qmllint` (syntax/binding check); functional verification is the manual checklist in Task 4. Do not fabricate QML unit tests.

---

### Task 0: Confirm the qmllint gate is available

**Step 1:** Check for the linter.

Run: `.venv/bin/pyside6-qmllint --version 2>/dev/null || python -c "import PySide6, shutil, os; print('pyside6 present')"`

Expected: a version string, or `pyside6 present`. If `pyside6-qmllint` is absent, fall back to loading the file through Qt in Task steps by substituting:
`.venv/bin/python -c "from PySide6.QtQml import QQmlApplicationEngine; from PySide6.QtGui import QGuiApplication; import sys; app=QGuiApplication(sys.argv); e=QQmlApplicationEngine(); e.addImportPath('qml'); e.load('qml/panels/FanPanel.qml'); print('LOADERR' if not e.rootObjects() else 'OK')"` — but note this alone will warn about the unresolved `appState`/`plcClient` context properties, so treat non-fatal warnings as acceptable and only a hard parse error as failure.

No commit.

---

### Task 1: FanPanel Off/On mode

**Files:**
- Modify (full replace): `qml/panels/FanPanel.qml`

**Step 1: Replace the file with the On/Off-aware version**

```qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import ".." as Rsp
import "../ui" as Ui

Ui.Card {
    id: root
    title: "Fan"
    implicitWidth: 380

    // Per-window opt-in: cabinets with a simple on/off fan set
    // `fanOnOff: true` in windows-config.json. Window.window resolves to the
    // owning ApplicationWindow (Main.qml), which carries the per-window cfg —
    // same pattern as O2GeneratorPanel.
    readonly property bool onOff:
        Window.window && Window.window.cfg && Window.window.cfg.fanOnOff === true

    readonly property var levelValues: [0, 85, 170, 255]

    readonly property var fanStates: [
        { "label": "Off",  "color": Rsp.Theme.slate500 },
        { "label": "Low",  "color": "#3b82f6"          },
        { "label": "Med",  "color": "#3b82f6"          },
        { "label": "High", "color": "#3b82f6"          }
    ]
    readonly property var onOffStates: [
        { "label": "Off", "color": Rsp.Theme.slate500 },
        { "label": "On",  "color": "#3b82f6"          }
    ]
    readonly property var activeStates: onOff ? onOffStates : fanStates

    // Persisted fan1Status is a 0..3 index. In On/Off mode the toggle only has
    // indices 0..1, so normalize any nonzero level to "On" (1) — otherwise a
    // carried-over High (3) would push the pill off-screen.
    readonly property int displayValue:
        onOff ? ((appState && appState.fan1Status > 0) ? 1 : 0)
              : (appState ? appState.fan1Status : 0)

    function apply(idx) {
        if (onOff) {
            plcClient.writeRegister("R01704", idx > 0 ? 255 : 0)
            appState.fan1Status = idx > 0 ? 1 : 0
        } else {
            plcClient.writeRegister("R01704", levelValues[Math.max(0, Math.min(3, idx))])
            appState.fan1Status = idx
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 16
            Text {
                text: "Main"
                color: Rsp.Theme.text
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: Rsp.Theme.fontSizeMd
                font.weight: Font.DemiBold
                Layout.preferredWidth: 64
            }
            Ui.ToggleSwitch {
                Layout.fillWidth: true
                states: root.activeStates
                value: root.displayValue
                onValueUpdated: function(newIndex) { root.apply(newIndex) }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
```

**Step 2: Lint the file**

Run: `.venv/bin/pyside6-qmllint qml/panels/FanPanel.qml` (or the Task 0 fallback loader).
Expected: no parse errors. Warnings about unqualified `appState`/`plcClient` (context properties) are expected and acceptable.

**Step 3: Commit**

```bash
git add qml/panels/FanPanel.qml
git commit -m "feat(fan): config-driven Off/On mode via cfg.fanOnOff"
```

---

### Task 2: LightingPanel Off/On mode (Main + Ante)

**Files:**
- Modify (full replace): `qml/panels/LightingPanel.qml`

**Step 1: Replace the file with the On/Off-aware version**

```qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import ".." as Rsp
import "../ui" as Ui

Ui.Card {
    id: root
    title: "Lighting"
    implicitWidth: 380

    // Per-window opt-in: cabinets with simple on/off lights set
    // `lightOnOff: true` in windows-config.json. Applies to BOTH Main and Ante.
    readonly property bool onOff:
        Window.window && Window.window.cfg && Window.window.cfg.lightOnOff === true

    readonly property var levelValues: [0, 85, 170, 255]

    readonly property var lightStates: [
        { "label": "Off",  "color": Rsp.Theme.slate500 },
        { "label": "Low",  "color": "#3b82f6"          },
        { "label": "Med",  "color": "#3b82f6"          },
        { "label": "High", "color": "#3b82f6"          }
    ]
    readonly property var onOffStates: [
        { "label": "Off", "color": Rsp.Theme.slate500 },
        { "label": "On",  "color": "#3b82f6"          }
    ]
    readonly property var activeStates: onOff ? onOffStates : lightStates

    // Normalize persisted 0..3 indices into the active toggle's range.
    readonly property int displayMain:
        onOff ? ((appState && appState.lightStatus > 0) ? 1 : 0)
              : (appState ? appState.lightStatus : 0)
    readonly property int displayAnte:
        onOff ? ((appState && appState.light2Status > 0) ? 1 : 0)
              : (appState ? appState.light2Status : 0)

    function applyMain(idx) {
        if (onOff) {
            plcClient.writeRegister("R01700", idx > 0 ? 255 : 0)
            appState.lightStatus = idx > 0 ? 1 : 0
        } else {
            plcClient.writeRegister("R01700", levelValues[Math.max(0, Math.min(3, idx))])
            appState.lightStatus = idx
        }
    }

    function applyAnte(idx) {
        if (onOff) {
            plcClient.writeRegister("R01702", idx > 0 ? 255 : 0)
            appState.light2Status = idx > 0 ? 1 : 0
        } else {
            plcClient.writeRegister("R01702", levelValues[Math.max(0, Math.min(3, idx))])
            appState.light2Status = idx
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 16

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 16
            Text {
                text: "Main"
                color: Rsp.Theme.text
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: Rsp.Theme.fontSizeMd
                font.weight: Font.DemiBold
                Layout.preferredWidth: 64
            }
            Ui.ToggleSwitch {
                Layout.fillWidth: true
                states: root.activeStates
                value: root.displayMain
                onValueUpdated: function(newIndex) { root.applyMain(newIndex) }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 16
            Text {
                text: "Ante"
                color: Rsp.Theme.text
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: Rsp.Theme.fontSizeMd
                font.weight: Font.DemiBold
                Layout.preferredWidth: 64
            }
            Ui.ToggleSwitch {
                Layout.fillWidth: true
                states: root.activeStates
                value: root.displayAnte
                onValueUpdated: function(newIndex) { root.applyAnte(newIndex) }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
```

**Step 2: Lint the file**

Run: `.venv/bin/pyside6-qmllint qml/panels/LightingPanel.qml` (or the Task 0 fallback loader).
Expected: no parse errors; context-property warnings acceptable.

**Step 3: Commit**

```bash
git add qml/panels/LightingPanel.qml
git commit -m "feat(lighting): config-driven Off/On mode via cfg.lightOnOff"
```

---

### Task 3: Document the new flags in window_config.py

**Files:**
- Modify: `app/window_config.py` (the module docstring example, lines ~4-11)

**Step 1: Extend the docstring example**

Replace the example JSON block in the module docstring so it shows the new optional flags. Change the `"main"` window line to include them and add a sentence documenting them. New docstring body for that section:

```python
    {
      "windows": [
        {"id": "main",   "page": "Dashboard",  "display": 0, "fullscreen": true,
         "fanOnOff": true, "lightOnOff": true},
        {"id": "vitals", "page": "VitalSigns", "display": 1, "fullscreen": true}
      ]
    }

`page` references a QML file under `qml/pages/<page>.qml`. Each page declares
which backend clients it actually needs via PAGE_CLIENTS; `main.py` starts
only the union of those — so a dashboard-only setup doesn't dial vitals or
B-Control.

Optional per-window UI flags (read directly in QML via `Window.window.cfg`):
`o2Generator` shows the O₂ Generator card; `fanOnOff` / `lightOnOff` collapse
the Fan / Lighting controls from 4-level to a plain Off/On toggle. All default
to false when absent.
```

**Step 2: Verify Python still imports**

Run: `.venv/bin/python -c "import app.window_config as w; print('ok')"`
Expected: `ok`

**Step 3: Commit**

```bash
git add app/window_config.py
git commit -m "docs(config): document fanOnOff / lightOnOff window flags"
```

---

### Task 4: Manual verification

No commit — this is the acceptance checklist. If anything fails, fix the relevant panel and amend its commit.

**Setup:** Back up the real config, then point it at a Dashboard window with the flags on:

```bash
cp ~/.config/rsp-qt/windows-config.json /tmp/windows-config.bak.json 2>/dev/null || true
```

Edit `~/.config/rsp-qt/windows-config.json` so the Dashboard window has
`"fanOnOff": true, "lightOnOff": true`.

**Run:** `QT_API=pyside6 .venv/bin/python main.py` (QT_API=pyside6 is required — otherwise qasync binds PyQt5 and the PLC loop dies; see the RPi kiosk deployment note).

**Checklist:**
1. Fan card shows a **two-cell Off / On** toggle (not four cells).
2. Both Lighting rows (Main, Ante) show **Off / On**.
3. Click **On** → PLC log / write queue shows `255` written to `R01704` (fan), `R01700` (main light), `R01702` (ante light).
4. Click **Off** → `0` written to the same register.
5. Set the flags back to `false` (or remove them), relaunch → the 4-level **Off/Low/Med/High** toggle returns for all three.
6. Carryover: with a persisted High still in QSettings, enable `fanOnOff` and relaunch → the fan pill shows **On** (not blank / off-screen).

**Teardown:** restore the operator config:

```bash
cp /tmp/windows-config.bak.json ~/.config/rsp-qt/windows-config.json 2>/dev/null || true
```

---

## Done criteria

- Both panels render Off/On when their flag is set, 4-level otherwise.
- On writes 255, Off writes 0, to the unchanged registers.
- No changes to `app/state.py`; no new persisted keys.
- Config flags documented in `window_config.py`.
- Three feature commits (fan, lighting, docs) on `feat/fan-light-onoff-config`.
