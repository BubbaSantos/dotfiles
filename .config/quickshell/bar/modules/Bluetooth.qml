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

    // 0 = icon, 1 = icon + count, 2 = icon + first connected device name
    property int mode: 0

    readonly property bool powered: BluetoothService.powered
    readonly property var connected: BluetoothService.connectedDevices
    readonly property int connectedCount: connected.length
    readonly property string firstDeviceName: connectedCount > 0 ? (connected[0].name || "Unknown") : ""

    function icon() {
        if (!powered) return "󰂲"
        if (connectedCount > 0) return "󰂱"
        return "󰂯"
    }

    function iconColor() {
        if (!powered) return Theme.fgDim
        if (connectedCount > 0) return Theme.blue
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
            visible: root.mode === 1 && root.connectedCount > 0
            text: root.connectedCount
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        Text {
            visible: root.mode === 2 && root.connectedCount > 0
            text: root.firstDeviceName
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
                btPicker.toggle()
            }
        }
    }

    BluetoothPicker {
        id: btPicker
        anchorItem: root
    }

    GlobalShortcut {
        name: "toggleBluetoothPicker"
        description: "Toggle the Bluetooth picker"
        onPressed: btPicker.toggle()
    }
}
