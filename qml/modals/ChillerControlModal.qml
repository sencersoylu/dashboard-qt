import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp
import "../ui" as Ui

Ui.AppModal {
    id: root
    title: "Chiller Kontrol"
    size: "md"

    property real localSetTemp: appState ? appState.chillerSetTemp : 20.0

    Timer {
        id: debounce
        interval: 500
        repeat: false
        onTriggered: {
            plcClient.writeRegister("D00202", Math.round(root.localSetTemp * 10))
            appState.chillerSetTemp = root.localSetTemp
        }
    }

    function start() { plcClient.writeRegister("D00208", 1) }
    function stop()  { plcClient.writeRegister("D00208", 0) }

    RowLayout {
        Layout.fillWidth: true

        Rectangle {
            implicitHeight: 28
            implicitWidth: stateBadge.implicitWidth + 24
            radius: 14
            color: appState && appState.chillerCommError ? Rsp.Theme.amber
                   : appState && appState.chillerRunning ? Rsp.Theme.emerald
                   : Rsp.Theme.rose
            Text {
                id: stateBadge
                anchors.centerIn: parent
                text: appState && appState.chillerCommError ? "COMM HATA"
                      : appState && appState.chillerRunning ? "Çalışıyor"
                      : "Durdu"
                color: "#ffffff"
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: Rsp.Theme.fontSizeSm
                font.weight: Font.Bold
            }
        }
        Item { Layout.fillWidth: true }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 16

        ColumnLayout {
            Layout.fillWidth: true
            Text {
                text: "Şu An"
                color: Rsp.Theme.textMuted
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: Rsp.Theme.fontSizeSm
            }
            Text {
                text: appState && appState.chillerCommError
                      ? "— °C"
                      : (appState ? appState.chillerCurrentTemp.toFixed(1) : "—") + " °C"
                color: Rsp.Theme.text
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: 36
                font.weight: Font.Bold
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Text {
                text: "Hedef"
                color: Rsp.Theme.textMuted
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: Rsp.Theme.fontSizeSm
            }
            Text {
                text: root.localSetTemp.toFixed(1) + " °C"
                color: Rsp.Theme.cyan
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: 36
                font.weight: Font.Bold
            }
        }
    }

    Ui.AppSlider {
        Layout.fillWidth: true
        label: "Hedef sıcaklık"
        color: "cyan"
        min: 5; max: 35; step: 0.5
        value: root.localSetTemp
        enabledState: !(appState && appState.chillerCommError)
        onValueUpdated: function(v) { root.localSetTemp = v; debounce.restart() }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Ui.AppButton {
            Layout.fillWidth: true
            text: "Başlat"
            variant: "success"
            enabledState: !(appState && appState.chillerCommError) && !(appState && appState.chillerRunning)
            onClicked: root.start()
        }
        Ui.AppButton {
            Layout.fillWidth: true
            text: "Durdur"
            variant: "danger"
            enabledState: !(appState && appState.chillerCommError) && (appState && appState.chillerRunning)
            onClicked: root.stop()
        }
        Ui.AppButton {
            Layout.fillWidth: true
            text: "Kapat"
            variant: "default"
            onClicked: { appState.showChillerModal = false; root.close() }
        }
    }
}
