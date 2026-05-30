import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp

Popup {
    id: root

    property string title: ""
    property string size: "md"
    property bool showCloseButton: true
    property bool closeOnBackdropClick: true
    property bool closeOnEscape: true

    default property alias content: contentColumn.data

    readonly property var widths: ({ sm: 400, md: 560, lg: 720, xl: 960 })
    readonly property int targetWidth: widths[size] || widths.md

    modal: true
    focus: true
    closePolicy: (closeOnBackdropClick ? Popup.CloseOnPressOutside : Popup.NoAutoClose) |
                 (closeOnEscape ? Popup.CloseOnEscape : Popup.NoAutoClose)

    anchors.centerIn: Overlay.overlay
    width: Math.min(targetWidth, parent ? parent.width - 48 : targetWidth)
    height: bodyColumn.implicitHeight + 48
    padding: 0

    background: Rectangle {
        radius: Rsp.Theme.radiusLg
        color: Rsp.Theme.bgPanel
        border.color: Rsp.Theme.border
        border.width: 1
    }

    Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.6)
    }

    ColumnLayout {
        id: bodyColumn
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            visible: root.title !== "" || root.showCloseButton

            Text {
                text: root.title
                color: Rsp.Theme.text
                font.family: Rsp.Theme.fontFamily
                font.pixelSize: Rsp.Theme.fontSizeLg
                font.weight: Font.Bold
                Layout.fillWidth: true
            }

            Item {
                visible: root.showCloseButton
                implicitWidth: 36; implicitHeight: 36

                Rectangle {
                    id: closeBg
                    anchors.fill: parent
                    radius: width / 2
                    color: closeArea.containsMouse
                           ? Qt.rgba(1, 1, 1, 0.15)
                           : Qt.rgba(1, 1, 1, 0.08)
                    border.color: Qt.rgba(1, 1, 1, 0.25)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: Rsp.Theme.animFast } }
                }

                Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: "#ffffff"
                    font.family: Rsp.Theme.fontFamily
                    font.pixelSize: 22
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.close()
                }
            }
        }

        ColumnLayout {
            id: contentColumn
            Layout.fillWidth: true
            spacing: 12
        }
    }
}
