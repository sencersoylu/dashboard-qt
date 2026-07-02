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
        x: -300; y: -100
        width: 700; height: 700
        radius: 350
        color: Qt.rgba(0.05, 0.45, 0.85, 0.06)   // sky tint, 6% opacity
    }
    Rectangle {
        visible: appState && appState.darkMode
        anchors.right: parent.right
        anchors.rightMargin: -200
        y: parent.height * 0.2
        width: 600; height: 600
        radius: 300
        color: Qt.rgba(0.4, 0.2, 0.9, 0.05)
    }
    Rectangle {
        visible: appState && appState.darkMode
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -300
        width: 800; height: 800
        radius: 400
        color: Qt.rgba(0.05, 0.7, 0.5, 0.04)
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
        anchors.bottomMargin: 24

        // ----- Header (page.width × 64) -----
        Panels.Header {
            id: header
            width: page.width
            height: 64
        }

        // ----- Main grid: fills remaining vertical space -----
        RowLayout {
            id: mainGrid
            anchors.top: header.bottom
            anchors.topMargin: 24
            anchors.bottom: parent.bottom
            width: page.width
            spacing: 24

            // Column 1 — Chamber Control (286 wide)
            Panels.ChamberControlPanel {
                Layout.preferredWidth: 286
                Layout.fillHeight: true
                onChillerRequested: chillerModal.open()
            }

            // Column 2 — Auxiliary Decompression (+ optional O₂ Generator card)
            ColumnLayout {
                Layout.preferredWidth: 389
                Layout.fillHeight: true
                spacing: 24

                Panels.AuxiliaryOutputPanel {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                // Cabinet-specific: the panel hides itself (and drops from the
                // layout) unless this window's config sets o2Generator: true.
                Panels.O2GeneratorPanel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 190
                }
            }

            // Column 3 — Lighting (top) + Fan (bottom)
            ColumnLayout {
                Layout.preferredWidth: 493
                Layout.fillHeight: true
                spacing: 24

                Panels.LightingPanel {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
                Panels.FanPanel {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
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
        onActivated: {
            var view = root.StackView ? root.StackView.view : null
            if (view && view.depth > 1) view.pop()
        }
    }
}
