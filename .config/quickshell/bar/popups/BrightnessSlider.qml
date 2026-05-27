import "."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.services

PanelWindow {
    id: root

    visible: false
    color: "transparent"

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    property real brightness: 0.5

    function showOSD() {
        visible = true
        PopupManager.open(root)
        readDelay.restart()
        autoHide.restart()
    }

    Timer {
        id: readDelay
        interval: 80
        onTriggered: brightReadProc.running = true
    }

    Timer {
        id: autoHide
        interval: 2000
        onTriggered: root.visible = false
    }

    GlobalShortcut {
        name: "showBrightnessOSD"
        onPressed: root.showOSD()
    }

    Process {
        id: brightReadProc
        command: ["sh", "-c", "brightnessctl -m | cut -d, -f4"]
        stdout: StdioCollector {
            onStreamFinished: {
                const val = parseInt(text.trim().replace("%", ""))
                if (!isNaN(val)) root.brightness = Math.max(0, Math.min(1, val / 100))
            }
        }
    }

    Process { id: brightSetProc }

    function setBrightness(val) {
        brightness = Math.max(0.01, Math.min(1.0, val))
        brightSetProc.command = ["brightnessctl", "set", Math.round(brightness * 100) + "%"]
        brightSetProc.running = true
        autoHide.restart()
    }

    Rectangle {
        id: card
        width: 280
        height: sliderRow.implicitHeight + 24
        x: root.width - width - 8
        y: Theme.barHeight + 8

        color: Theme.popupBg
        radius: 12
        border.width: 1
        border.color: "#f38c6f"

        opacity: root.visible ? 1 : 0
        scale: root.visible ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }

        RowLayout {
            id: sliderRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            Text {
                text: root.brightness > 0.66 ? "󰃠" : root.brightness > 0.33 ? "󰃟" : "󰃞"
                color: Theme.fgDim
                font.family: Theme.fontFamily; font.pixelSize: 16
                width: 18; horizontalAlignment: Text.AlignHCenter
                Behavior on color { ColorAnimation { duration: 100 } }
            }

            Item {
                id: brightSlider; Layout.fillWidth: true; height: 20

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width; height: 4; radius: 2
                    color: Qt.rgba(1, 1, 1, 0.18)

                    Rectangle {
                        width: parent.width * root.brightness
                        height: parent.height; radius: parent.radius
                        color: Theme.yellow
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 12; height: 12; radius: 6; color: Theme.fg
                    x: Math.max(0, Math.min(parent.width - 12, root.brightness * parent.width - 6))
                }

                MouseArea {
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.SizeHorCursor
                    onClicked: root.setBrightness(mouseX / brightSlider.width)
                    onPositionChanged: if (pressed) root.setBrightness(mouseX / brightSlider.width)
                }
            }

            Text {
                text: Math.round(root.brightness * 100) + "%"
                color: Theme.fgDim
                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall
                width: 38; horizontalAlignment: Text.AlignRight
            }
        }
    }
}
