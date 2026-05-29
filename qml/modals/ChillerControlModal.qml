import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp
import "../ui" as Ui

Ui.AppModal {
    id: root
    title: ""              // custom header below
    showCloseButton: false // we provide our own
    size: "lg"

    property real localSetTemp: appState ? appState.chillerSetTemp : 20.0

    Timer {
        id: debounce
        interval: 500
        repeat: false
        onTriggered: {
            plcClient.writeRegister("D00202", Math.round(root.localSetTemp * 10))
            appState.chillerSetTemp = root.localSetTemp
        }
    }

    function start() { plcClient.writeRegister("D00208", 1) }
    function stop()  { plcClient.writeRegister("D00208", 0) }

    readonly property bool commError: appState && appState.chillerCommError
    readonly property bool running:   appState && appState.chillerRunning && !commError

    readonly property color accent: commError ? Rsp.Theme.amber
                                    : running  ? Rsp.Theme.emerald
                                               : Rsp.Theme.cyan

    // ============ Custom Header ============
    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        // Icon badge with accent ring
        Item {
            implicitWidth: 44; implicitHeight: 44
            Rectangle {
                anchors.fill: parent
                radius: 12
                color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.15)
                border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.35)
                border.width: 1
            }
            Image {
                anchors.centerIn: parent
                source: "../../assets/icons/snowflake.svg"
                sourceSize: Qt.size(22, 22)
                width: 22; height: 22
                // Tint via ColorOverlay-like trick: keep stroke=currentColor → reuse opacity
                opacity: 1.0
            }
            Rectangle {
                anchors.fill: parent
                radius: 12
                color: root.accent
                opacity: 0.0
                // Optional pulse when running
                SequentialAnimation on opacity {
                    running: root.running
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.0; to: 0.18; duration: 900; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 0.18; to: 0.0; duration: 900; easing.type: Easing.InOutQuad }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                text: "Chiller Control"
                color: Rsp.Theme.text
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: 22
                font.weight: Font.Bold
            }
            RowLayout {
                spacing: 8
                Rectangle {
                    implicitWidth: 8; implicitHeight: 8
                    radius: 4
                    color: root.accent
                    SequentialAnimation on opacity {
                        running: root.running
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 0.3; duration: 700; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 0.3; to: 1.0; duration: 700; easing.type: Easing.InOutQuad }
                    }
                }
                Text {
                    text: root.commError ? "Communication Error"
                          : root.running   ? "Running"
                                           : "Stopped"
                    color: Rsp.Theme.textMuted
                    font.family: Rsp.Theme.fontFamily
                    font.pixelSize: Rsp.Theme.fontSizeSm
                    font.weight: Font.Medium
                }
            }
        }

        // Close button
        Item {
            implicitWidth: 32; implicitHeight: 32
            Rectangle {
                anchors.fill: parent
                radius: 8
                color: closeArea.containsMouse ? Rsp.Theme.border : "transparent"
                Behavior on color { ColorAnimation { duration: Rsp.Theme.animFast } }
            }
            Text {
                anchors.centerIn: parent
                text: "×"
                color: Rsp.Theme.textMuted
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: 22
            }
            MouseArea {
                id: closeArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { if (appState) appState.showChillerModal = false; root.close() }
            }
        }
    }

    // ============ Temperature Cards (Current | Target) ============
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 12

        // Current temp card
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 124
            radius: Rsp.Theme.radiusMd
            color: Qt.rgba(1, 1, 1, 0.04)
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 8

                RowLayout {
                    spacing: 6
                    Rectangle {
                        implicitWidth: 6; implicitHeight: 6; radius: 3
                        color: Rsp.Theme.textMuted
                    }
                    Text {
                        text: "CURRENT"
                        color: Rsp.Theme.textMuted
                        font.family: Rsp.Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        font.letterSpacing: 1.5
                    }
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    spacing: 4
                    Text {
                        text: root.commError
                              ? "––"
                              : (appState ? appState.chillerCurrentTemp.toFixed(1) : "––")
                        color: Rsp.Theme.text
                        font.family: Rsp.Theme.fontFamily
                        font.pixelSize: 44
                        font.weight: Font.Bold
                    }
                    Text {
                        text: "°C"
                        color: Rsp.Theme.textMuted
                        font.family: Rsp.Theme.fontFamily
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                        Layout.bottomMargin: 6
                    }
                }
            }
        }

        // Target temp card (cyan accent)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 124
            radius: Rsp.Theme.radiusMd
            color: Qt.rgba(Rsp.Theme.cyan.r, Rsp.Theme.cyan.g, Rsp.Theme.cyan.b, 0.10)
            border.color: Qt.rgba(Rsp.Theme.cyan.r, Rsp.Theme.cyan.g, Rsp.Theme.cyan.b, 0.30)
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 8

                RowLayout {
                    spacing: 6
                    Rectangle {
                        implicitWidth: 6; implicitHeight: 6; radius: 3
                        color: Rsp.Theme.cyan
                    }
                    Text {
                        text: "TARGET"
                        color: Rsp.Theme.cyan
                        font.family: Rsp.Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        font.letterSpacing: 1.5
                    }
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    spacing: 4
                    Text {
                        text: root.localSetTemp.toFixed(1)
                        color: Rsp.Theme.cyan
                        font.family: Rsp.Theme.fontFamily
                        font.pixelSize: 44
                        font.weight: Font.Bold
                    }
                    Text {
                        text: "°C"
                        color: Qt.rgba(Rsp.Theme.cyan.r, Rsp.Theme.cyan.g, Rsp.Theme.cyan.b, 0.7)
                        font.family: Rsp.Theme.fontFamily
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                        Layout.bottomMargin: 6
                    }
                }
            }
        }
    }

    // ============ Slider ============
    Item {
        Layout.fillWidth: true
        Layout.topMargin: 8
        Layout.preferredHeight: slider.implicitHeight

        Ui.AppSlider {
            id: slider
            anchors.fill: parent
            label: "Set target temperature"
            color: "cyan"
            min: 5; max: 35; step: 0.5
            value: root.localSetTemp
            enabledState: !root.commError
            onValueUpdated: function(v) { root.localSetTemp = v; debounce.restart() }
        }
    }

    // ============ Actions ============
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 8
        spacing: 12

        Ui.AppButton {
            Layout.fillWidth: true
            text: "Start"
            variant: "success"
            size: "lg"
            enabledState: !root.commError && !root.running
            onClicked: root.start()
        }
        Ui.AppButton {
            Layout.fillWidth: true
            text: "Stop"
            variant: "danger"
            size: "lg"
            enabledState: !root.commError && root.running
            onClicked: root.stop()
        }
        Ui.AppButton {
            Layout.fillWidth: true
            text: "Close"
            variant: "default"
            size: "lg"
            onClicked: { if (appState) appState.showChillerModal = false; root.close() }
        }
    }
}
