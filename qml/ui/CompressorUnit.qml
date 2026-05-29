import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp

Item {
    id: root

    property string label: ""
    property bool status: false

    readonly property color textBlue: "#4a90e2"
    readonly property color greenStatus: "#22c55e"

    implicitWidth: 200
    implicitHeight: 260

    Column {
        anchors.fill: parent
        spacing: 8

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            Rectangle {
                width: 32; height: 32
                radius: 16
                color: root.status ? root.greenStatus : Rsp.Theme.rose
                Text {
                    anchors.centerIn: parent
                    text: root.status ? "✓" : "✗"
                    color: "#ffffff"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.status ? "On" : "Off"
                color: root.status ? root.greenStatus : Rsp.Theme.rose
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: 16
            }
        }

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            source: "../../assets/svg/compressor.svg"
            sourceSize: Qt.size(200, 160)
            width: 200; height: 160
        }

        Text {
            text: root.label
            color: root.textBlue
            font.family: Rsp.Theme.fontFamily
            font.pixelSize: 24
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
