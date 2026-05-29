import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp

Rectangle {
    id: root

    property string title: ""
    property bool hoverable: false
    property bool isLoading: false
    default property alias body: contentColumn.data
    property Component headerAction: null

    radius: Rsp.Theme.radiusLg
    color: appState && appState.darkMode
           ? Qt.rgba(1, 1, 1, 0.05)
           : Qt.rgba(1, 1, 1, 0.80)
    border.width: 1
    border.color: appState && appState.darkMode
                  ? Qt.rgba(1, 1, 1, 0.10)
                  : Qt.rgba(0.88, 0.91, 0.94, 1)

    implicitHeight: layoutColumn.implicitHeight
    implicitWidth: 400

    transform: Translate { id: lift; y: hoverable && hoverArea.containsMouse ? -4 : 0
        Behavior on y { NumberAnimation { duration: Rsp.Theme.animMed; easing.type: Easing.OutCubic } }
    }
    scale: hoverable && hoverArea.containsMouse ? 1.01 : 1.0
    Behavior on scale { NumberAnimation { duration: Rsp.Theme.animMed; easing.type: Easing.OutCubic } }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: hoverable
        acceptedButtons: Qt.NoButton
    }

    ColumnLayout {
        id: layoutColumn
        anchors.fill: parent
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 64 : 0
            visible: root.title !== ""

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Rsp.Theme.border
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 24

                Text {
                    text: root.title
                    color: Rsp.Theme.text
                    font.family: Rsp.Theme.fontFamily
                    font.pixelSize: Rsp.Theme.fontSizeXl
                    font.weight: Font.Bold
                    Layout.fillWidth: true
                }

                Loader {
                    sourceComponent: root.headerAction
                    visible: root.headerAction !== null
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.isLoading ? loadingSkeleton.height : contentColumn.implicitHeight + 48

            ColumnLayout {
                id: contentColumn
                anchors.fill: parent
                anchors.margins: 24
                visible: !root.isLoading
            }

            ColumnLayout {
                id: loadingSkeleton
                visible: root.isLoading
                anchors.fill: parent
                anchors.margins: 24
                spacing: 12

                Repeater {
                    model: 3
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        radius: 4
                        color: Rsp.Theme.border
                        SequentialAnimation on opacity {
                            running: root.isLoading
                            loops: Animation.Infinite
                            NumberAnimation { from: 0.4; to: 0.8; duration: 800 }
                            NumberAnimation { from: 0.8; to: 0.4; duration: 800 }
                        }
                    }
                }
            }
        }
    }
}
