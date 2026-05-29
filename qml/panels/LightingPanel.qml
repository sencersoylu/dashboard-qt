import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp
import "../ui" as Ui

Ui.Card {
    id: root
    title: "Lighting"
    implicitWidth: 380

    readonly property var levelValues: [0, 85, 170, 255]

    function applyMain(idx) {
        plcClient.writeRegister("R01700", levelValues[Math.max(0, Math.min(3, idx))])
        appState.lightStatus = idx
    }

    function applyAnte(idx) {
        plcClient.writeRegister("R01702", levelValues[Math.max(0, Math.min(3, idx))])
        appState.light2Status = idx
    }

    readonly property var lightStates: [
        { "label": "Off",  "color": Rsp.Theme.slate500 },
        { "label": "Low",  "color": "#3b82f6"          },
        { "label": "Med",  "color": "#3b82f6"          },
        { "label": "High", "color": "#3b82f6"          }
    ]

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
                states: root.lightStates
                value: appState ? appState.lightStatus : 0
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
                states: root.lightStates
                value: appState ? appState.light2Status : 0
                onValueUpdated: function(newIndex) { root.applyAnte(newIndex) }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
