import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp
import "../ui" as Ui

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

            // ===== AppButton ==========================================
            Text {
                text: "AppButton"
                color: Rsp.Theme.text
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: Rsp.Theme.fontSizeLg
                font.weight: Font.Bold
            }
            Flow {
                Layout.fillWidth: true
                spacing: 12
                Ui.AppButton { text: "Default";  variant: "default" }
                Ui.AppButton { text: "Success";  variant: "success" }
                Ui.AppButton { text: "Warning";  variant: "warning" }
                Ui.AppButton { text: "Danger";   variant: "danger" }
                Ui.AppButton { text: "Info";     variant: "info" }
                Ui.AppButton { text: "Muted";    variant: "muted" }
                Ui.AppButton { text: "Disabled"; variant: "default"; enabledState: false }
                Ui.AppButton { text: "Loading…"; variant: "info"; isLoading: true }
                Ui.AppButton { text: "Small";    variant: "success"; size: "sm" }
                Ui.AppButton { text: "Large";    variant: "danger"; size: "lg" }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.parent.StackView ? root.parent.StackView.view.pop() : null
    }
}
