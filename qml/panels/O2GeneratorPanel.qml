import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import ".." as Rsp
import "../ui" as Ui

// Cabinet-specific O₂ generator control. Rendered as its own card beneath the
// Auxiliary Decompression panel, and only on chambers whose window config sets
// `o2Generator: true`. Window.window resolves to the owning ApplicationWindow
// (Main.qml), which carries the per-window `cfg`.
Ui.Card {
    id: root
    title: "O₂ Generator"
    implicitWidth: 380

    readonly property bool o2GenEnabled:
        Window.window && Window.window.cfg && Window.window.cfg.o2Generator === true

    // Hide (and drop from the layout) entirely on cabinets without the unit.
    visible: o2GenEnabled

    // True read-back design: command the M0077 coil only. The pill position
    // follows appState.o2GeneratorOn, which PlcClient refreshes from data[31],
    // so we deliberately do NOT optimistically echo the new state here.
    function toggleO2Gen() {
        const newVal = (appState && appState.o2GeneratorOn) ? 0 : 1
        plcClient.writeBit("M0077", newVal)
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 0

        Item { Layout.fillHeight: true; Layout.minimumHeight: 8 }

        Ui.ToggleSwitch {
            Layout.fillWidth: true
            states: [
                { "label": "Off", "color": Rsp.Theme.slate500 },
                { "label": "On",  "color": Rsp.Theme.emerald }
            ]
            value: (appState && appState.o2GeneratorOn) ? 1 : 0
            onValueUpdated: function(newIndex) { root.toggleO2Gen() }
        }

        Item { Layout.fillHeight: true; Layout.minimumHeight: 8 }
    }
}
