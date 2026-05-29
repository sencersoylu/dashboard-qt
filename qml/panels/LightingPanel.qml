import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp
import "../ui" as Ui

Ui.Card {
    id: root
    title: "Aydınlatma"
    implicitWidth: 400

    readonly property var levelValues: [0, 85, 170, 255]

    function levelToIndex(level) {
        for (let i = 0; i < levelValues.length; ++i) {
            if (levelValues[i] === level) return i
        }
        return 0
    }

    function applyMain(idx) {
        const value = levelValues[Math.max(0, Math.min(3, idx))]
        plcClient.writeRegister("R01700", value)
        appState.lightStatus = value
    }

    function applyAnte(idx) {
        const value = levelValues[Math.max(0, Math.min(3, idx))]
        plcClient.writeRegister("R01702", value)
        appState.light2Status = value
    }

    readonly property var lightStates: [
        { "label": "Off",    "color": Rsp.Theme.slate500 },
        { "label": "Düşük",  "color": Rsp.Theme.amber   },
        { "label": "Orta",   "color": Rsp.Theme.sky     },
        { "label": "Yüksek", "color": Rsp.Theme.emerald }
    ]

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Text {
                text: "Ana Oda"
                color: Rsp.Theme.text
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: Rsp.Theme.fontSizeMd
                Layout.preferredWidth: 100
            }
            Ui.ToggleSwitch {
                Layout.fillWidth: true
                states: root.lightStates
                value: root.levelToIndex(appState ? appState.lightStatus : 0)
                onValueChanged: function(newIndex) { root.applyMain(newIndex) }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Text {
                text: "Geçiş"
                color: Rsp.Theme.text
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: Rsp.Theme.fontSizeMd
                Layout.preferredWidth: 100
            }
            Ui.ToggleSwitch {
                Layout.fillWidth: true
                states: root.lightStates
                value: root.levelToIndex(appState ? appState.light2Status : 0)
                onValueChanged: function(newIndex) { root.applyAnte(newIndex) }
            }
        }
    }
}
