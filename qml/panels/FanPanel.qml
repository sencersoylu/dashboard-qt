import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp
import "../ui" as Ui

Ui.Card {
    id: root
    title: "Fan"
    implicitWidth: 400

    readonly property var levelValues: [0, 85, 170, 255]

    function levelToIndex(level) {
        for (let i = 0; i < levelValues.length; ++i) {
            if (levelValues[i] === level) return i
        }
        return 0
    }

    function apply(idx) {
        const value = levelValues[Math.max(0, Math.min(3, idx))]
        plcClient.writeRegister("R01704", value)
        appState.fan1Status = value
    }

    readonly property var fanStates: [
        { "label": "Off",    "color": Rsp.Theme.slate500 },
        { "label": "Düşük",  "color": Rsp.Theme.amber   },
        { "label": "Orta",   "color": Rsp.Theme.sky     },
        { "label": "Yüksek", "color": Rsp.Theme.emerald }
    ]

    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        Text {
            text: "Main"
            color: Rsp.Theme.text
            font.family: Rsp.Theme.fontFamily
            font.pixelSize: Rsp.Theme.fontSizeMd
            Layout.preferredWidth: 100
        }
        Ui.ToggleSwitch {
            Layout.fillWidth: true
            states: root.fanStates
            value: root.levelToIndex(appState ? appState.fan1Status : 0)
            onValueChanged: function(newIndex) { root.apply(newIndex) }
        }
    }
}
