import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp
import "../ui" as Ui

Ui.Card {
    id: root
    title: "Auxiliary Decompression"
    implicitWidth: 380

    function toggleValve1() {
        const newValue = (appState && appState.valve1Status) ? 0 : 1
        if (newValue === 0) {
            plcClient.writeBit("M0501", 0); plcClient.writeBit("M0500", 1)
        } else {
            plcClient.writeBit("M0500", 0); plcClient.writeBit("M0501", 1)
        }
        appState.valve1Status = !appState.valve1Status
    }

    function toggleValve2() {
        const newValue = (appState && appState.valve2Status) ? 0 : 1
        if (newValue === 0) {
            plcClient.writeBit("M0503", 0); plcClient.writeBit("M0502", 1)
        } else {
            plcClient.writeBit("M0502", 0); plcClient.writeBit("M0503", 1)
        }
        appState.valve2Status = !appState.valve2Status
    }

    readonly property var valveStates: [
        { "label": "Closed", "color": Rsp.Theme.slate500 },
        { "label": "Open",   "color": "#3b82f6"          }
    ]

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 0

        Item { Layout.fillHeight: true; Layout.preferredHeight: 24 }

        // ===== Main Chamber =====
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Main"
                color: Rsp.Theme.text
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: Rsp.Theme.fontSizeLg
                font.weight: Font.Bold
            }
            Ui.ToggleSwitch {
                Layout.fillWidth: true
                states: root.valveStates
                value: (appState && appState.valve1Status) ? 1 : 0
                onValueUpdated: function(newIndex) { root.toggleValve1() }
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.topMargin: 24
            Layout.bottomMargin: 24
            color: Rsp.Theme.border
        }

        // ===== Ante Chamber =====
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Ante"
                color: Rsp.Theme.text
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: Rsp.Theme.fontSizeLg
                font.weight: Font.Bold
            }
            Ui.ToggleSwitch {
                Layout.fillWidth: true
                states: root.valveStates
                value: (appState && appState.valve2Status) ? 1 : 0
                onValueUpdated: function(newIndex) { root.toggleValve2() }
            }
        }

        Item { Layout.fillHeight: true; Layout.preferredHeight: 24 }
    }
}
