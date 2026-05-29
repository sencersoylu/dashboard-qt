import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Rsp

Rectangle {
    id: root

    // The StackView push call passes the URL of the page to replace this
    // splash with once the timer + fade-out finishes.
    property string nextPage: "pages/Dashboard.qml"

    signal finished()

    // ----- Background (matches Dashboard gradient so the handover is seamless)
    gradient: Gradient {
        orientation: Gradient.Vertical
        GradientStop { position: 0.0; color: "#0f172a" }
        GradientStop { position: 0.5; color: "#0a0e1c" }
        GradientStop { position: 1.0; color: "#020617" }
    }

    // Subtle orbs to echo the Dashboard backdrop
    Rectangle {
        x: -300; y: -100
        width: 700; height: 700
        radius: 350
        color: Qt.rgba(0.05, 0.45, 0.85, 0.06)
    }
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -300
        width: 800; height: 800
        radius: 400
        color: Qt.rgba(0.05, 0.7, 0.5, 0.04)
    }

    // ----- Centered logo + loading dots
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 32

        Image {
            id: logo
            Layout.alignment: Qt.AlignHCenter
            // Splash background is the dark gradient regardless of theme,
            // so always use the white logo here for legibility.
            source: "../../assets/images/hipertech-logo.svg"
            sourceSize.width: 480
            fillMode: Image.PreserveAspectFit
            opacity: 0
            scale: 0.96

            ParallelAnimation {
                running: true
                NumberAnimation { target: logo; property: "opacity"; from: 0; to: 1.0; duration: 700; easing.type: Easing.OutCubic }
                NumberAnimation { target: logo; property: "scale";   from: 0.96; to: 1.0; duration: 900; easing.type: Easing.OutCubic }
            }
        }

        // Three-dot pulse loader
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            Repeater {
                model: 3
                delegate: Rectangle {
                    implicitWidth: 10
                    implicitHeight: 10
                    radius: 5
                    color: Rsp.Theme.cyan
                    opacity: 0.25

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: true
                        PauseAnimation { duration: index * 180 }
                        NumberAnimation { from: 0.25; to: 1.0; duration: 420; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 1.0; to: 0.25; duration: 420; easing.type: Easing.InOutQuad }
                        PauseAnimation { duration: (2 - index) * 180 }
                    }
                }
            }
        }
    }

    // ----- 5-second hold, then fade out and signal finished
    Timer {
        interval: 5000
        running: true
        repeat: false
        onTriggered: fadeOut.start()
    }

    NumberAnimation {
        id: fadeOut
        target: root
        property: "opacity"
        from: 1.0; to: 0.0
        duration: 400
        easing.type: Easing.InCubic
        onFinished: {
            root.finished()
            // If a StackView owns us, replace ourselves with the configured
            // next page so the parent doesn't need to wire up a signal.
            if (root.StackView.view) {
                root.StackView.view.replace(root.nextPage)
            }
        }
    }
}
