import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp
import "../ui" as Ui

Ui.AppModal {
    id: root
    title: ""
    size: "md"

    function dismiss() {
        plcClient.writeBit("M0400", 0)
        appState.showErrorModal = false
        root.close()
    }

    Item {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: 64; implicitHeight: 64
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Qt.rgba(0.96, 0.27, 0.32, 0.15)
        }
        Text {
            anchors.centerIn: parent
            text: "⚠"
            color: Rsp.Theme.rose
            font.pixelSize: 36
            font.weight: Font.Bold
        }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: "Uyarı"
        color: Rsp.Theme.text
        font.family: Rsp.Theme.fontFamily
        font.pixelSize: Rsp.Theme.fontSizeXl
        font.weight: Font.Bold
    }

    Text {
        Layout.fillWidth: true
        text: appState ? appState.errorMessage : ""
        color: Rsp.Theme.textMuted
        font.family: Rsp.Theme.fontFamily
        font.pixelSize: Rsp.Theme.fontSizeMd
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
    }

    Ui.AppButton {
        Layout.fillWidth: true
        text: "Tamam"
        variant: "danger"
        onClicked: root.dismiss()
    }
}
