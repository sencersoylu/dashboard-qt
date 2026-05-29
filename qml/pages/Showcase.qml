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

            // ===== Card ===============================================
            Text {
                text: "Card"
                color: Rsp.Theme.text
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: Rsp.Theme.fontSizeLg
                font.weight: Font.Bold
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                Ui.Card {
                    Layout.preferredWidth: 320
                    title: "Plain card"
                    Text {
                        text: "Body content."
                        color: Rsp.Theme.text
                        font.family: Rsp.Theme.fontFamily
                    }
                }

                Ui.Card {
                    Layout.preferredWidth: 320
                    title: "Hoverable"
                    hoverable: true
                    Text {
                        text: "Hover me."
                        color: Rsp.Theme.text
                        font.family: Rsp.Theme.fontFamily
                    }
                }

                Ui.Card {
                    Layout.preferredWidth: 320
                    title: "Loading"
                    isLoading: true
                }
            }

            // ===== AppModal ===========================================
            Text {
                text: "AppModal"
                color: Rsp.Theme.text
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: Rsp.Theme.fontSizeLg
                font.weight: Font.Bold
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Ui.AppButton { text: "Open small";  variant: "info"; onClicked: { demoModal.size = "sm";  demoModal.open() } }
                Ui.AppButton { text: "Open medium"; variant: "info"; onClicked: { demoModal.size = "md";  demoModal.open() } }
                Ui.AppButton { text: "Open large";  variant: "info"; onClicked: { demoModal.size = "lg";  demoModal.open() } }
            }
            Ui.AppModal {
                id: demoModal
                title: "Demo modal"
                Text {
                    text: "Esc, backdrop click, or × button closes."
                    color: Rsp.Theme.text
                    font.family: Rsp.Theme.fontFamily
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
                Ui.AppButton {
                    text: "Close"
                    variant: "default"
                    onClicked: demoModal.close()
                }
            }

            // ===== ToggleSwitch =======================================
            Text {
                text: "ToggleSwitch"
                color: Rsp.Theme.text
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: Rsp.Theme.fontSizeLg
                font.weight: Font.Bold
            }
            Ui.ToggleSwitch {
                Layout.preferredWidth: 320
                states: [
                    { "label": "Off", "color": Rsp.Theme.slate500 },
                    { "label": "On",  "color": Rsp.Theme.emerald  }
                ]
            }
            Ui.ToggleSwitch {
                Layout.preferredWidth: 480
                states: [
                    { "label": "Air",   "color": Rsp.Theme.sky     },
                    { "label": "Auto",  "color": Rsp.Theme.emerald },
                    { "label": "Manual","color": Rsp.Theme.amber   }
                ]
            }

            // ===== AppSlider ==========================================
            Text {
                text: "AppSlider"
                color: Rsp.Theme.text
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: Rsp.Theme.fontSizeLg
                font.weight: Font.Bold
            }
            Ui.AppSlider { Layout.preferredWidth: 480; label: "Brightness"; value: 64;  color: "blue"     }
            Ui.AppSlider { Layout.preferredWidth: 480; label: "Temp";       value: 22;  color: "emerald"; min: 0; max: 40 }
            Ui.AppSlider { Layout.preferredWidth: 480; label: "Warning";    value: 80;  color: "amber";   size: "lg" }
            Ui.AppSlider { Layout.preferredWidth: 480; label: "Disabled";   value: 50;  color: "rose";    enabledState: false }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.parent.StackView ? root.parent.StackView.view.pop() : null
    }
}
