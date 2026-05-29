import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp

Item {
    id: root

    property var pressures: [0,0,0,0,0,0, 0,0,0,0,0,0]

    readonly property color seatBlue: "#4a90e2"

    implicitHeight: 2 * 80 + 16
    implicitWidth: 6 * 96 + 5 * 12

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        Repeater {
            model: 2
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                property int rowIndex: index

                Repeater {
                    model: 6
                    Rectangle {
                        id: cell
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80
                        radius: Rsp.Theme.radiusSm
                        color: appState && appState.darkMode
                               ? Qt.rgba(0.12, 0.16, 0.23, 0.5)
                               : Qt.rgba(0.94, 0.95, 0.97, 1)

                        readonly property int seatNumber: parent.rowIndex * 6 + index + 1
                        readonly property real pressure: root.pressures.length > seatNumber - 1
                                                         ? root.pressures[seatNumber - 1]
                                                         : 0

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                text: cell.seatNumber
                                color: Rsp.Theme.text
                                font.family: Rsp.Theme.fontFamily
                                font.pixelSize: 24
                                font.weight: Font.Bold
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: cell.pressure.toFixed(2) + " Bar"
                                color: root.seatBlue
                                font.family: Rsp.Theme.fontFamily
                                font.pixelSize: 16
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }
            }
        }
    }
}
