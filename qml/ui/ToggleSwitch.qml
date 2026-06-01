import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp

Rectangle {
    id: root

    property int value: 0
    property var states: []
    property bool enabledState: true

    signal valueUpdated(int newIndex)

    implicitHeight: 56
    implicitWidth: 320
    radius: height / 2
    color: appState && appState.darkMode ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0.8, 0.83, 0.87, 0.8)
    opacity: enabledState ? 1.0 : 0.4
    clip: true

    Behavior on opacity { NumberAnimation { duration: Rsp.Theme.animMed } }

    readonly property int pillMargin: 4
    readonly property real cellWidth: states.length > 0 ? width / states.length : 0
    readonly property real pillWidth: Math.max(0, cellWidth - pillMargin * 2)

    Rectangle {
        id: pill
        height: parent.height - root.pillMargin * 2
        width: root.pillWidth
        radius: height / 2
        color: root.states.length > 0 && root.value < root.states.length
                ? root.states[root.value].color
                : Rsp.Theme.slate500
        y: root.pillMargin
        x: root.value * root.cellWidth + root.pillMargin

        Behavior on x     { NumberAnimation { duration: Rsp.Theme.animMed; easing.type: Easing.InOutCubic } }
        Behavior on color { ColorAnimation  { duration: Rsp.Theme.animMed } }
    }

    Row {
        anchors.fill: parent
        Repeater {
            model: root.states
            Item {
                width: root.width / root.states.length
                height: root.height

                Text {
                    anchors.centerIn: parent
                    text: modelData.label
                    color: index === root.value
                           ? "#ffffff"
                           : (appState && appState.darkMode
                                ? Qt.rgba(1, 1, 1, 0.4)
                                : Rsp.Theme.slate500)
                    font.family: Rsp.Theme.fontFamily
                    font.pixelSize: root.states.length <= 2
                                    ? Rsp.Theme.fontSizeMd
                                    : Rsp.Theme.fontSizeSm
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 0.9
                    wrapMode: Text.NoWrap
                    Behavior on color { ColorAnimation { duration: Rsp.Theme.animMed } }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.enabledState
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                    // Fire the signal only — DO NOT assign root.value here.
                    // The parent QML binds `value` to a state property (e.g.
                    // appState.airMode). Direct assignment would sever that
                    // binding, leaving the pill frozen when the state is
                    // later updated programmatically (e.g. force-Air on
                    // entering Automatic).
                    onClicked: if (index !== root.value) root.valueUpdated(index)
                }
            }
        }
    }
}
