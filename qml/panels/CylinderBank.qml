import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp

Item {
    id: root

    property int cylinderCount: 8

    implicitWidth: cylinderCount * 32 + (cylinderCount - 1) * 6
    implicitHeight: 140

    Row {
        id: row
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 8
        spacing: 6

        Repeater {
            model: root.cylinderCount
            Item {
                width: 24
                height: 120

                Rectangle {
                    width: 12; height: 8
                    radius: 2
                    color: Rsp.Theme.slate500
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Rectangle {
                    width: 24; height: 96
                    y: 8
                    radius: 4
                    border.color: Rsp.Theme.slate700
                    border.width: 1
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(0.05, 0.45, 0.85, 0.4) }
                        GradientStop { position: 1.0; color: Qt.rgba(0.05, 0.45, 0.85, 0.0) }
                    }

                    Rectangle {
                        width: parent.width; height: 1
                        y: parent.height * 0.3
                        color: Qt.rgba(0.4, 0.5, 0.6, 0.4)
                    }
                    Rectangle {
                        width: parent.width; height: 1
                        y: parent.height * 0.7
                        color: Qt.rgba(0.4, 0.5, 0.6, 0.4)
                    }
                }

                Rectangle {
                    width: 24; height: 8
                    anchors.bottom: parent.bottom
                    radius: 2
                    color: Rsp.Theme.slate700
                }
            }
        }
    }

    Rectangle {
        anchors.top: row.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: row.width + 16
        height: 6
        radius: 3
        color: Rsp.Theme.slate700
    }
}
