import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp

Rectangle {
    id: root

    implicitHeight: 96
    color: Rsp.Theme.bgPanel
    border.color: Rsp.Theme.border
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        spacing: 16

        Image {
            source: "../../assets/images/hipertech-logo.svg"
            Layout.preferredHeight: 64
            Layout.preferredWidth: 320
            fillMode: Image.PreserveAspectFit
            sourceSize: Qt.size(640, 128)
        }

        Item { Layout.fillWidth: true }

        Rectangle {
            implicitWidth: 44; implicitHeight: 44
            radius: 22
            color: themeArea.containsMouse ? Rsp.Theme.border : "transparent"
            Behavior on color { ColorAnimation { duration: Rsp.Theme.animFast } }

            Text {
                anchors.centerIn: parent
                text: appState && appState.darkMode ? "☀" : "☾"
                color: Rsp.Theme.text
                font.pixelSize: 20
            }

            MouseArea {
                id: themeArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: appState.darkMode = !appState.darkMode
            }
        }

        Rectangle {
            implicitHeight: 36
            implicitWidth: connText.implicitWidth + 32
            radius: 18
            color: (appState && appState.connected) ? Rsp.Theme.emerald : Rsp.Theme.rose

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 6

                Text {
                    text: (appState && appState.connected) ? "●" : "○"
                    color: "#ffffff"
                    font.pixelSize: 14
                }
                Text {
                    id: connText
                    text: (appState && appState.connected) ? "Connected" : "Disconnected"
                    color: "#ffffff"
                    font.family: Rsp.Theme.fontFamily
                    font.pixelSize: Rsp.Theme.fontSizeSm
                    font.weight: Font.DemiBold
                }
            }
        }

        Rectangle {
            implicitHeight: 36
            implicitWidth: timeRow.implicitWidth + 32
            radius: 18
            color: Rsp.Theme.bg
            border.color: Rsp.Theme.border
            border.width: 1

            RowLayout {
                id: timeRow
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                Text {
                    text: appState ? appState.currentTime2 : ""
                    color: Rsp.Theme.textMuted
                    font.family: Rsp.Theme.fontFamily
                    font.pixelSize: Rsp.Theme.fontSizeSm
                }
                Rectangle {
                    width: 1; height: 16; color: Rsp.Theme.border
                }
                Text {
                    text: appState ? appState.currentTime : ""
                    color: Rsp.Theme.text
                    font.family: Rsp.Theme.fontFamily
                    font.pixelSize: Rsp.Theme.fontSizeMd
                    font.weight: Font.DemiBold
                }
            }
        }
    }
}
