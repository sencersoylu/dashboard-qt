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
