import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp

Item {
    id: root

    property string text: ""
    property string variant: "default"
    property string size: "md"
    property bool isLoading: false
    property bool fullWidth: false
    property bool enabledState: true

    signal clicked()

    readonly property var variantColors: ({
        "default":  { bg: Rsp.Theme.slate700, hover: Rsp.Theme.slate500, fg: "#ffffff" },
        "success":  { bg: Rsp.Theme.emerald,  hover: "#0e9f6e",          fg: "#ffffff" },
        "warning":  { bg: Rsp.Theme.amber,    hover: "#d97706",          fg: "#ffffff" },
        "danger":   { bg: Rsp.Theme.rose,     hover: "#dc2626",          fg: "#ffffff" },
        "info":     { bg: Rsp.Theme.sky,      hover: "#0284c7",          fg: "#ffffff" },
        "muted":    { bg: Rsp.Theme.slate500, hover: Rsp.Theme.slate700, fg: "#ffffff" }
    })

    readonly property var sizeMetrics: ({
        "sm": { h: 40, padding: 16, fontSize: Rsp.Theme.fontSizeSm },
        "md": { h: 48, padding: 24, fontSize: Rsp.Theme.fontSizeMd },
        "lg": { h: 64, padding: 32, fontSize: Rsp.Theme.fontSizeLg }
    })

    readonly property var v: variantColors[variant] || variantColors["default"]
    readonly property var m: sizeMetrics[size] || sizeMetrics["md"]

    implicitHeight: m.h
    implicitWidth: fullWidth ? parent.width : textMetric.width + m.padding * 2 + (isLoading ? spinner.width + 8 : 0)
    width: fullWidth ? parent.width : implicitWidth
    height: m.h
    opacity: enabledState ? 1.0 : 0.5

    Behavior on opacity { NumberAnimation { duration: Rsp.Theme.animFast } }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Rsp.Theme.radiusMd
        color: mouseArea.containsMouse ? root.v.hover : root.v.bg
        scale: mouseArea.pressed ? 0.98 : (mouseArea.containsMouse ? 1.02 : 1.0)

        Behavior on color { ColorAnimation { duration: Rsp.Theme.animMed } }
        Behavior on scale { NumberAnimation { duration: Rsp.Theme.animFast; easing.type: Easing.OutCubic } }

        RowLayout {
            anchors.centerIn: parent
            spacing: 8

            BusyIndicator {
                id: spinner
                visible: root.isLoading
                running: root.isLoading
                implicitWidth: root.m.fontSize + 4
                implicitHeight: root.m.fontSize + 4
            }

            Text {
                id: label
                text: root.text
                visible: !root.isLoading
                color: root.v.fg
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: root.m.fontSize
                font.weight: Font.Medium
            }
        }
    }

    Text {
        id: textMetric
        text: root.text
        visible: false
        font.family: Rsp.Theme.fontFamily
        font.pixelSize: root.m.fontSize
        font.weight: Font.Medium
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.enabledState && !root.isLoading
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
        onClicked: root.clicked()
    }
}
