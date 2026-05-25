import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import qs
import qs.popups

Rectangle {
    id: root
    Layout.preferredHeight: 22
    Layout.preferredWidth: batRow.implicitWidth + 12
    color: mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
    radius: 6

    property string mode: "percentage"

    readonly property var display: UPower.displayDevice
    readonly property bool ready: display && display.ready
    readonly property real pct: ready ? display.percentage * 100 : 0
    readonly property bool charging: ready && display.state === UPowerDeviceState.Charging
    readonly property bool pluggedIn: ready && (
        display.state === UPowerDeviceState.Charging
        || display.state === UPowerDeviceState.FullyCharged
        || display.state === UPowerDeviceState.PendingCharge
    )
    readonly property bool isFull: ready && display.state === UPowerDeviceState.FullyCharged
    readonly property bool isLow: pct <= 20 && !pluggedIn
    readonly property bool isCritical: pct <= 10 && !pluggedIn
    readonly property int timeToEmpty: ready ? display.timeToEmpty : 0
    readonly property int timeToFull: ready ? display.timeToFull : 0

    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    function batteryIcon(p, c, full) {
        if (full) return "󰂅"
        if (c) return "󰂄"
        if (p >= 90) return "󰁹"
        if (p >= 75) return "󰂀"
        if (p >= 50) return "󰁾"
        if (p >= 25) return "󰁼"
        if (p >= 10) return "󰁺"
        return "󰂎"
    }

    function formatSeconds(s) {
        if (!s || s <= 0) return "—"
        const h = Math.floor(s / 3600)
        const m = Math.floor((s % 3600) / 60)
        if (h > 0) return `${h}h ${m}m`
        return `${m}m`
    }

    function statusColor() {
        if (root.isCritical) return Theme.red
        if (root.isLow) return Theme.brightYellow
        if (root.charging || root.isFull) return Theme.green
        return Theme.fg
    }

    RowLayout {
        id: batRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: root.batteryIcon(root.pct, root.charging, root.isFull)
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeIcon
            color: root.statusColor()

            SequentialAnimation on opacity {
                running: root.isCritical
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 0.3; duration: 750 }
                NumberAnimation { from: 0.3; to: 1.0; duration: 750 }
            }
        }

        Text {
            text: {
                if (root.mode === "percentage") return Math.round(root.pct) + "%"
                if (root.isFull) return "Full"
                if (root.charging && root.timeToFull > 0) return root.formatSeconds(root.timeToFull)
                if (!root.charging && root.timeToEmpty > 0) return root.formatSeconds(root.timeToEmpty)
                return Math.round(root.pct) + "%"
            }
            color: root.statusColor()
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
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
                root.mode = (root.mode === "percentage" ? "time" : "percentage")
            } else if (ev.button === Qt.RightButton) {
                profilePopup.toggle()
            }
        }
    }

    PowerProfileSlider {
        id: profilePopup
        anchorItem: root
    }

    GlobalShortcut {
        name: "togglePowerMenu"
        description: "Toggle the power profile menu"
        onPressed: profilePopup.toggle()
    }
}
