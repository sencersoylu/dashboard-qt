import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp

Rectangle {
    id: root
    color: Rsp.Theme.bg

    ScrollView {
        anchors.fill: parent
        anchors.margins: Rsp.Theme.spacingLg
        clip: true

        ColumnLayout {
            width: root.width - Rsp.Theme.spacingLg * 2
            spacing: Rsp.Theme.spacingLg

            Text {
                text: "UI Component Showcase"
                color: Rsp.Theme.text
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: Rsp.Theme.fontSizeXl
                font.weight: Font.Bold
            }

            Text {
                text: "Press Esc or Ctrl+S to return to Main."
                color: Rsp.Theme.textMuted
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: Rsp.Theme.fontSizeMd
            }

            Rectangle {
                Layout.preferredHeight: 80
                Layout.fillWidth: true
                radius: Rsp.Theme.radiusMd
                color: Rsp.Theme.bgPanel
                border.color: Rsp.Theme.border
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "Bundles 2–5 populate this page."
                    color: Rsp.Theme.textMuted
                    font.family: Rsp.Theme.fontFamily
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.parent.StackView ? root.parent.StackView.view.pop() : null
    }
}
