import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "." as Rsp

ApplicationWindow {
    id: window
    width: 1280
    height: 720
    visibility: Window.FullScreen
    title: "RSP — Qt (Phase 0)"
    color: Rsp.Theme.bg

    FontLoader { source: "../assets/fonts/Poppins-Regular.ttf" }
    FontLoader { source: "../assets/fonts/Poppins-Medium.ttf" }
    FontLoader { source: "../assets/fonts/Poppins-SemiBold.ttf" }
    FontLoader { source: "../assets/fonts/Poppins-Bold.ttf" }

    Shortcut {
        sequence: "F11"
        onActivated: window.visibility = (window.visibility === Window.FullScreen)
                                         ? Window.Windowed
                                         : Window.FullScreen
    }

    Shortcut {
        sequence: "Ctrl+D"
        onActivated: appState.darkMode = !appState.darkMode
    }

    Rectangle {
        anchors.fill: parent
        color: Rsp.Theme.bg

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Rsp.Theme.spacingMd

            Text {
                text: "RSP Qt — Phase 0"
                color: Rsp.Theme.text
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: Rsp.Theme.fontSizeXl
                font.weight: Font.Bold
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: "F11: fullscreen   ·   Ctrl+D: dark mode toggle"
                color: Rsp.Theme.textMuted
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: Rsp.Theme.fontSizeMd
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: "Dark mode: " + (Rsp.Theme.dark ? "ON" : "OFF")
                color: Rsp.Theme.emerald
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: Rsp.Theme.fontSizeLg
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
