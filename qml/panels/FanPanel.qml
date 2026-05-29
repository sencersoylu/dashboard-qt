import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp
import "../ui" as Ui

Ui.Card {
    id: root
    title: "Fan"
    implicitWidth: 380

    readonly property var levelValues: [0, 85, 170, 255]

    function apply(idx) {
        plcClient.writeRegister("R01704", levelValues[Math.max(0, Math.min(3, idx))])
        appState.fan1Status = idx
    }

    readonly property var fanStates: [
        { "label": "Off",  "color": Rsp.Theme.slate500 },
        { "label": "Low",  "color": "#3b82f6"          },
        { "label": "Med",  "color": "#3b82f6"          },
        { "label": "High", "color": "#3b82f6"          }
    ]

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
            states: root.fanStates
            value: appState ? appState.fan1Status : 0
            onValueUpdated: function(newIndex) { root.apply(newIndex) }
        }
    }
}
