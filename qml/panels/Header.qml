import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp

Rectangle {
    id: root

    implicitHeight: 64
    color: "transparent"

    RowLayout {
        anchors.fill: parent
        spacing: 16

        Image {
            source: "../../assets/images/hipertech-logo.svg"
            Layout.preferredHeight: 64
            Layout.preferredWidth: 354
            fillMode: Image.PreserveAspectFit
            sourceSize: Qt.size(708, 128)
        }

        Item { Layout.fillWidth: true }

        Rectangle {
            implicitWidth: 44; implicitHeight: 44
            radius: 22
            color: themeArea.containsMouse ? Rsp.Theme.border : "transparent"
            Behavior on color { ColorAnimation { duration: Rsp.Theme.animFast } }

            Image {
                anchors.centerIn: parent
                source: appState && appState.darkMode ? "../../assets/icons/sun.svg" : "../../assets/icons/moon.svg"
                sourceSize: Qt.size(22, 22)
                width: 22; height: 22
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
            implicitHeight: 38
            implicitWidth: connText.implicitWidth + 32
            radius: 19
            color: (appState && appState.connected)
                   ? Qt.rgba(0.063, 0.725, 0.506, 0.20)
                   : Qt.rgba(0.937, 0.267, 0.267, 0.20)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 8

                Image {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    source: (appState && appState.connected) ? "../../assets/icons/wifi.svg" : "../../assets/icons/wifi-off.svg"
                    sourceSize: Qt.size(16, 16)
                }
                Text {
                    id: connText
                    text: (appState && appState.connected) ? "Connected" : "Disconnected"
                    color: (appState && appState.connected) ? "#34d399" : "#f87171"
                    font.family: Rsp.Theme.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Medium
                }
            }
        }

        Rectangle {
            implicitHeight: 40
            implicitWidth: timeRow.implicitWidth + 32
            radius: 20
            color: appState && appState.darkMode ? Qt.rgba(0,0,0,0.30) : Qt.rgba(1,1,1,0.80)
            border.color: appState && appState.darkMode ? Qt.rgba(1,1,1,0.10) : Rsp.Theme.border
            border.width: 1

            RowLayout {
                id: timeRow
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 8

                Image {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    source: "../../assets/icons/calendar.svg"
                    sourceSize: Qt.size(16, 16)
                }
                Text {
                    text: appState ? appState.currentTime2 : ""
                    color: Rsp.Theme.text
                    font.family: Rsp.Theme.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Medium
                }
                Text {
                    text: "•"
                    color: Rsp.Theme.textMuted
                    font.pixelSize: 14
                }
                Image {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    source: "../../assets/icons/clock.svg"
                    sourceSize: Qt.size(16, 16)
                }
                Text {
                    text: appState ? appState.currentTime : ""
                    color: Rsp.Theme.text
                    font.family: Rsp.Theme.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Medium
                }
            }
        }
    }
}
