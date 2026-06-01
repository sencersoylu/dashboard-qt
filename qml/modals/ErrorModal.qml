import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp
import "../ui" as Ui

Ui.AppModal {
    id: root
    title: ""
    size: "md"

    // After user dismisses, suppress re-opening until the master gate
    // (data[19] bit 0) drops back to 0 on the Python side. We also pin a
    // 500 ms floor so an immediate next PLC frame (before the writeBit
    // clears the bit) can't race the modal back open.
    Timer {
        id: minHold
        interval: 500
        repeat: false
    }

    function dismiss() {
        plcClient.writeBit("M0400", 0)
        appState.errorModalSuppressed = true
        appState.showErrorModal = false
        minHold.restart()
        root.close()
    }

    Item {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: 88; implicitHeight: 88
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Qt.rgba(0.96, 0.27, 0.32, 0.15)
        }
        Text {
            anchors.centerIn: parent
            text: "⚠"
            color: Rsp.Theme.rose
            font.pixelSize: 52
            font.weight: Font.Bold
        }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: "Warning"
        color: Rsp.Theme.text
        font.family: Rsp.Theme.fontFamily
        font.pixelSize: 36
        font.weight: Font.Bold
    }

    Text {
        Layout.fillWidth: true
        text: appState ? appState.errorMessage : ""
        color: Rsp.Theme.textMuted
        font.family: Rsp.Theme.fontFamily
        font.pixelSize: 22
        font.weight: Font.Medium
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
    }

    Item {
        Layout.fillWidth: true
        Layout.topMargin: 8
        Layout.preferredHeight: 72

        Rectangle {
            anchors.fill: parent
            radius: Rsp.Theme.radiusMd
            color: Rsp.Theme.rose
            opacity: minHold.running ? 0.5 : 1.0
            scale: okArea.pressed ? 0.98 : (okArea.containsMouse ? 1.02 : 1.0)
            Behavior on scale { NumberAnimation { duration: Rsp.Theme.animFast } }
            Behavior on opacity { NumberAnimation { duration: Rsp.Theme.animFast } }

            Text {
                anchors.centerIn: parent
                text: "OK"
                color: "#ffffff"
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: 24
                font.weight: Font.DemiBold
            }

            MouseArea {
                id: okArea
                anchors.fill: parent
                hoverEnabled: true
                enabled: !minHold.running
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                onClicked: root.dismiss()
            }
        }
    }
}
