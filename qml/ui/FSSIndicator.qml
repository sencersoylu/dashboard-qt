import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp

Item {
    id: root

    property string label: ""
    property real level: 0
    property real pressure: 0
    property bool isActive: true
    property bool hasWarning: false
    property real warningPressure: 50

    readonly property color textBlue: "#4a90e2"
    readonly property color greenStatus: "#22c55e"

    implicitWidth: 94
    implicitHeight: 280

    Column {
        anchors.fill: parent
        spacing: 8

        Text {
            text: root.label
            color: root.textBlue
            font.family: Rsp.Theme.fontFamily
            font.pixelSize: 16
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Text {
            text: "FFS"
            color: root.textBlue
            font.family: Rsp.Theme.fontFamily
            font.pixelSize: 16
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4

            Rectangle {
                width: 20; height: 20
                radius: 10
                color: root.isActive ? root.greenStatus : Rsp.Theme.rose

                Text {
                    anchors.centerIn: parent
                    text: root.isActive ? "✓" : "✗"
                    color: "#ffffff"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.isActive ? "Active" : "Off"
                color: root.isActive ? root.greenStatus : Rsp.Theme.rose
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: 12
            }
        }

        Item {
            width: 94; height: 170
            anchors.horizontalCenter: parent.horizontalCenter

            Image {
                anchors.fill: parent
                source: "../../assets/svg/fss-tank.svg"
                sourceSize: Qt.size(94, 170)
            }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 110
                spacing: 2

                Text {
                    text: "%" + root.level.toFixed(0)
                    color: "#ffffff"
                    font.family: Rsp.Theme.fontFamily
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    text: root.pressure.toFixed(1) + " Bar"
                    color: "#ffffff"
                    font.family: Rsp.Theme.fontFamily
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        Rectangle {
            visible: root.hasWarning
            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth: warnText.implicitWidth + 16
            implicitHeight: warnText.implicitHeight + 6
            radius: 4
            color: Rsp.Theme.rose

            Text {
                id: warnText
                anchors.centerIn: parent
                text: "≤ " + root.warningPressure + " Bar"
                color: "#ffffff"
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.Bold
            }
        }
    }
}
