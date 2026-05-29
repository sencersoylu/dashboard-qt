import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp
import "../panels" as Panels
import "../modals" as Modals

Rectangle {
    id: root
    color: Rsp.Theme.bg

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const now = new Date()
            appState.currentTime  = Qt.formatTime(now, "HH:mm:ss")
            appState.currentTime2 = Qt.formatDate(now, "dd MMM yyyy")
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Panels.Header {
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 24
            spacing: 24

            // ----- Left column -----
            ColumnLayout {
                Layout.preferredWidth: 320
                Layout.fillHeight: true
                spacing: 16

                Panels.ChamberControlPanel {
                    Layout.fillWidth: true
                    onChillerRequested: chillerModal.open()
                }

                Panels.AuxiliaryOutputPanel {
                    Layout.fillWidth: true
                }
            }

            // ----- Center column -----
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 16

                Panels.HyperbaricChamber {
                    Layout.fillWidth: true
                }

                Panels.ChamberSeatOverlay {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                Panels.CylinderBank {
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            // ----- Right column -----
            ColumnLayout {
                Layout.preferredWidth: 320
                Layout.fillHeight: true
                spacing: 16

                Panels.LightingPanel {
                    Layout.fillWidth: true
                }

                Panels.FanPanel {
                    Layout.fillWidth: true
                }

                Panels.ChillerStatusPanel {
                    Layout.fillWidth: true
                }
            }
        }
    }

    // ===== Modals =====
    Modals.ErrorModal {
        id: errorModal
        Connections {
            target: appState
            function onShowErrorModalChanged() {
                if (appState.showErrorModal) errorModal.open()
                else errorModal.close()
            }
        }
    }

    Modals.SeatAlarmModal {
        id: seatModal
        Connections {
            target: appState
            function onShowSeatAlarmModalChanged() {
                if (appState.showSeatAlarmModal) seatModal.open()
                else seatModal.close()
            }
        }
    }

    Modals.ChillerControlModal {
        id: chillerModal
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.parent.StackView ? root.parent.StackView.view.pop() : null
    }
}
