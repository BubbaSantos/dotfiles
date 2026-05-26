import "."
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

PopupWindow {
    id: pom
    popupWidth: 300
    popupHeight: 268
    keepOpen: isRunning
    function open_() { visible = true }

    property bool isRunning: false
    property int phase: 0        // 0=Focus 1=Short Break 2=Long Break
    property int cyclesDone: 0
    property int totalSecs: 25 * 60
    property int remaining: 25 * 60

    readonly property var phaseDurs:  [25 * 60, 5 * 60, 15 * 60]
    readonly property var phaseNames: ["Focus", "Short Break", "Long Break"]
    readonly property color phaseColor: phase === 0 ? Theme.red : (phase === 1 ? Theme.green : Theme.aqua)

    function setPhase(p) {
        isRunning = false
        phase = p
        totalSecs = phaseDurs[p]
        remaining = phaseDurs[p]
    }

    function skipPhase() {
        if (phase === 0) {
            cyclesDone += 1
            setPhase(cyclesDone % 4 === 0 ? 2 : 1)
        } else {
            setPhase(0)
        }
    }

    function resetAll() {
        cyclesDone = 0
        setPhase(0)
    }

    function fmt(s) {
        return ("0" + Math.floor(s / 60)).slice(-2) + ":" + ("0" + s % 60).slice(-2)
    }

    Timer {
        interval: 1000; running: pom.isRunning; repeat: true
        onTriggered: {
            if (pom.remaining > 0) pom.remaining -= 1
            else { pom.isRunning = false; pom.skipPhase() }
        }
    }

    Item {
        anchors.fill: parent
        focus: pom.visible
        Keys.onPressed: function(ev) {
            if      (ev.key === Qt.Key_Escape) { pom.close(); ev.accepted = true }
            else if (ev.key === Qt.Key_Space)  { pom.isRunning = !pom.isRunning; ev.accepted = true }
            else if (ev.key === Qt.Key_N)      { pom.skipPhase(); ev.accepted = true }
            else if (ev.key === Qt.Key_R)      { pom.resetAll(); ev.accepted = true }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Item { Layout.fillHeight: true }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: phaseNames[phase]
            color: phaseColor
            font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true
            Behavior on color { ColorAnimation { duration: 400 } }
        }

        Item { Layout.preferredHeight: 10 }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8
            Repeater {
                model: 4
                Rectangle {
                    width: 7; height: 7; radius: 4
                    color: index < (cyclesDone % 4) ? Theme.yellow : Qt.rgba(1, 1, 1, 0.15)
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }

        Item { Layout.preferredHeight: 12 }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: fmt(remaining)
            color: Theme.fg
            font.family: Theme.fontFamily; font.pixelSize: 48; font.bold: true
        }

        Item { Layout.preferredHeight: 12 }

        Rectangle {
            Layout.fillWidth: true
            height: 3; radius: 2
            color: Qt.rgba(1, 1, 1, 0.08)
            Rectangle {
                width: parent.width * (1 - remaining / Math.max(1, totalSecs))
                height: parent.height; radius: parent.radius
                color: phaseColor
                Behavior on color { ColorAnimation { duration: 400 } }
            }
        }

        Item { Layout.preferredHeight: 14 }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            Rectangle {
                width: 34; height: 34; radius: 17
                color: resetBtn.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Text { anchors.centerIn: parent; text: "󰑎"; color: Theme.fgDim; font.family: Theme.fontFamily; font.pixelSize: 15 }
                MouseArea { id: resetBtn; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pom.resetAll() }
            }

            Rectangle {
                width: 46; height: 46; radius: 23
                color: playBtn.containsMouse ? phaseColor : Qt.rgba(1, 1, 1, 0.08)
                Behavior on color { ColorAnimation { duration: 150 } }
                Text {
                    anchors.centerIn: parent
                    text: pom.isRunning ? "󰏤" : "󰐊"
                    color: playBtn.containsMouse ? Theme.bg : phaseColor
                    font.family: Theme.fontFamily; font.pixelSize: 20
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                MouseArea { id: playBtn; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pom.isRunning = !pom.isRunning }
            }

            Rectangle {
                width: 34; height: 34; radius: 17
                color: skipBtn.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Text { anchors.centerIn: parent; text: "󰒭"; color: Theme.fgDim; font.family: Theme.fontFamily; font.pixelSize: 15 }
                MouseArea { id: skipBtn; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pom.skipPhase() }
            }
        }

        Item { Layout.fillHeight: true }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Space toggle · N skip · R reset · Esc close"
            color: Theme.fgVeryDim; font.family: Theme.fontFamily; font.pixelSize: 9
        }

        Item { Layout.preferredHeight: 4 }
    }
}
