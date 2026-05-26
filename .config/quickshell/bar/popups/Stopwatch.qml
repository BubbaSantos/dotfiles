import "."
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

PopupWindow {
    id: sw
    popupWidth: 300
    popupHeight: 290
    keepOpen: isRunning
    function open_() { visible = true }

    property bool isRunning: false
    property int elapsed: 0      // milliseconds
    property var laps: []

    function fmt(ms) {
        const total = Math.floor(ms / 10)
        const cs  = total % 100
        const s   = Math.floor(total / 100) % 60
        const m   = Math.floor(total / 6000) % 60
        const h   = Math.floor(total / 360000)
        const base = (h > 0 ? h + ":" : "") +
                     (h > 0 ? ("0" + m).slice(-2) : m) + ":" +
                     ("0" + s).slice(-2) + "." +
                     ("0" + cs).slice(-2)
        return base
    }

    function lap() {
        if (!isRunning && elapsed === 0) return
        const newLaps = laps.slice()
        newLaps.unshift(elapsed)
        laps = newLaps
    }

    function reset() {
        isRunning = false
        elapsed = 0
        laps = []
    }

    Timer {
        interval: 10; running: sw.isRunning; repeat: true
        onTriggered: sw.elapsed += 10
    }

    Item {
        anchors.fill: parent
        focus: sw.visible
        Keys.onPressed: function(ev) {
            if      (ev.key === Qt.Key_Escape) { sw.close(); ev.accepted = true }
            else if (ev.key === Qt.Key_Space)  { sw.isRunning = !sw.isRunning; ev.accepted = true }
            else if (ev.key === Qt.Key_L)      { sw.lap(); ev.accepted = true }
            else if (ev.key === Qt.Key_R)      { sw.reset(); ev.accepted = true }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Item { Layout.fillHeight: true }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: fmt(elapsed)
            color: Theme.fg
            font.family: Theme.fontFamily; font.pixelSize: 40; font.bold: true
        }

        Item { Layout.preferredHeight: 12 }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            Rectangle {
                width: 34; height: 34; radius: 17
                color: resetBtn.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Text { anchors.centerIn: parent; text: "󰑎"; color: Theme.fgDim; font.family: Theme.fontFamily; font.pixelSize: 15 }
                MouseArea { id: resetBtn; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sw.reset() }
            }

            Rectangle {
                width: 46; height: 46; radius: 23
                color: playBtn.containsMouse ? Theme.yellow : Qt.rgba(1, 1, 1, 0.08)
                Behavior on color { ColorAnimation { duration: 150 } }
                Text {
                    anchors.centerIn: parent
                    text: sw.isRunning ? "󰏤" : "󰐊"
                    color: playBtn.containsMouse ? Theme.bg : Theme.yellow
                    font.family: Theme.fontFamily; font.pixelSize: 20
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                MouseArea { id: playBtn; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sw.isRunning = !sw.isRunning }
            }

            Rectangle {
                width: 34; height: 34; radius: 17
                color: lapBtn.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                opacity: (sw.isRunning || sw.elapsed > 0) ? 1 : 0.3
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Text { anchors.centerIn: parent; text: "󱎫"; color: Theme.fgDim; font.family: Theme.fontFamily; font.pixelSize: 13 }
                MouseArea { id: lapBtn; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sw.lap() }
            }
        }

        Item { Layout.preferredHeight: 10 }

        // Lap list (last 4, newest first)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            visible: laps.length > 0

            Repeater {
                model: Math.min(laps.length, 4)
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "#" + (laps.length - index)
                        color: Theme.fgVeryDim; font.family: Theme.fontFamily; font.pixelSize: 10
                        Layout.preferredWidth: 24
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: sw.fmt(laps[index])
                        color: index === 0 ? Theme.yellow : Theme.fgDim
                        font.family: Theme.fontFamily; font.pixelSize: 10; font.bold: index === 0
                    }
                }
            }

            Item { Layout.preferredHeight: 2 }
        }

        Item { Layout.fillHeight: true }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Space start/stop · L lap · R reset · Esc close"
            color: Theme.fgVeryDim; font.family: Theme.fontFamily; font.pixelSize: 9
        }

        Item { Layout.preferredHeight: 4 }
    }
}
