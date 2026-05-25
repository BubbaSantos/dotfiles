import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.services
import qs.popups

Rectangle {
    id: root
    Layout.preferredHeight: 22
    Layout.preferredWidth: row.implicitWidth + 12
    color: mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
    radius: 6

    // Display modes: 0 = icon only, 1 = icon + signal%, 2 = icon + ssid
    property int mode: 0

    readonly property bool connected: WifiService.connected
    readonly property int signal_: WifiService.signal_
    readonly property bool powered: WifiService.powered
    readonly property string ssid: WifiService.ssid

    function icon() {
        if (!powered) return "✈"
        if (!connected) return "󰖪"
        if (signal_ >= 80) return "󰤨"
        if (signal_ >= 60) return "󰤥"
        if (signal_ >= 40) return "󰤢"
        if (signal_ >= 20) return "󰤟"
        return "󰤯"
    }

    function iconColor() {
        if (!powered) return Theme.red
        if (!connected || signal_ < 30) return Theme.red
        return Theme.fg
    }

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on Layout.preferredWidth { NumberAnimation { duration: Theme.animFast } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 5

        Text {
            text: root.icon()
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeIcon
            color: root.iconColor()
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        Text {
            visible: root.mode === 1 && root.connected
            text: root.signal_ + "%"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        Text {
            visible: root.mode === 2 && root.connected
            text: root.ssid
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            elide: Text.ElideRight
            Layout.maximumWidth: 140
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: function(ev) {
            if (ev.button === Qt.LeftButton) {
                root.mode = (root.mode + 1) % 3
            } else if (ev.button === Qt.RightButton) {
                wifiPicker.toggle()
            }
        }
    }

    WifiPicker {
        id: wifiPicker
        anchorItem: root
    }

    GlobalShortcut {
        name: "toggleWifiPicker"
        description: "Toggle the Wi-Fi picker"
        onPressed: wifiPicker.toggle()
    }
}
