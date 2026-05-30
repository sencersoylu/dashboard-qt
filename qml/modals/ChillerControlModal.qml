import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp
import "../ui" as Ui

Ui.AppModal {
    id: root
    title: ""              // header is below the AppModal close strip
    showCloseButton: true  // use AppModal's built-in close (top-right)
    size: "md"

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

    function toggleChiller() {
        var next = root.running ? 0 : 1
        plcClient.writeRegister("D00208", next)
        appState.chillerRunning = !root.running
    }

    readonly property bool commError: appState && appState.chillerCommError
    readonly property bool running:   appState && appState.chillerRunning && !commError

    // ============ Big Temperature Card (with header) ============
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 220
        Layout.topMargin: 4
        radius: 20
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop {
                position: 0.0
                color: appState && appState.darkMode
                       ? Qt.rgba(Rsp.Theme.cyan.r, Rsp.Theme.cyan.g, Rsp.Theme.cyan.b, 0.10)
                       : "#ecfeff"
            }
            GradientStop {
                position: 1.0
                color: appState && appState.darkMode
                       ? Qt.rgba(0.23, 0.51, 0.96, 0.06)
                       : "#eff6ff"
            }
        }
        border.color: appState && appState.darkMode
                      ? Qt.rgba(Rsp.Theme.cyan.r, Rsp.Theme.cyan.g, Rsp.Theme.cyan.b, 0.18)
                      : "#cffafe"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 0

            // ----- Card Header: snowflake (white) + "Chiller Status" + status pill
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Image {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    source: "../../assets/icons/snowflake-white.svg"
                    sourceSize: Qt.size(24, 24)
                }
                Text {
                    text: "Chiller Status"
                    color: Rsp.Theme.text
                    font.family: Rsp.Theme.fontFamily
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }
                Item { Layout.fillWidth: true }

                // Status pill
                Rectangle {
                    implicitHeight: 32
                    implicitWidth: statusContent.implicitWidth + 24
                    radius: 16
                    color: root.running
                           ? Rsp.Theme.emerald
                           : (appState && appState.darkMode ? Rsp.Theme.slate700 : "#cbd5e1")

                    RowLayout {
                        id: statusContent
                        anchors.centerIn: parent
                        spacing: 8

                        Rectangle {
                            visible: root.running
                            implicitWidth: 8; implicitHeight: 8
                            radius: 4
                            color: "#ffffff"
                            SequentialAnimation on opacity {
                                running: root.running
                                loops: Animation.Infinite
                                NumberAnimation { from: 1.0; to: 0.4; duration: 700; easing.type: Easing.InOutQuad }
                                NumberAnimation { from: 0.4; to: 1.0; duration: 700; easing.type: Easing.InOutQuad }
                            }
                        }
                        Text {
                            text: root.running ? "Running" : "Stopped"
                            color: root.running
                                   ? "#ffffff"
                                   : (appState && appState.darkMode ? Rsp.Theme.slate300 : Rsp.Theme.slate500)
                            font.family: Rsp.Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // ----- Card Body: "Current Water Temperature" + huge number
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Current Water Temperature"
                color: appState && appState.darkMode ? Rsp.Theme.slate300 : Rsp.Theme.slate500
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: 15
                font.weight: Font.Medium
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 4
                spacing: 4

                Text {
                    text: root.commError
                          ? "––"
                          : (appState ? appState.chillerCurrentTemp.toFixed(1) : "––")
                    color: appState && appState.darkMode ? Rsp.Theme.text : Rsp.Theme.slate700
                    font.family: Rsp.Theme.fontFamily
                    font.pixelSize: 64
                    font.weight: Font.Bold
                }
                Text {
                    text: "°C"
                    color: appState && appState.darkMode ? Rsp.Theme.slate300 : Rsp.Theme.slate700
                    font.family: Rsp.Theme.fontFamily
                    font.pixelSize: 32
                    Layout.bottomMargin: 8
                }
            }

            Item { Layout.fillHeight: true }
        }
    }

    // ============ Slider — Target Temp ============
    Ui.AppSlider {
        Layout.fillWidth: true
        Layout.topMargin: 8
        label: "Target Water Temperature"
        color: "cyan"
        unit: "°C"
        min: 5; max: 35; step: 0.5
        value: root.localSetTemp
        enabledState: !root.commError
        leftLabel: "5°C"
        centerLabel: "20°C"
        rightLabel: "35°C"
        onValueUpdated: function(v) { root.localSetTemp = v; debounce.restart() }
    }

    // ============ Divider ============
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        Layout.topMargin: 4
        color: Rsp.Theme.border
    }

    // ============ Action Buttons ============
    // Single Start/Stop button with power icon, then Close
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 64

        Rectangle {
            id: powerBtn
            anchors.fill: parent
            radius: Rsp.Theme.radiusMd
            color: root.running ? Rsp.Theme.rose : Rsp.Theme.emerald
            opacity: root.commError ? 0.4 : 1.0
            scale: powerArea.pressed ? 0.98 : (powerArea.containsMouse ? 1.02 : 1.0)
            Behavior on color { ColorAnimation { duration: Rsp.Theme.animMed } }
            Behavior on scale { NumberAnimation { duration: Rsp.Theme.animFast } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 12

                Image {
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    source: "../../assets/icons/power.svg"
                    sourceSize: Qt.size(22, 22)
                }
                Text {
                    text: root.running ? "Stop Chiller" : "Start Chiller"
                    color: "#ffffff"
                    font.family: Rsp.Theme.fontFamily
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }
            }

            MouseArea {
                id: powerArea
                anchors.fill: parent
                hoverEnabled: true
                enabled: !root.commError
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                onClicked: root.toggleChiller()
            }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 48
        Layout.topMargin: 4

        Rectangle {
            id: closeBtn
            anchors.fill: parent
            radius: Rsp.Theme.radiusMd
            color: appState && appState.darkMode ? Rsp.Theme.slate700 : "#94a3b8"
            scale: closeArea.pressed ? 0.98 : (closeArea.containsMouse ? 1.02 : 1.0)
            Behavior on scale { NumberAnimation { duration: Rsp.Theme.animFast } }

            Text {
                anchors.centerIn: parent
                text: "Close"
                color: "#ffffff"
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }

            MouseArea {
                id: closeArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (appState) appState.showChillerModal = false
                    root.close()
                }
            }
        }
    }
}
