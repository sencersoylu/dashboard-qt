import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp

Item {
    id: root

    implicitWidth: 720
    implicitHeight: 480

    // ===== Extracted verbatim from React SEAT_POSITIONS =====
    // Source: renderer/components/dashboard/ChamberSeatOverlay.tsx
    // ListElement values must be literals; '%' stripped, numbers preserved.
    ListModel {
        id: seats
        // Main Chamber - Back row (top row in image, right to left)
        ListElement { seatId: "1";  label: "1";  topPct: 23; leftPct: 60;   widthPct: 6; heightPct: 9 }
        ListElement { seatId: "2";  label: "2";  topPct: 26; leftPct: 51;   widthPct: 6; heightPct: 9 }
        ListElement { seatId: "3";  label: "3";  topPct: 29; leftPct: 42;   widthPct: 6; heightPct: 9 }
        ListElement { seatId: "4";  label: "4";  topPct: 32; leftPct: 33;   widthPct: 6; heightPct: 9 }
        ListElement { seatId: "5";  label: "5";  topPct: 35; leftPct: 24.5; widthPct: 6; heightPct: 9 }
        ListElement { seatId: "6";  label: "6";  topPct: 38; leftPct: 16;   widthPct: 6; heightPct: 9 }

        // Main Chamber - Front row (bottom row in image, right to left)
        ListElement { seatId: "7";  label: "7";  topPct: 52; leftPct: 58;   widthPct: 6; heightPct: 9 }
        ListElement { seatId: "8";  label: "8";  topPct: 55; leftPct: 49;   widthPct: 6; heightPct: 9 }
        ListElement { seatId: "9";  label: "9";  topPct: 58; leftPct: 40;   widthPct: 6; heightPct: 9 }
        ListElement { seatId: "10"; label: "10"; topPct: 61; leftPct: 31;   widthPct: 6; heightPct: 9 }
        ListElement { seatId: "11"; label: "11"; topPct: 64; leftPct: 22.5; widthPct: 6; heightPct: 9 }
        ListElement { seatId: "12"; label: "12"; topPct: 67; leftPct: 14;   widthPct: 6; heightPct: 9 }

        // Ante Chamber (left section)
        ListElement { seatId: "A1"; label: "A1"; topPct: 20; leftPct: 76;   widthPct: 6; heightPct: 9 }
        ListElement { seatId: "A2"; label: "A2"; topPct: 46; leftPct: 76;   widthPct: 6; heightPct: 9 }
    }

    Image {
        id: chamberImage
        anchors.fill: parent
        source: "../../assets/images/chamber-3d.png"
        fillMode: Image.PreserveAspectFit
        sourceSize.width: 1440
    }

    Repeater {
        model: seats
        delegate: Item {
            x: root.width  * leftPct  / 100
            y: root.height * topPct   / 100
            width:  root.width  * widthPct  / 100
            height: root.height * heightPct / 100

            // Active alarm marker
            Rectangle {
                id: alarmDot
                anchors.fill: parent
                radius: width / 2
                color: Rsp.Theme.rose
                // Loose equality so "1" == 1 still works if seatNumber arrives as int
                opacity: (typeof appState !== "undefined" && appState && appState.activeSeatAlarm
                         && String(appState.activeSeatAlarm.seatNumber) === seatId)
                         ? 0.7 : 0
                Behavior on opacity { NumberAnimation { duration: Rsp.Theme.animMed } }

                SequentialAnimation on scale {
                    running: alarmDot.opacity > 0
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0;  to: 1.15; duration: 500 }
                    NumberAnimation { from: 1.15; to: 1.0;  duration: 500 }
                }

                Text {
                    anchors.centerIn: parent
                    text: label
                    color: "#ffffff"
                    font.family: Rsp.Theme.fontFamily
                    font.pixelSize: Rsp.Theme.fontSizeLg
                    font.weight: Font.Bold
                    visible: alarmDot.opacity > 0
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                // Click is local-only in React (no PLC write). No-op for now.
            }
        }
    }
}
