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

            // Look up the requested screen — by name (string, stable) or
            // index (number, fallback). Returns null if name-based and the
            // monitor isn't connected yet.
            function _findScreen(wanted) {
                var screens = Qt.application.screens
                if (typeof wanted === "string") {
                    for (var s = 0; s < screens.length; s++) {
                        if (screens[s].name === wanted) return screens[s]
                    }
                    return null
                }
                var idx = wanted
                if (idx >= screens.length) return screens[0]
                return screens[idx]
            }

            function _placeOnScreen(target) {
                var name = cfg ? cfg.id : "?"
                var screens = Qt.application.screens
                console.log("Window '" + name + "' → " + target.name
                            + " at " + target.virtualX + "," + target.virtualY
                            + " (all: " + screens.map(function(x){ return x.name }).join(", ") + ")")
                win.x = target.virtualX
                win.y = target.virtualY
                win.screen = target
                if (!cfg || cfg.fullscreen !== false) {
                    win.showFullScreen()
                } else {
                    win.show()
                }
            }

            // Boot order: HDMI ports register asynchronously. If the named
            // monitor isn't visible yet, poll for up to ~15 s before giving
            // up and falling back to whatever is available.
            Timer {
                id: screenWaiter
                interval: 500
                repeat: true
                property int attempts: 0
                readonly property int maxAttempts: 30  // 30 × 500 ms = 15 s
                onTriggered: {
                    attempts++
                    var wanted = (cfg && cfg.display !== undefined) ? cfg.display : 0
                    var target = win._findScreen(wanted)
                    if (target) {
                        stop()
                        win._placeOnScreen(target)
                        return
                    }
                    if (attempts >= maxAttempts) {
                        stop()
                        var fallback = Qt.application.screens[0]
                        console.warn("Window '" + (cfg ? cfg.id : "?") + "' timed out waiting for '"
                                     + wanted + "' — using " + fallback.name)
                        win._placeOnScreen(fallback)
                    }
                }
            }

            Component.onCompleted: {
                // Try immediate placement first — covers the common case
                // where every monitor is already up.
                var wanted = (cfg && cfg.display !== undefined) ? cfg.display : 0
                var target = win._findScreen(wanted)
                if (target) {
                    win._placeOnScreen(target)
                } else {
                    console.log("Window '" + (cfg ? cfg.id : "?") + "' waiting for screen '"
                                + wanted + "' (currently: "
                                + Qt.application.screens.map(function(x){ return x.name }).join(", ") + ")")
                    screenWaiter.start()
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
