import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.popups

Rectangle {
    id: brightModule
    Layout.preferredHeight: 22
    Layout.preferredWidth: brightRow.implicitWidth + 12
    color: mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
    radius: 6

    property real brightness: 0.5

    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    Process {
        id: brightReadProc
        command: ["sh", "-c", "brightnessctl -m | cut -d, -f4"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const val = parseInt(text.trim().replace("%", ""))
                if (!isNaN(val)) brightModule.brightness = Math.max(0, Math.min(1, val / 100))
            }
        }
    }

    Process { id: brightSetProc }

    function setBrightness(val) {
        brightness = Math.max(0.01, Math.min(1.0, val))
        brightSetProc.command = ["brightnessctl", "set", Math.round(brightness * 100) + "%"]
        brightSetProc.running = true
    }

    Timer {
        interval: 1000; repeat: true; running: true
        onTriggered: if (!brightReadProc.running) brightReadProc.running = true
    }

    RowLayout {
        id: brightRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: brightModule.brightness > 0.66 ? "󰃠" : brightModule.brightness > 0.33 ? "󰃟" : "󰃞"
            color: Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeIcon
        }
        Text {
            text: Math.round(brightModule.brightness * 100) + "%"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onWheel: (ev) => {
            const step = 0.05
            brightModule.setBrightness(brightModule.brightness + (ev.angleDelta.y > 0 ? step : -step))
        }
        onClicked: brightnessPopup.toggle()
    }

    BrightnessSlider { id: brightnessPopup; anchorItem: brightModule }
}
