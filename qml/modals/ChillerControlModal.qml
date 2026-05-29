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
        Layout.bottomMargin: 4
        spacing: 14

        // Icon badge — radial gradient backdrop + soft outer halo + crisp snowflake
        Item {
            implicitWidth: 56; implicitHeight: 56

            // Soft outer halo (slightly larger than the badge)
            Rectangle {
                anchors.centerIn: parent
                width: 72; height: 72
                radius: width / 2
                color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.10)
                opacity: 0.85
                SequentialAnimation on opacity {
                    running: root.running
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.55; to: 0.95; duration: 1200; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 0.95; to: 0.55; duration: 1200; easing.type: Easing.InOutQuad }
                }
            }

            // Main badge — radial gradient hint via two stacked rectangles
            Rectangle {
                anchors.fill: parent
                radius: 14
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.28) }
                    GradientStop { position: 1.0; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.10) }
                }
                border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.45)
                border.width: 1
            }

            // Sheen highlight along the top
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 1
                height: parent.height * 0.5
                radius: 13
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.10) }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.00) }
                }
            }

            Image {
                anchors.centerIn: parent
                source: "../../assets/icons/snowflake.svg"
                sourceSize: Qt.size(28, 28)
                width: 28; height: 28
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            Text {
                text: "Chiller Control"
                color: Rsp.Theme.text
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: 22
                font.weight: Font.Bold
            }
            // Status pill — tinted bg + animated dot
            Rectangle {
                Layout.preferredHeight: 24
                implicitWidth: statusRow.implicitWidth + 18
                radius: 12
                color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.15)
                border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.35)
                border.width: 1

                RowLayout {
                    id: statusRow
                    anchors.centerIn: parent
                    spacing: 7

                    Rectangle {
                        implicitWidth: 7; implicitHeight: 7
                        radius: 3.5
                        color: root.accent
                        SequentialAnimation on opacity {
                            running: root.running
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 0.35; duration: 700; easing.type: Easing.InOutQuad }
                            NumberAnimation { from: 0.35; to: 1.0; duration: 700; easing.type: Easing.InOutQuad }
                        }
                    }
                    Text {
                        text: root.commError ? "Communication Error"
                              : root.running   ? "Running"
                                               : "Stopped"
                        color: root.accent
                        font.family: Rsp.Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        font.letterSpacing: 0.4
                    }
                }
            }
        }

        // Close button
        Item {
            Layout.alignment: Qt.AlignTop
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
    readonly property real currentTemp: appState ? appState.chillerCurrentTemp : 0.0
    readonly property real delta: root.commError ? 0.0 : (root.currentTemp - root.localSetTemp)
    readonly property bool atTarget: Math.abs(root.delta) < 0.3
    readonly property color deltaColor: root.commError ? Rsp.Theme.textMuted
                                        : root.atTarget ? Rsp.Theme.emerald
                                        : root.delta > 0 ? Rsp.Theme.amber
                                                         : Rsp.Theme.sky

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 12

        // Current temp card
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 134
            radius: Rsp.Theme.radiusMd
            color: Qt.rgba(1, 1, 1, 0.04)
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
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
                    Item { Layout.fillWidth: true }

                    // Δ chip — sits inline with the CURRENT label
                    Rectangle {
                        visible: !root.commError
                        implicitHeight: 20
                        implicitWidth: deltaLabel.implicitWidth + 14
                        radius: 10
                        color: Qt.rgba(root.deltaColor.r, root.deltaColor.g, root.deltaColor.b, 0.18)
                        border.color: Qt.rgba(root.deltaColor.r, root.deltaColor.g, root.deltaColor.b, 0.35)
                        border.width: 1

                        Text {
                            id: deltaLabel
                            anchors.centerIn: parent
                            text: root.atTarget
                                  ? "● on target"
                                  : (root.delta > 0 ? "▲ " : "▼ ")
                                    + Math.abs(root.delta).toFixed(1) + "°C"
                            color: root.deltaColor
                            font.family: Rsp.Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            font.letterSpacing: 0.3
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    spacing: 4
                    Text {
                        text: root.commError
                              ? "––"
                              : root.currentTemp.toFixed(1)
                        color: Rsp.Theme.text
                        font.family: Rsp.Theme.fontFamily
                        font.pixelSize: 46
                        font.weight: Font.Bold
                    }
                    Text {
                        text: "°C"
                        color: Rsp.Theme.textMuted
                        font.family: Rsp.Theme.fontFamily
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                        Layout.bottomMargin: 8
                    }
                }
            }
        }

        // Target temp card (cyan accent + gradient bg)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 134
            radius: Rsp.Theme.radiusMd
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Qt.rgba(Rsp.Theme.cyan.r, Rsp.Theme.cyan.g, Rsp.Theme.cyan.b, 0.18) }
                GradientStop { position: 1.0; color: Qt.rgba(Rsp.Theme.cyan.r, Rsp.Theme.cyan.g, Rsp.Theme.cyan.b, 0.06) }
            }
            border.color: Qt.rgba(Rsp.Theme.cyan.r, Rsp.Theme.cyan.g, Rsp.Theme.cyan.b, 0.35)
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
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
                    Item { Layout.fillWidth: true }
                    // Range hint chip
                    Text {
                        text: "5 – 35 °C"
                        color: Qt.rgba(Rsp.Theme.cyan.r, Rsp.Theme.cyan.g, Rsp.Theme.cyan.b, 0.7)
                        font.family: Rsp.Theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 0.4
                    }
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    spacing: 4
                    Text {
                        text: root.localSetTemp.toFixed(1)
                        color: Rsp.Theme.cyan
                        font.family: Rsp.Theme.fontFamily
                        font.pixelSize: 46
                        font.weight: Font.Bold
                    }
                    Text {
                        text: "°C"
                        color: Qt.rgba(Rsp.Theme.cyan.r, Rsp.Theme.cyan.g, Rsp.Theme.cyan.b, 0.7)
                        font.family: Rsp.Theme.fontFamily
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                        Layout.bottomMargin: 8
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
