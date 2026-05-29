import QtQuick
import QtQuick.Window
import QtQuick.Controls
import "." as Rsp

QtObject {
    id: root

    // Shared FontLoaders — must live somewhere top-level. Stay loaded for
    // the lifetime of the process; all child windows inherit the Poppins
    // family.
    property var fonts: QtObject {
        readonly property var regular:  FontLoader { source: "../assets/fonts/Poppins-Regular.ttf" }
        readonly property var medium:   FontLoader { source: "../assets/fonts/Poppins-Medium.ttf" }
        readonly property var semibold: FontLoader { source: "../assets/fonts/Poppins-SemiBold.ttf" }
        readonly property var bold:     FontLoader { source: "../assets/fonts/Poppins-Bold.ttf" }
    }

    // One ApplicationWindow per entry in windowsConfig. Each gets its own
    // page, its own screen, and its own shortcut set.
    Component {
        id: winComponent
        ApplicationWindow {
            id: win

            property var cfg
            // Splash.qml lives in qml/pages/, so URLs resolve relative to
            // that directory. We pass `<page>.qml` (no "pages/" prefix) to
            // avoid the double-pages path issue.
            property string pageUrl: cfg ? cfg.page + ".qml" : ""

            width: 1280
            height: 720
            title: cfg ? "RSP — " + cfg.id : "RSP"
            color: Rsp.Theme.bg
            visibility: (cfg && cfg.fullscreen === false)
                        ? Window.Windowed
                        : Window.FullScreen

            // labwc + XWayland sometimes restores the prior geometry; force
            // the configured visibility once on screen.
            Component.onCompleted: {
                if (cfg && cfg.display !== undefined) {
                    var screens = Qt.application.screens
                    if (screens.length > cfg.display) {
                        win.screen = screens[cfg.display]
                    } else {
                        console.warn("Window '" + cfg.id + "' wants display "
                                     + cfg.display + " but only "
                                     + screens.length + " available — falling back to 0")
                        win.screen = screens[0]
                    }
                }
                if (!cfg || cfg.fullscreen !== false) {
                    win.showFullScreen()
                }
                // Splash → real page handover happens inside the splash
                // component itself via its `finished` signal.
                stack.replace("pages/Splash.qml", { nextPage: win.pageUrl })
            }

            Shortcut {
                sequence: "F11"
                onActivated: win.visibility = (win.visibility === Window.FullScreen)
                                              ? Window.Windowed
                                              : Window.FullScreen
            }
            Shortcut {
                sequence: "Ctrl+D"
                onActivated: appState.darkMode = !appState.darkMode
            }

            StackView {
                id: stack
                anchors.fill: parent
                initialItem: Rectangle { color: Rsp.Theme.bg }
            }
        }
    }

    Component.onCompleted: {
        if (typeof windowsConfig === "undefined" || windowsConfig.length === 0) {
            console.warn("windowsConfig empty — no windows will be created")
            return
        }
        for (var i = 0; i < windowsConfig.length; i++) {
            winComponent.createObject(root, { cfg: windowsConfig[i] })
        }
    }
}
