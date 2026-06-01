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
        const goingAuto = !(appState && appState.autoMode)
        plcClient.writeBit("M0201", goingAuto ? 1 : 0)
        appState.autoMode = goingAuto
        // When the operator switches to Automatic, force the gas mode to
        // Air (airMode = false / index 0). Manual switch leaves the gas
        // selection where the operator left it.
        if (goingAuto && appState.airMode) {
            plcClient.writeBit("M0200", 0)
            appState.airMode = false
        }
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
        spacing: 0

        Item { Layout.fillHeight: true; Layout.minimumHeight: 4 }

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

        Item { Layout.fillHeight: true; Layout.minimumHeight: 16 }

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

        Item { Layout.fillHeight: true; Layout.minimumHeight: 16 }

        // ----- Ventil (only enabled in MANUAL mode) -----
        Ui.ToggleSwitch {
            Layout.fillWidth: true
            enabledState: !(appState && appState.autoMode)
            states: [
                { "label": "Ventil\nOff", "color": Rsp.Theme.slate500 },
                { "label": "Low",         "color": "#3b82f6"          },
                { "label": "High",        "color": "#3b82f6"          }
            ]
            value: appState ? appState.ventilMode : 0
            onValueUpdated: function(newIndex) { root.setVentil(newIndex) }
        }

        Item { Layout.fillHeight: true; Layout.minimumHeight: 16 }

        // ----- Chiller pill button -----
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 64

            Rectangle {
                id: chillerBg
                anchors.fill: parent
                radius: height / 2   // pill shape
                color: !appState || appState.chillerCommError
                       ? Rsp.Theme.slate500
                       : appState.chillerRunning
                           ? Rsp.Theme.sky
                           : Rsp.Theme.slate500
                opacity: (appState && appState.chillerCommError) ? 0.5 : 1.0

                Behavior on color   { ColorAnimation { duration: Rsp.Theme.animMed } }
                Behavior on opacity { NumberAnimation { duration: Rsp.Theme.animFast } }

                scale: chillerArea.pressed ? 0.98 : (chillerArea.containsMouse ? 1.02 : 1.0)
                Behavior on scale { NumberAnimation { duration: Rsp.Theme.animFast } }
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 12

                Image {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    source: "../../assets/icons/monitor.svg"
                    sourceSize: Qt.size(20, 20)
                }
                Text {
                    text: {
                        if (!appState || appState.chillerCommError) return "Chiller Off"
                        return appState.chillerRunning
                            ? "Chiller " + appState.chillerCurrentTemp.toFixed(1) + "°C"
                            : "Chiller Off"
                    }
                    color: "#ffffff"
                    font.family: Rsp.Theme.fontFamily
                    font.pixelSize: Rsp.Theme.fontSizeLg
                    font.weight: Font.DemiBold
                }
            }

            MouseArea {
                id: chillerArea
                anchors.fill: parent
                hoverEnabled: true
                enabled: !(appState && appState.chillerCommError)
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                onClicked: root.chillerRequested()
            }
        }
    }
}
