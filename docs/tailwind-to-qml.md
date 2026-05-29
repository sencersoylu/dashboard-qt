# Tailwind → QML Cheat-Sheet

Quick reference for porting React/Tailwind UI to QML. The Theme singleton at
`qml/Theme.qml` centralizes colors, radii, fonts, and animation timings.

## Backgrounds and text

| Tailwind | QML |
|---|---|
| `bg-white dark:bg-slate-900` | `color: Theme.bg` |
| `bg-slate-100 dark:bg-slate-800` | `color: Theme.bgPanel` |
| `text-slate-900 dark:text-white` | `color: Theme.text` |
| `text-slate-500 dark:text-slate-300` | `color: Theme.textMuted` |
| `border border-slate-200 dark:border-slate-700` | `border.width: 1; border.color: Theme.border` |
| `bg-white/80` (glass) | `color: Qt.rgba(1, 1, 1, 0.8)` or `Theme.glass` |

## Sizing

| Tailwind | QML |
|---|---|
| `h-10` (40 px) | `height: 40` |
| `h-12` (48 px) | `height: 48` |
| `h-14` (56 px) | `height: 56` |
| `w-full` | `Layout.fillWidth: true` (inside a Layout) or `anchors.left/right` |
| `px-6` | `leftPadding: 24; rightPadding: 24` |
| `py-4` | `topPadding: 16; bottomPadding: 16` |

## Corner radius

| Tailwind | QML |
|---|---|
| `rounded-lg` | `radius: Theme.radiusSm` (6) |
| `rounded-2xl` | `radius: Theme.radiusLg` (20) |
| `rounded-full` | `radius: height / 2` |

## Spacing inside layouts

| Tailwind | QML |
|---|---|
| `gap-2` | `spacing: 8` |
| `gap-3` | `spacing: Theme.spacingMd` (12) |
| `gap-4` | `spacing: Theme.spacingLg` (16) |
| `flex` (column) | `ColumnLayout {}` |
| `flex` (row) | `RowLayout {}` |
| `grid grid-cols-N` | `GridLayout { columns: N }` |

## Shadows

DropShadow from Qt5Compat:
```qml
import Qt5Compat.GraphicalEffects 1.15
DropShadow {
    anchors.fill: target
    source: target
    horizontalOffset: 0
    verticalOffset: 6
    radius: 12
    samples: 25
    color: Qt.rgba(0, 0, 0, 0.2)
}
```
Maps to `shadow-lg`. Use `MultiEffect` if on Qt 6.5+.

## Animations and transitions

| Tailwind | QML |
|---|---|
| `transition-all` | `Behavior on <property> { NumberAnimation { duration: Theme.animMed } }` |
| `transition-colors duration-200` | `Behavior on color { ColorAnimation { duration: 200 } }` |
| `hover:scale-[1.02]` | `MouseArea.containsMouse` triggers a `State` with `scale: 1.02` |
| `active:scale-[0.98]` | `MouseArea.pressed` triggers a `State` with `scale: 0.98` |
| `disabled:opacity-50` | Bind `opacity: enabled ? 1.0 : 0.5` |
| `animate-spin` | `RotationAnimator on rotation { from: 0; to: 360; duration: 1000; loops: -1 }` |
| `animate-fade-in` | Initial `opacity: 0` + `Behavior on opacity` + set to 1 in onCompleted |

## Variants

For variant-driven colors (Button, Slider) define them in the component:

```qml
readonly property var variantColors: ({
    "default":  { bg: Theme.slate700, fg: "#ffffff", hover: Theme.slate500 },
    "success":  { bg: Theme.emerald,  fg: "#ffffff", hover: "#0e9f6e" },
    "warning":  { bg: Theme.amber,    fg: "#ffffff", hover: "#d97706" },
    "danger":   { bg: Theme.rose,     fg: "#ffffff", hover: "#dc2626" },
    "info":     { bg: Theme.sky,      fg: "#ffffff", hover: "#0284c7" },
    "muted":    { bg: Theme.slate500, fg: "#ffffff", hover: Theme.slate700 }
})

readonly property var current: variantColors[variant] || variantColors["default"]
```

## Focus rings

Tailwind `focus:ring-2 focus:ring-blue-500` →
```qml
Rectangle {
    anchors.fill: parent
    anchors.margins: -2
    color: "transparent"
    border.width: 2
    border.color: Theme.sky
    visible: parent.activeFocus
    radius: parent.radius + 2
}
```

## Component conventions in this codebase

- Every component reads `Theme.*` — never hardcode hex colors except inside variant maps.
- Every component is composable via the `default property` for slot-style children.
- Pass `isDark` is NOT used — Theme is the single source of truth and re-evaluates on `appState.darkMode` change.
- Components fire callbacks via Signals, not direct property mutation on app state.
