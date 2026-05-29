import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp
import "../ui" as Ui

Ui.Card {
    id: root
    title: "Chamber Control"
    implicitWidth: 380

    signal chillerRequested()

    function toggleAuto() {
        const newValue = (appState && appState.autoMode) ? 0 : 1
        plcClient.writeBit("M0201", newValue)
        appState.autoMode = !appState.autoMode
    }

    function toggleAir() {
        const newValue = (appState && appState.airMode) ? 0 : 1
        plcClient.writeBit("M0200", newValue)
        appState.airMode = !appState.airMode
    }

    function setVentil(idx) {
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
        Layout.fillHeight: true
        spacing: 24

        // ----- Manual / Automatic -----
        Ui.ToggleSwitch {
            Layout.fillWidth: true
            states: [
                { "label": "Manual",    "color": Rsp.Theme.rose    },
                { "label": "Automatic", "color": Rsp.Theme.emerald }
            ]
            value: (appState && appState.autoMode) ? 0 : 1
            onValueUpdated: function(newIndex) { root.toggleAuto() }
        }

        // ----- Air / Oxygen (only enabled in auto mode) -----
        Ui.ToggleSwitch {
            Layout.fillWidth: true
            enabledState: appState && appState.autoMode
            states: [
                { "label": "Air",    "color": "#3b82f6"        },
                { "label": "Oxygen", "color": Rsp.Theme.emerald }
            ]
            value: (appState && appState.airMode) ? 1 : 0
            onValueUpdated: function(newIndex) { root.toggleAir() }
        }

        // ----- Ventil (only enabled in MANUAL mode) -----
        Ui.ToggleSwitch {
            Layout.fillWidth: true
            enabledState: !(appState && appState.autoMode)
            states: [
                { "label": "Off",  "color": Rsp.Theme.slate500 },
                { "label": "Low",  "color": "#3b82f6"          },
                { "label": "High", "color": "#3b82f6"          }
            ]
            value: appState ? appState.ventilMode : 0
            onValueUpdated: function(newIndex) { root.setVentil(newIndex) }
        }

        Item { Layout.fillHeight: true }

        // ----- Chiller pill button -----
        Ui.AppButton {
            Layout.fillWidth: true
            size: "lg"
            variant: appState && appState.chillerRunning ? "info" : "muted"
            text: {
                if (!appState) return "Chiller Off"
                if (appState.chillerCommError) return "Chiller Off"
                if (appState.chillerRunning) {
                    return "Chiller " + appState.chillerCurrentTemp.toFixed(1) + "°C"
                }
                return "Chiller Off"
            }
            enabledState: !(appState && appState.chillerCommError)
            onClicked: root.chillerRequested()
        }
    }
}
