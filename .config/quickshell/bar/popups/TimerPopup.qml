import "."
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

PopupWindow {
    id: tmr
    popupWidth: 300
    popupHeight: 272
    keepOpen: isRunning
    function open_() { visible = true }

    property bool isRunning: false
    property bool finished: false
    property int focusedField: 0   // 0=minutes 1=seconds
    property int minutes: 5
    property int seconds: 0
    property int totalSecs: 0
    property int remaining: 0

    function start() {
        const t = minutes * 60 + seconds
        if (t <= 0) return
        totalSecs = t
        remaining = t
        finished = false
        isRunning = true
    }

    function toggleRun() {
        if (finished) { reset(); return }
        if (isRunning) { isRunning = false }
        else if (remaining > 0) { isRunning = true }
        else { start() }
    }

    function reset() {
        isRunning = false
        finished = false
        remaining = 0
        totalSecs = 0
    }

    function adjustField(delta) {
        if (focusedField === 0) {
            minutes = Math.max(0, Math.min(99, minutes + delta))
        } else {
            seconds = Math.max(0, Math.min(59, seconds + delta))
        }
    }

    function fmt(s) {
        return ("0" + Math.floor(s / 60)).slice(-2) + ":" + ("0" + s % 60).slice(-2)
    }

    Timer {
        interval: 1000; running: tmr.isRunning; repeat: true
        onTriggered: {
            if (tmr.remaining > 1) {
                tmr.remaining -= 1
            } else {
                tmr.remaining = 0
                tmr.isRunning = false
                tmr.finished = true
            }
        }
    }

    Item {
        anchors.fill: parent
        focus: tmr.visible
        Keys.onPressed: function(ev) {
            if      (ev.key === Qt.Key_Escape) { tmr.close(); ev.accepted = true }
            else if (ev.key === Qt.Key_Space || ev.key === Qt.Key_Return) { tmr.toggleRun(); ev.accepted = true }
            else if (ev.key === Qt.Key_R)      { tmr.reset(); ev.accepted = true }
            else if ((ev.key === Qt.Key_Left || ev.key === Qt.Key_H) && !tmr.isRunning && !tmr.finished)  { tmr.focusedField = 0; ev.accepted = true }
            else if ((ev.key === Qt.Key_Right || ev.key === Qt.Key_L) && !tmr.isRunning && !tmr.finished) { tmr.focusedField = 1; ev.accepted = true }
            else if ((ev.key === Qt.Key_Up   || ev.key === Qt.Key_K) && !tmr.isRunning && !tmr.finished)  { tmr.adjustField(1); ev.accepted = true }
            else if ((ev.key === Qt.Key_Down  || ev.key === Qt.Key_J) && !tmr.isRunning && !tmr.finished) { tmr.adjustField(-1); ev.accepted = true }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Item { Layout.fillHeight: true }

        // Editing view: two fields with +/- buttons
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 4
            visible: !tmr.isRunning && !tmr.finished && tmr.remaining === 0

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 16

                // Minutes
                ColumnLayout {
                    spacing: 4
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 28; height: 24; radius: 6
                        color: plusM.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Text { anchors.centerIn: parent; text: "▲"; color: Theme.fgDim; font.pixelSize: 10 }
                        MouseArea { id: plusM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: tmr.minutes = Math.min(99, tmr.minutes + 1)
                            onWheel: tmr.minutes = Math.max(0, Math.min(99, tmr.minutes + (wheel.angleDelta.y > 0 ? 1 : -1)))
                        }
                    }
                    Rectangle {
                        width: 60; height: 52; radius: 8
                        color: tmr.focusedField === 0 ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.03)
                        border.width: tmr.focusedField === 0 ? 1 : 0
                        border.color: Theme.yellow
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Text {
                            anchors.centerIn: parent
                            text: ("0" + tmr.minutes).slice(-2)
                            color: tmr.focusedField === 0 ? Theme.fg : Theme.fgDim
                            font.family: Theme.fontFamily; font.pixelSize: 32; font.bold: true
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: tmr.focusedField = 0
                            onWheel: tmr.minutes = Math.max(0, Math.min(99, tmr.minutes + (wheel.angleDelta.y > 0 ? 1 : -1)))
                        }
                    }
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 28; height: 24; radius: 6
                        color: minusM.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Text { anchors.centerIn: parent; text: "▼"; color: Theme.fgDim; font.pixelSize: 10 }
                        MouseArea { id: minusM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: tmr.minutes = Math.max(0, tmr.minutes - 1)
                        }
                    }
                }

                Text {
                    text: ":"
                    color: Theme.fgDim; font.family: Theme.fontFamily; font.pixelSize: 32; font.bold: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.bottomMargin: 4
                }

                // Seconds
                ColumnLayout {
                    spacing: 4
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 28; height: 24; radius: 6
                        color: plusS.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Text { anchors.centerIn: parent; text: "▲"; color: Theme.fgDim; font.pixelSize: 10 }
                        MouseArea { id: plusS; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: tmr.seconds = Math.min(59, tmr.seconds + 1)
                            onWheel: tmr.seconds = Math.max(0, Math.min(59, tmr.seconds + (wheel.angleDelta.y > 0 ? 1 : -1)))
                        }
                    }
                    Rectangle {
                        width: 60; height: 52; radius: 8
                        color: tmr.focusedField === 1 ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.03)
                        border.width: tmr.focusedField === 1 ? 1 : 0
                        border.color: Theme.yellow
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Text {
                            anchors.centerIn: parent
                            text: ("0" + tmr.seconds).slice(-2)
                            color: tmr.focusedField === 1 ? Theme.fg : Theme.fgDim
                            font.family: Theme.fontFamily; font.pixelSize: 32; font.bold: true
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: tmr.focusedField = 1
                            onWheel: tmr.seconds = Math.max(0, Math.min(59, tmr.seconds + (wheel.angleDelta.y > 0 ? 1 : -1)))
                        }
                    }
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 28; height: 24; radius: 6
                        color: minusS.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Text { anchors.centerIn: parent; text: "▼"; color: Theme.fgDim; font.pixelSize: 10 }
                        MouseArea { id: minusS; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: tmr.seconds = Math.max(0, tmr.seconds - 1)
                        }
                    }
                }
            }
        }

        // Running/paused view
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8
            visible: tmr.isRunning || (tmr.remaining > 0 && !tmr.finished) || tmr.finished

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: tmr.finished ? "Done!" : fmt(remaining)
                color: tmr.finished ? Theme.green : Theme.fg
                font.family: Theme.fontFamily; font.pixelSize: 48; font.bold: true
                Behavior on color { ColorAnimation { duration: 300 } }
            }

            Rectangle {
                Layout.fillWidth: true; Layout.leftMargin: 0; Layout.rightMargin: 0
                height: 3; radius: 2
                color: Qt.rgba(1, 1, 1, 0.08)
                visible: !tmr.finished
                Rectangle {
                    width: parent.width * (1 - remaining / Math.max(1, totalSecs))
                    height: parent.height; radius: parent.radius
                    color: remaining < 30 ? Theme.red : Theme.blue
                    Behavior on color { ColorAnimation { duration: 400 } }
                }
            }
        }

        Item { Layout.preferredHeight: 14 }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            Rectangle {
                width: 34; height: 34; radius: 17
                color: resetBtn.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                visible: tmr.isRunning || tmr.finished || tmr.remaining > 0
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Text { anchors.centerIn: parent; text: "󰑎"; color: Theme.fgDim; font.family: Theme.fontFamily; font.pixelSize: 15 }
                MouseArea { id: resetBtn; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tmr.reset() }
            }

            Rectangle {
                width: 46; height: 46; radius: 23
                color: playBtn.containsMouse ? Theme.blue : Qt.rgba(1, 1, 1, 0.08)
                Behavior on color { ColorAnimation { duration: 150 } }
                Text {
                    anchors.centerIn: parent
                    text: tmr.finished ? "󰑎" : (tmr.isRunning ? "󰏤" : "󰐊")
                    color: playBtn.containsMouse ? Theme.bg : Theme.blue
                    font.family: Theme.fontFamily; font.pixelSize: 20
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                MouseArea { id: playBtn; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tmr.toggleRun() }
            }
        }

        Item { Layout.fillHeight: true }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: tmr.isRunning || tmr.remaining > 0
                  ? "Space pause · R reset · Esc close"
                  : "← → field · ↑ ↓ adjust · Space start · Esc close"
            color: Theme.fgVeryDim; font.family: Theme.fontFamily; font.pixelSize: 9
        }

        Item { Layout.preferredHeight: 4 }
    }
}
