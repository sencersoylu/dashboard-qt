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
        plcClient.writeRegister("R0030", 0)
        appState.showSeatAlarmModal = false
        appState.activeSeatAlarm = null
        root.close()
    }

    Item {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: 96; implicitHeight: 96

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Qt.rgba(0.96, 0.27, 0.32, 0.15)

            SequentialAnimation on scale {
                running: visible
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 1.1; duration: 600; easing.type: Easing.InOutQuad }
                NumberAnimation { from: 1.1; to: 1.0; duration: 600; easing.type: Easing.InOutQuad }
            }
        }
        Image {
            anchors.centerIn: parent
            source: "../../assets/icons/armchair.svg"
            sourceSize.width: 48
            sourceSize.height: 48
            fillMode: Image.PreserveAspectFit
        }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: "Seat Alarm"
        color: Rsp.Theme.text
        font.family: Rsp.Theme.fontFamily
        font.pixelSize: Rsp.Theme.fontSizeXl
        font.weight: Font.Bold
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: appState && appState.activeSeatAlarm
              ? (appState.activeSeatAlarm.seatNumber || "—").toString()
              : "—"
        color: Rsp.Theme.rose
        font.family: Rsp.Theme.fontFamily
        font.pixelSize: 96
        font.weight: Font.Bold
    }

    Ui.AppButton {
        Layout.fillWidth: true
        text: "Close Alarm"
        variant: "danger"
        onClicked: root.dismiss()
    }
}
