import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp
import "../panels" as Panels

Rectangle {
    id: root
    color: Rsp.Theme.bg

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const now = new Date()
            appState.currentTime = Qt.formatTime(now, "HH:mm:ss")
            appState.currentTime2 = Qt.formatDate(now, "dd MMM yyyy")
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Panels.Header {
            Layout.fillWidth: true
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Text {
                anchors.centerIn: parent
                text: "Dashboard — Bundles 2–6 fill this area"
                color: Rsp.Theme.textMuted
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: Rsp.Theme.fontSizeLg
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.parent.StackView ? root.parent.StackView.view.pop() : null
    }
}
