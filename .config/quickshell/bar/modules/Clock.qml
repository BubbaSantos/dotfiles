import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.popups

Rectangle {
    id: root
    Layout.preferredHeight: 22
    Layout.preferredWidth: clockText.implicitWidth + 16
    color: mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
    radius: 6

    // 12hr stays 12hr when paired with date; 24hr is its own choice
    readonly property var formats: [
        "hh:mm:ss AP",                    // 03:45:12 PM
        "ddd dd · hh:mm:ss AP",           // Mon 25 · 03:45:12 PM
        "ddd dd MMM · hh:mm:ss AP",       // Mon 25 May · 03:45:12 PM
        "HH:mm:ss",                       // 15:45:12
        "hh:mm AP"                        // 03:45 PM
    ]
    property int modeIndex: 0

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on Layout.preferredWidth { NumberAnimation { duration: Theme.animFast } }

    Text {
        id: clockText
        anchors.centerIn: parent
        text: Qt.formatDateTime(clockTimer.now, root.formats[root.modeIndex])
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
    }

    Timer {
        id: clockTimer
        property var now: new Date()
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: now = new Date()
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: function(ev) {
            if (ev.button === Qt.LeftButton) {
                root.modeIndex = (root.modeIndex + 1) % root.formats.length
            } else if (ev.button === Qt.RightButton) {
                calendarPopup.toggle()
            }
        }
    }

    Calendar {
        id: calendarPopup
        anchorItem: root
    }
}
