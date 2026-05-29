import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp

Item {
    id: root

    implicitWidth: 560
    implicitHeight: 200

    readonly property color compartmentColor: appState && appState.darkMode
        ? Qt.rgba(0.12, 0.16, 0.23, 0.5)
        : Qt.rgba(0.88, 0.91, 0.94, 0.6)
    readonly property color borderColor: Rsp.Theme.border
    readonly property color pipeColor: Rsp.Theme.slate500

    Rectangle {
        id: leftCap
        anchors.left: parent.left
        anchors.verticalCenter: gridArea.verticalCenter
        width: 24; height: gridArea.height + 24
        radius: 12
        color: root.pipeColor
    }
    Rectangle {
        id: rightCap
        anchors.right: parent.right
        anchors.verticalCenter: gridArea.verticalCenter
        width: 24; height: gridArea.height + 24
        radius: 12
        color: root.pipeColor
    }

    GridLayout {
        id: gridArea
        anchors.centerIn: parent
        anchors.leftMargin: 32
        anchors.rightMargin: 32
        width: parent.width - 64
        columns: 7
        rowSpacing: 4
        columnSpacing: 4

        Repeater {
            model: 14
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                radius: Rsp.Theme.radiusSm
                color: root.compartmentColor
                border.color: root.borderColor
                border.width: 1
            }
        }
    }

    Rectangle {
        anchors.top: gridArea.bottom
        anchors.topMargin: 16
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 80
        height: 12
        radius: 4
        color: Rsp.Theme.slate700
    }
}
