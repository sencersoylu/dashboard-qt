import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp
import "../ui" as Ui

Ui.Card {
    id: root
    title: "Yardımcı Çıkışlar"
    implicitWidth: 400

    property int valve1Index: 0
    property int valve2Index: 0

    function applyValve(index, openReg, closeReg) {
        if (index === 0) {
            plcClient.writeBit(openReg,  0)
            plcClient.writeBit(closeReg, 0)
        } else if (index === 1) {
            plcClient.writeBit(openReg,  1)
            plcClient.writeBit(closeReg, 0)
        } else {
            plcClient.writeBit(openReg,  0)
            plcClient.writeBit(closeReg, 1)
        }
    }

    readonly property var valveStates: [
        { "label": "Kapalı", "color": Rsp.Theme.slate500 },
        { "label": "Aç",     "color": Rsp.Theme.emerald },
        { "label": "Kapat",  "color": Rsp.Theme.rose }
    ]

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Text {
                text: "Ana Valf"
                color: Rsp.Theme.text
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: Rsp.Theme.fontSizeMd
                Layout.preferredWidth: 100
            }
            Ui.ToggleSwitch {
                Layout.fillWidth: true
                states: root.valveStates
                value: root.valve1Index
                onValueUpdated: function(newIndex) {
                    root.valve1Index = newIndex
                    root.applyValve(newIndex, "M0500", "M0501")
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Text {
                text: "Geçiş Valf"
                color: Rsp.Theme.text
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: Rsp.Theme.fontSizeMd
                Layout.preferredWidth: 100
            }
            Ui.ToggleSwitch {
                Layout.fillWidth: true
                states: root.valveStates
                value: root.valve2Index
                onValueUpdated: function(newIndex) {
                    root.valve2Index = newIndex
                    root.applyValve(newIndex, "M0502", "M0503")
                }
            }
        }
    }
}
