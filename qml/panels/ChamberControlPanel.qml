import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp
import "../ui" as Ui

Ui.Card {
    id: root
    title: "Oda Kontrol"
    implicitWidth: 400

    signal chillerRequested()

    readonly property var twoState: function(offLabel, onLabel) { return [
        { "label": offLabel, "color": Rsp.Theme.slate500 },
        { "label": onLabel,  "color": Rsp.Theme.emerald }
    ]}
    readonly property var ventilStates: [
        { "label": "Off",      "color": Rsp.Theme.slate500 },
        { "label": "Tahliye",  "color": Rsp.Theme.rose },
        { "label": "Doldur",   "color": Rsp.Theme.emerald }
    ]

    function applyVentil(idx) {
        if (idx === 0) {
            plcClient.writeBit("M0202", 0); plcClient.writeBit("M0203", 0)
        } else if (idx === 1) {
            plcClient.writeBit("M0202", 1); plcClient.writeBit("M0203", 0)
        } else {
            plcClient.writeBit("M0202", 0); plcClient.writeBit("M0203", 1)
        }
        appState.ventilMode = idx
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 16

        Ui.ToggleSwitch {
            Layout.fillWidth: true
            states: root.twoState("Manuel", "Otomatik")
            value: (appState && appState.autoMode) ? 1 : 0
            onValueChanged: function(newIndex) {
                plcClient.writeBit("M0201", newIndex)
                appState.autoMode = (newIndex === 1)
            }
        }

        Ui.ToggleSwitch {
            Layout.fillWidth: true
            states: root.twoState("Hava", "Oksijen")
            value: (appState && appState.airMode) ? 1 : 0
            onValueChanged: function(newIndex) {
                plcClient.writeBit("M0200", newIndex)
                appState.airMode = (newIndex === 1)
            }
        }

        Ui.ToggleSwitch {
            Layout.fillWidth: true
            states: root.ventilStates
            value: appState ? appState.ventilMode : 0
            onValueChanged: function(newIndex) { root.applyVentil(newIndex) }
        }

        Ui.AppButton {
            Layout.fillWidth: true
            variant: appState && appState.chillerRunning ? "info" : "muted"
            text: (appState && appState.chillerCommError) ? "Chiller: COMM HATA"
                  : (appState && appState.chillerRunning)
                      ? "Chiller: " + appState.chillerSetTemp.toFixed(1) + " °C"
                      : "Chiller: KAPALI"
            enabledState: !(appState && appState.chillerCommError)
            onClicked: root.chillerRequested()
        }
    }
}
