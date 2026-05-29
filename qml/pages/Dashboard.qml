import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp
import "../panels" as Panels
import "../modals" as Modals

Rectangle {
    id: root

    gradient: Gradient {
        orientation: Gradient.Vertical
        GradientStop { position: 0.0; color: appState && appState.darkMode ? "#0f172a" : "#f8fafc" }
        GradientStop { position: 0.5; color: appState && appState.darkMode ? "#0a0e1c" : "#ffffff" }
        GradientStop { position: 1.0; color: appState && appState.darkMode ? "#020617" : "#f1f5f9" }
    }

    Rectangle {
        visible: appState && appState.darkMode
        x: -100; y: 100
        width: 400; height: 400
        radius: 200
        color: Qt.rgba(0.05, 0.45, 0.85, 0.15)
    }
    Rectangle {
        visible: appState && appState.darkMode
        anchors.right: parent.right
        anchors.rightMargin: -120
        y: parent.height * 0.3
        width: 360; height: 360
        radius: 180
        color: Qt.rgba(0.4, 0.2, 0.9, 0.10)
    }
    Rectangle {
        visible: appState && appState.darkMode
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -180
        width: 500; height: 500
        radius: 250
        color: Qt.rgba(0.05, 0.7, 0.5, 0.08)
    }

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

    Item {
        id: page
        anchors.fill: parent
        anchors.leftMargin: 32
        anchors.rightMargin: 32
        anchors.topMargin: 24

        // ----- Header (1216 × 64) -----
        Panels.Header {
            id: header
            width: page.width
            height: 64
        }

        // ----- Main grid (1216 × 441) at y = 64 + 24 -----
        RowLayout {
            id: mainGrid
            anchors.top: header.bottom
            anchors.topMargin: 24
            width: page.width
            height: 441
            spacing: 24

            // Column 1 — Chamber Control (286 × 441)
            Panels.ChamberControlPanel {
                Layout.preferredWidth: 286
                Layout.preferredHeight: 441
                onChillerRequested: chillerModal.open()
            }

            // Column 2 — Auxiliary Decompression (389 × 441)
            Panels.AuxiliaryOutputPanel {
                Layout.preferredWidth: 389
                Layout.preferredHeight: 441
            }

            // Column 3 — Lighting (top, 493 × 209) + Fan (bottom, 493 × 209)
            ColumnLayout {
                Layout.preferredWidth: 493
                Layout.preferredHeight: 441
                spacing: 24

                Panels.LightingPanel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 209
                }
                Panels.FanPanel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 209
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
