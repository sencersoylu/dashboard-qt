import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp

Item {
    id: root

    property real value: 0
    property real min: 0
    property real max: 100
    property real step: 1
    property string label: ""
    property string color: "blue"
    property string size: "md"
    property bool showLabels: true
    property string leftLabel: ""
    property string centerLabel: ""
    property string rightLabel: ""
    property string unit: ""
    property bool enabledState: true

    signal valueUpdated(real v)

    readonly property var colorMap: ({
        "blue":    "#3b82f6",
        "emerald": Rsp.Theme.emerald,
        "amber":   Rsp.Theme.amber,
        "rose":    Rsp.Theme.rose,
        "indigo":  "#6366f1",
        "cyan":    Rsp.Theme.cyan
    })

    readonly property var sizeMap: ({
        "sm": { track: 6,  thumb: 20 },
        "md": { track: 10, thumb: 28 },
        "lg": { track: 14, thumb: 36 }
    })

    readonly property string activeColor: colorMap[color] || colorMap["blue"]
    readonly property var m: sizeMap[size] || sizeMap["md"]
    readonly property real ratio: max > min ? (value - min) / (max - min) : 0

    implicitHeight: (label !== "" ? 36 : 0) + m.thumb + (showLabels ? 24 : 0)
    implicitWidth: 320
    opacity: enabledState ? 1.0 : 0.5

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            visible: root.label !== ""

            Text {
                text: root.label
                color: Rsp.Theme.text
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: Rsp.Theme.fontSizeMd
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }
            Text {
                text: Math.round(root.value) + (root.unit !== "" ? " " + root.unit : "")
                color: root.activeColor
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: Rsp.Theme.fontSizeXl
                font.weight: Font.Bold
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.m.thumb

            Rectangle {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: root.m.track
                radius: height / 2
                color: appState && appState.darkMode ? Rsp.Theme.slate700 : "#e2e8f0"
            }

            Rectangle {
                anchors.left: track.left
                anchors.verticalCenter: track.verticalCenter
                width: track.width * root.ratio
                height: track.height
                radius: track.radius
                color: root.activeColor
                Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }

            Rectangle {
                id: thumb
                width: root.m.thumb
                height: root.m.thumb
                radius: width / 2
                color: "#ffffff"
                border.color: root.activeColor
                border.width: 3
                x: track.width * root.ratio - width / 2
                anchors.verticalCenter: track.verticalCenter
                scale: thumbArea.containsMouse || thumbArea.drag.active ? 1.1 : 1.0
                Behavior on scale { NumberAnimation { duration: Rsp.Theme.animFast } }

                MouseArea {
                    id: thumbArea
                    anchors.fill: parent
                    enabled: root.enabledState
                    hoverEnabled: true
                    drag.target: thumb
                    drag.axis: Drag.XAxis
                    drag.minimumX: -thumb.width / 2
                    drag.maximumX: track.width - thumb.width / 2
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor

                    onPositionChanged: if (drag.active) {
                        const r = Math.max(0, Math.min(1, (thumb.x + thumb.width / 2) / track.width))
                        const raw = root.min + r * (root.max - root.min)
                        const stepped = Math.round(raw / root.step) * root.step
                        if (stepped !== root.value) {
                            root.value = stepped
                            root.valueUpdated(stepped)
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.showLabels
            spacing: 0

            Text {
                text: root.leftLabel !== "" ? root.leftLabel : Math.round(root.min)
                color: Rsp.Theme.textMuted
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: Rsp.Theme.fontSizeSm
            }
            Item { Layout.fillWidth: true }
            Text {
                visible: root.centerLabel !== ""
                text: root.centerLabel
                color: Rsp.Theme.textMuted
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: Rsp.Theme.fontSizeSm
            }
            Item { Layout.fillWidth: true; visible: root.centerLabel !== "" }
            Text {
                text: root.rightLabel !== "" ? root.rightLabel : Math.round(root.max)
                color: Rsp.Theme.textMuted
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: Rsp.Theme.fontSizeSm
            }
        }
    }
}
