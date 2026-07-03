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
