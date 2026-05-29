pragma Singleton
import QtQuick

QtObject {
    id: theme

    // ---- Dark mode (read from AppState if present, default true) ----
    property bool dark: typeof appState !== "undefined" ? appState.darkMode : true

    // ---- Tailwind slate scale ----
    readonly property color slate50:  "#f8fafc"
    readonly property color slate200: "#e2e8f0"
    readonly property color slate300: "#cbd5e1"
    readonly property color slate500: "#64748b"
    readonly property color slate700: "#334155"
    readonly property color slate800: "#1e293b"
    readonly property color slate900: "#0f172a"

    // ---- Semantic colors (Tailwind *-500) ----
    readonly property color emerald: "#10b981"   // safe / on
    readonly property color amber:   "#f59e0b"   // warning
    readonly property color rose:    "#f43f5e"   // danger
    readonly property color cyan:    "#06b6d4"   // chiller / special
    readonly property color sky:     "#0ea5e9"   // info

    // ---- Derived (dark-aware) ----
    readonly property color bg:       dark ? slate900 : "#ffffff"
    readonly property color bgPanel:  dark ? slate800 : slate50
    readonly property color text:     dark ? "#ffffff" : slate900
    readonly property color textMuted: dark ? slate300 : slate500
    readonly property color border:   dark ? slate700 : slate200
    readonly property color glass:    dark ? Qt.rgba(0, 0, 0, 0.32) : Qt.rgba(1, 1, 1, 0.80)

    // ---- Typography ----
    readonly property string fontFamily: "Poppins"
    readonly property int    fontSizeSm: 12
    readonly property int    fontSizeMd: 14
    readonly property int    fontSizeLg: 18
    readonly property int    fontSizeXl: 24

    // ---- Geometry ----
    readonly property int radiusSm: 6
    readonly property int radiusMd: 12
    readonly property int radiusLg: 20
    readonly property int spacingSm: 8
    readonly property int spacingMd: 12
    readonly property int spacingLg: 16

    // ---- Animation ----
    readonly property int animFast: 120
    readonly property int animMed:  200
    readonly property int animSlow: 400
}
