import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp

Item {
    id: root

    property real pressure: 0
    property string label: ""
    property string subLabel: ""
    property string type: "air"

    readonly property color textBlue: "#4a90e2"

    implicitHeight: image.implicitHeight + labels.implicitHeight + 12
    implicitWidth: type === "cylinder" ? 32 * 8 + 6 * 7 : 110

    Column {
        anchors.fill: parent
        spacing: 8

        Item {
            id: image
            width: parent.width
            height: type === "cylinder" ? 190 : 150

            Image {
                anchors.centerIn: parent
                source: type === "air"      ? "../../assets/svg/tank-air.svg"
                      : type === "nitrogen" ? "../../assets/svg/tank-nitrogen.svg"
                      : ""
                visible: type !== "cylinder"
                sourceSize: Qt.size(110, 150)
                width: 110; height: 150
            }

            Row {
                anchors.centerIn: parent
                spacing: 6
                visible: type === "cylinder"
                Repeater {
                    model: 8
                    Image {
                        source: "../../assets/svg/tank-cylinder.svg"
                        sourceSize: Qt.size(32, 190)
                        width: 32; height: 190
                    }
                }
            }
        }

        Column {
            id: labels
            width: parent.width
            spacing: 2

            Text {
                visible: root.subLabel !== ""
                text: root.subLabel
                color: root.textBlue
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: 16
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: root.label
                color: root.textBlue
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: 16
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: root.pressure.toFixed(0) + " Bar"
                color: root.textBlue
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: 20
                font.weight: Font.Bold
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
