import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs

Rectangle {
    Layout.preferredHeight: 22
    Layout.preferredWidth: paRow.implicitWidth + 12
    color: mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
    radius: 6

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real vol: sink ? sink.audio.volume : 0
    readonly property bool muted: sink ? sink.audio.muted : false

    PwObjectTracker { objects: sink ? [sink] : [] }

    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    RowLayout {
        id: paRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: Math.round(parent.parent.vol * 100) + "%"
            color: parent.parent.muted ? Theme.red : Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
        Text {
            text: parent.parent.muted ? "󰝟" : ""
            color: parent.parent.muted ? Theme.red : Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeIcon
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onWheel: (ev) => {
            if (!parent.sink) return
            const step = 0.02
            const newVol = Math.max(0, Math.min(1.5,
                parent.sink.audio.volume + (ev.angleDelta.y > 0 ? step : -step)))
            parent.sink.audio.volume = newVol
        }
        onClicked: (ev) => {
            if (!parent.sink) return
            if (ev.button === Qt.RightButton) {
                wiremixProc.running = true
            } else {
                parent.sink.audio.muted = !parent.sink.audio.muted
            }
        }
    }

    Process {
        id: wiremixProc
        command: ["alacritty", "--class=Wiremix", "-e", "wiremix"]
    }
}
