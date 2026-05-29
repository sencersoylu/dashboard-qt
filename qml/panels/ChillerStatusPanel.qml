import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp

Rectangle {
    id: root

    property bool isRunning: appState ? appState.chillerRunning : false
    property real setTemp: appState ? appState.chillerSetTemp : 0
    property real currentTemp: appState ? appState.chillerCurrentTemp : 0
    property bool commError: appState ? appState.chillerCommError : false

    implicitWidth: 220
    implicitHeight: 140
    radius: Rsp.Theme.radiusLg
    color: Rsp.Theme.bgPanel
    border.color: Rsp.Theme.border
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Chiller"
                color: Rsp.Theme.text
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: Rsp.Theme.fontSizeMd
                font.weight: Font.Bold
                Layout.fillWidth: true
            }

            Rectangle {
                implicitHeight: 24
                implicitWidth: badgeText.implicitWidth + 16
                radius: 12
                color: root.commError ? Rsp.Theme.amber
                      : root.isRunning ? Rsp.Theme.emerald
                      : Rsp.Theme.rose
                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: root.commError ? "COMM" : (root.isRunning ? "ON" : "OFF")
                    color: "#ffffff"
                    font.family: Rsp.Theme.fontFamily
                    font.pixelSize: Rsp.Theme.fontSizeSm
                    font.weight: Font.Bold
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                Text {
                    text: "SV"
                    color: Rsp.Theme.textMuted
                    font.family: Rsp.Theme.fontFamily
                    font.pixelSize: Rsp.Theme.fontSizeSm
                }
                Text {
                    text: root.commError ? "— °C" : root.setTemp.toFixed(1) + " °C"
                    color: Rsp.Theme.cyan
                    font.family: Rsp.Theme.fontFamily
                    font.pixelSize: Rsp.Theme.fontSizeXl
                    font.weight: Font.Bold
                }
            }

            Rectangle { width: 1; Layout.fillHeight: true; color: Rsp.Theme.border }

            ColumnLayout {
                Layout.fillWidth: true
                Text {
                    text: "PV"
                    color: Rsp.Theme.textMuted
                    font.family: Rsp.Theme.fontFamily
                    font.pixelSize: Rsp.Theme.fontSizeSm
                }
                Text {
                    text: root.commError ? "— °C" : root.currentTemp.toFixed(1) + " °C"
                    color: Rsp.Theme.text
                    font.family: Rsp.Theme.fontFamily
                    font.pixelSize: Rsp.Theme.fontSizeXl
                    font.weight: Font.Bold
                }
            }
        }
    }
}
