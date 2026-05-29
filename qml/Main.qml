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
    // page, its own screen, and its own shortcut set. `property Component`
    // with an inline element auto-wraps the element in a Component — the
    // only form QtObject (which lacks a default property) accepts.
    property Component winComponent: ApplicationWindow {
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
            // Stay hidden until Component.onCompleted has placed us on the
            // correct screen — otherwise the FullScreen request fires on
            // the default monitor and labwc never re-homes the surface.
            visibility: Window.Hidden

            Component.onCompleted: {
                var screens = Qt.application.screens
                var idx = (cfg && cfg.display !== undefined) ? cfg.display : 0
                if (idx >= screens.length) {
                    console.warn("Window '" + (cfg ? cfg.id : "?") + "' wants display "
                                 + idx + " but only " + screens.length
                                 + " available — falling back to 0")
                    idx = 0
                }
                var target = screens[idx]
                console.log("Window '" + (cfg ? cfg.id : "?") + "' → screen "
                            + idx + " (" + target.name + ") at "
                            + target.virtualX + "," + target.virtualY)
                // Move the window into the target screen's bounds *before*
                // showing it. labwc fullscreens whatever monitor contains
                // the window's top-left corner.
                win.x = target.virtualX
                win.y = target.virtualY
                win.width = target.geometry.width
                win.height = target.geometry.height
                win.screen = target
                if (!cfg || cfg.fullscreen !== false) {
                    win.showFullScreen()
                } else {
                    win.show()
                }
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
