import "."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import qs
import qs.services
import qs.popups

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
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    function toggle() { visible = !visible }
    function close()  { visible = false }

    onVisibleChanged: {
        if (visible) {
            PopupManager.open(root)
            showPowerMenu = false
            brightReadProc.running = true
        }
    }

    // ── Brightness ────────────────────────────────────────────────────────
    property real brightness: 0.5

    Process {
        id: brightReadProc
        command: ["sh", "-c", "brightnessctl -m | cut -d, -f5"]
        stdout: StdioCollector {
            onStreamFinished: {
                const val = parseInt(text.trim().replace("%", ""))
                if (!isNaN(val)) root.brightness = Math.max(0, Math.min(1, val / 100))
            }
        }
    }

    Process {
        id: brightSetProc
    }

    function setBrightness(val) {
        brightness = Math.max(0.01, Math.min(1.0, val))
        brightSetProc.command = ["brightnessctl", "set", Math.round(brightness * 100) + "%"]
        brightSetProc.running = true
    }

    // ── Volume ────────────────────────────────────────────────────────────
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real vol: sink ? sink.audio.volume : 0
    readonly property bool muted: sink ? sink.audio.muted : false
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    // ── Power ─────────────────────────────────────────────────────────────
    property bool showPowerMenu: false
    Process { id: lockProc;     command: ["loginctl", "lock-session"] }
    Process { id: suspendProc;  command: ["systemctl", "suspend"] }
    Process { id: rebootProc;   command: ["systemctl", "reboot"] }
    Process { id: shutdownProc; command: ["systemctl", "poweroff"] }

    Process { id: dispatchProc }
    function dispatchShortcut(name) {
        root.close()
        dispatchProc.command = ["hyprctl", "dispatch", "global", "quickshell:" + name]
        dispatchProc.running = true
    }

    // ── Click-outside ─────────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    // ── Card ──────────────────────────────────────────────────────────────
    Rectangle {
        id: card
        width: 480
        height: contentCol.implicitHeight + 28
        x: root.width - width - 8
        y: Theme.barHeight + 8

        color: Theme.barBg
        radius: 14
        border.width: 1
        border.color: "#f38c6f"

        opacity: root.visible ? 1 : 0
        scale:   root.visible ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }
        Behavior on height  { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent; onClicked: {} }

        HoverHandler {
            onHoveredChanged: {
                if (!hovered) autoCloseTimer.restart()
                else autoCloseTimer.stop()
            }
        }
        Timer {
            id: autoCloseTimer
            interval: 3000
            onTriggered: root.close()
        }

        Item {
            anchors.fill: parent
            focus: root.visible
            Keys.onPressed: function(ev) {
                if (ev.key === Qt.Key_Escape) { root.close(); ev.accepted = true }
                else if (ev.key === Qt.Key_P) { root.showPowerMenu = !root.showPowerMenu; ev.accepted = true }
            }
        }

        ColumnLayout {
            id: contentCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 12

            // ── TOGGLE TILES ──────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // WiFi
                Rectangle {
                    Layout.fillWidth: true
                    height: 56; radius: 8
                    color: WifiService.powered && WifiService.connected
                           ? Qt.rgba(131/255, 165/255, 152/255, 0.2)
                           : (wfM.containsMouse ? Qt.rgba(1,1,1,0.10) : Qt.rgba(1,1,1,0.06))
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    RowLayout {
                        anchors.fill: parent; anchors.margins: 10; spacing: 8
                        Text {
                            text: {
                                if (!WifiService.powered) return "✈"
                                if (!WifiService.connected) return "󰖪"
                                if (WifiService.signal_ >= 80) return "󰤨"
                                if (WifiService.signal_ >= 60) return "󰤥"
                                if (WifiService.signal_ >= 40) return "󰤢"
                                return "󰤯"
                            }
                            color: WifiService.powered && WifiService.connected ? Theme.blue : Theme.fgDim
                            font.family: Theme.fontFamily; font.pixelSize: 20
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 2
                            Text {
                                text: "Wi-Fi"; color: Theme.fg
                                font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true
                            }
                            Text {
                                text: !WifiService.powered ? "Off"
                                      : WifiService.connected ? WifiService.ssid : "Not connected"
                                color: Theme.fgDim
                                font.family: Theme.fontFamily; font.pixelSize: 9
                                elide: Text.ElideRight; Layout.fillWidth: true
                            }
                        }
                        Rectangle {
                            width: 8; height: 8; radius: 4
                            color: WifiService.powered && WifiService.connected
                                   ? Theme.green : Qt.rgba(1,1,1,0.15)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                    MouseArea {
                        id: wfM; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: function(ev) {
                            if (ev.button === Qt.LeftButton) WifiService.setPowered(!WifiService.powered)
                            else wifiPicker.toggle()
                        }
                    }
                }

                // Bluetooth
                Rectangle {
                    Layout.fillWidth: true
                    height: 56; radius: 8
                    color: BluetoothService.powered && BluetoothService.connectedDevices.length > 0
                           ? Qt.rgba(131/255, 165/255, 152/255, 0.2)
                           : (btM.containsMouse ? Qt.rgba(1,1,1,0.10) : Qt.rgba(1,1,1,0.06))
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    RowLayout {
                        anchors.fill: parent; anchors.margins: 10; spacing: 8
                        Text {
                            text: !BluetoothService.powered ? "󰂲"
                                  : BluetoothService.connectedDevices.length > 0 ? "󰂱" : "󰂯"
                            color: BluetoothService.powered
                                   ? (BluetoothService.connectedDevices.length > 0 ? Theme.blue : Theme.fg)
                                   : Theme.fgDim
                            font.family: Theme.fontFamily; font.pixelSize: 20
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 2
                            Text {
                                text: "Bluetooth"; color: Theme.fg
                                font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true
                            }
                            Text {
                                text: !BluetoothService.powered ? "Off"
                                      : BluetoothService.connectedDevices.length > 0
                                        ? (BluetoothService.connectedDevices[0].name || "Connected")
                                        : "No devices"
                                color: Theme.fgDim
                                font.family: Theme.fontFamily; font.pixelSize: 9
                                elide: Text.ElideRight; Layout.fillWidth: true
                            }
                        }
                        Rectangle {
                            width: 8; height: 8; radius: 4
                            color: BluetoothService.powered && BluetoothService.connectedDevices.length > 0
                                   ? Theme.blue : Qt.rgba(1,1,1,0.15)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                    MouseArea {
                        id: btM; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: function(ev) {
                            if (ev.button === Qt.LeftButton) BluetoothService.setPowered(!BluetoothService.powered)
                            else btPicker.toggle()
                        }
                    }
                }

                // Notifications
                Rectangle {
                    Layout.fillWidth: true
                    height: 56; radius: 8
                    color: NotifService.hasUnread
                           ? Qt.rgba(215/255, 153/255, 33/255, 0.15)
                           : (nfM.containsMouse ? Qt.rgba(1,1,1,0.10) : Qt.rgba(1,1,1,0.06))
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    RowLayout {
                        anchors.fill: parent; anchors.margins: 10; spacing: 8
                        Text {
                            text: NotifService.hasUnread ? "󰂞" : "󰂚"
                            color: NotifService.hasUnread ? Theme.yellow : Theme.fg
                            font.family: Theme.fontFamily; font.pixelSize: 20
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 2
                            Text {
                                text: "Notifications"; color: Theme.fg
                                font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true
                            }
                            Text {
                                text: NotifService.unreadCount > 0
                                      ? NotifService.unreadCount + " unread" : "All caught up"
                                color: Theme.fgDim
                                font.family: Theme.fontFamily; font.pixelSize: 9
                            }
                        }
                        Rectangle {
                            width: 8; height: 8; radius: 4
                            color: NotifService.hasUnread ? Theme.yellow : Qt.rgba(1,1,1,0.15)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                    MouseArea {
                        id: nfM; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: function(ev) {
                            if (ev.button === Qt.LeftButton) NotifService.markAllRead()
                            else root.dispatchShortcut("toggleNotifHub")
                        }
                    }
                }
            }

            // ── VOLUME SLIDER ─────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true; spacing: 10

                Text {
                    text: root.muted ? "󰝟" : root.vol > 0.6 ? "󰕾" : root.vol > 0.2 ? "󰖀" : "󰕿"
                    color: root.muted ? Theme.red : Theme.fgDim
                    font.family: Theme.fontFamily; font.pixelSize: 16
                    width: 18; horizontalAlignment: Text.AlignHCenter
                    Behavior on color { ColorAnimation { duration: 100 } }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.sink) root.sink.audio.muted = !root.sink.audio.muted
                    }
                }

                Item {
                    id: volSlider; Layout.fillWidth: true; height: 20

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width; height: 4; radius: 2
                        color: Qt.rgba(1,1,1,0.1)

                        Rectangle {
                            width: parent.width * Math.min(1.0, root.vol)
                            height: parent.height; radius: parent.radius
                            color: root.muted ? Theme.fgVeryDim : Theme.blue
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 12; height: 12; radius: 6; color: Theme.fg
                        x: Math.max(0, Math.min(parent.width - 12,
                                Math.min(1.0, root.vol) * parent.width - 6))
                    }

                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.SizeHorCursor
                        function setVol(mx) {
                            if (!root.sink) return
                            root.sink.audio.volume = Math.max(0, Math.min(1.0, mx / volSlider.width))
                        }
                        onClicked: setVol(mouseX)
                        onPositionChanged: if (pressed) setVol(mouseX)
                    }
                }

                Text {
                    text: root.muted ? "muted" : Math.round(root.vol * 100) + "%"
                    color: root.muted ? Theme.red : Theme.fgDim
                    font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall
                    width: 38; horizontalAlignment: Text.AlignRight
                    Behavior on color { ColorAnimation { duration: 100 } }
                }
            }

            // ── BRIGHTNESS SLIDER ─────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true; spacing: 10

                Text {
                    text: root.brightness > 0.66 ? "󰃠" : root.brightness > 0.33 ? "󰃟" : "󰃞"
                    color: Theme.fgDim
                    font.family: Theme.fontFamily; font.pixelSize: 16
                    width: 18; horizontalAlignment: Text.AlignHCenter
                }

                Item {
                    id: brightSlider; Layout.fillWidth: true; height: 20

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width; height: 4; radius: 2
                        color: Qt.rgba(1,1,1,0.1)

                        Rectangle {
                            width: parent.width * root.brightness
                            height: parent.height; radius: parent.radius
                            color: Theme.yellow
                        }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 12; height: 12; radius: 6; color: Theme.fg
                        x: Math.max(0, Math.min(parent.width - 12,
                                root.brightness * parent.width - 6))
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

            // ── SEPARATOR ─────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true; height: 1
                color: Qt.rgba(1,1,1,0.08)
            }

            // ── LAUNCHER BUTTONS ──────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true; spacing: 8

                Repeater {
                    model: [
                        { label: "Calendar",  icon: "󰸗", color: Theme.aqua   },
                        { label: "Timers",    icon: "󰔛", color: Theme.purple },
                        { label: "Hub",       icon: "󰂚", color: Theme.yellow },
                        { label: "Power",     icon: "⏻",  color: Theme.red    },
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true; height: 44; radius: 8
                        color: (index === 3 && root.showPowerMenu)
                               ? Qt.rgba(1,1,1,0.14)
                               : (lM.containsMouse ? Qt.rgba(1,1,1,0.12) : Qt.rgba(1,1,1,0.06))
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        ColumnLayout {
                            anchors.centerIn: parent; spacing: 3
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.icon; color: modelData.color
                                font.family: Theme.fontFamily; font.pixelSize: 16
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label; color: Theme.fgDim
                                font.family: Theme.fontFamily; font.pixelSize: 9
                            }
                        }

                        MouseArea {
                            id: lM; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (index === 0)      root.dispatchShortcut("toggleCalendar")
                                else if (index === 1) timersMenu.toggle()
                                else if (index === 2) root.dispatchShortcut("toggleNotifHub")
                                else if (index === 3) root.showPowerMenu = !root.showPowerMenu
                            }
                        }
                    }
                }
            }

            // ── POWER ACTIONS (expanded) ──────────────────────────────────
            RowLayout {
                Layout.fillWidth: true; spacing: 8
                visible: root.showPowerMenu

                Repeater {
                    model: [
                        { label: "Lock",     icon: "󰌾", color: Theme.blue   },
                        { label: "Suspend",  icon: "󰤄", color: Theme.blue   },
                        { label: "Reboot",   icon: "󰑓", color: Theme.yellow },
                        { label: "Shutdown", icon: "⏻",  color: Theme.red    },
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true; height: 40; radius: 8
                        color: pM.containsMouse ? Qt.rgba(1,1,1,0.14) : Qt.rgba(1,1,1,0.06)
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        ColumnLayout {
                            anchors.centerIn: parent; spacing: 2
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.icon; color: modelData.color
                                font.family: Theme.fontFamily; font.pixelSize: 14
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label; color: Theme.fgDim
                                font.family: Theme.fontFamily; font.pixelSize: 9
                            }
                        }

                        MouseArea {
                            id: pM; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (index === 0) lockProc.running = true
                                else if (index === 1) suspendProc.running = true
                                else if (index === 2) rebootProc.running = true
                                else if (index === 3) shutdownProc.running = true
                                root.close()
                            }
                        }
                    }
                }
            }

            Item { height: 2 }
        }
    }

    // ── Sub-popups ────────────────────────────────────────────────────────
    WifiPicker     { id: wifiPicker; anchorItem: card }
    BluetoothPicker { id: btPicker;  anchorItem: card }
    TimepiecesMenu { id: timersMenu; anchorItem: card }
}
