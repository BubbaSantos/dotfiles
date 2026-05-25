import "."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Bluetooth
import qs
import qs.services

PanelWindow {
    id: root
    property Item anchorItem: null

    visible: false
    color: "transparent"

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    function toggle() {
        if (visible) close()
        else open_()
    }
    function open_() {
        if (BluetoothService.powered) BluetoothService.startScan()
        visible = true
    }
    function close() {
        if (BluetoothService.scanning) BluetoothService.stopScan()
        visible = false
    }

    function deviceIcon(d) {
        if (!d.icon) return "󰂯"
        const i = d.icon.toLowerCase()
        if (i.includes("audio") || i.includes("headphone") || i.includes("headset")) return "󰋋"
        if (i.includes("mouse") || i.includes("pointing")) return "󰍽"
        if (i.includes("keyboard")) return "󰌌"
        if (i.includes("phone")) return "󰏲"
        if (i.includes("computer") || i.includes("laptop")) return "󰌢"
        if (i.includes("gamepad") || i.includes("joypad")) return "󰊴"
        if (i.includes("watch")) return "󰖉"
        return "󰂯"
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: card
        width: 380
        height: Math.min(menuColumn.implicitHeight + 28, 520)

        x: {
            if (!root.anchorItem) return 20
            const p = root.anchorItem.mapToItem(null, 0, 0)
            const desired = p.x + root.anchorItem.width - width
            return Math.max(8, Math.min(root.width - width - 8, desired))
        }
        y: 0

        color: Theme.barBg
        radius: 10
        border.width: 1
        border.color: "#f38c6f"

        opacity: root.visible ? 1 : 0
        scale: root.visible ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Item {
            anchors.fill: parent
            focus: root.visible
            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) {
                    root.close()
                    event.accepted = true
                } else if (event.key === Qt.Key_R && (event.modifiers & Qt.ControlModifier)) {
                    if (BluetoothService.scanning) BluetoothService.stopScan()
                    else BluetoothService.startScan()
                    event.accepted = true
                }
            }
        }

        // X close button
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 8
            anchors.rightMargin: 8
            width: 20
            height: 20
            radius: 10
            color: closeMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
            z: 2

            Text {
                anchors.centerIn: parent
                text: "✕"
                color: closeMouse.containsMouse ? Theme.fg : Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.close()
            }
        }

        ColumnLayout {
            id: menuColumn
            anchors.fill: parent
            anchors.margins: 14
            anchors.topMargin: 14
            anchors.rightMargin: 36
            spacing: 10

            // Header + power toggle
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Bluetooth"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                }
                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredHeight: 22
                    Layout.preferredWidth: powerRow.implicitWidth + 16
                    radius: 11
                    color: BluetoothService.powered
                           ? Qt.rgba(0, 0, 0, 0.25)
                           : Theme.red
                    Behavior on color { ColorAnimation { duration: 200 } }

                    RowLayout {
                        id: powerRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: BluetoothService.powered ? "󰂯" : "󰂲"
                            color: BluetoothService.powered ? Theme.fg : Theme.bg
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                        }
                        Text {
                            text: BluetoothService.powered ? "On" : "Off"
                            color: BluetoothService.powered ? Theme.fg : Theme.bg
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: !BluetoothService.powered
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: BluetoothService.setPowered(!BluetoothService.powered)
                    }
                }
            }

            // Off state
            Text {
                Layout.fillWidth: true
                visible: !BluetoothService.powered
                text: BluetoothService.ready ? "Bluetooth is off" : "No Bluetooth adapter"
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                Layout.topMargin: 20
                Layout.bottomMargin: 20
            }

            // Paired devices section
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                visible: BluetoothService.powered && BluetoothService.pairedDevices.length > 0

                Text {
                    text: "Paired"
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                }
                Item { Layout.fillWidth: true }
            }

            ListView {
                id: pairedList
                Layout.fillWidth: true
                Layout.preferredHeight: contentHeight
                visible: BluetoothService.powered && BluetoothService.pairedDevices.length > 0
                interactive: false
                model: BluetoothService.pairedDevices
                spacing: 2

                delegate: Item {
                    width: pairedList.width
                    height: 40
                    required property var modelData

                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: modelData.connected
                               ? Qt.rgba(141/255, 161/255, 152/255, 0.15)
                               : (rowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                text: root.deviceIcon(modelData)
                                color: modelData.connected ? Theme.green : Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 16
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    text: modelData.name || "Unknown"
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: modelData.connected
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: {
                                        if (modelData.pairing) return "Pairing…"
                                        if (modelData.connected) {
                                            if (modelData.batteryAvailable) {
                                                return `Connected · ${Math.round(modelData.battery * 100)}%`
                                            }
                                            return "Connected"
                                        }
                                        return "Paired"
                                    }
                                    color: Theme.fgDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                }
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: function(ev) {
                                if (ev.button === Qt.LeftButton) {
                                    if (modelData.connected) modelData.disconnect()
                                    else modelData.connect()
                                } else if (ev.button === Qt.RightButton) {
                                    modelData.forget()
                                }
                            }
                        }
                    }
                }
            }

            // Available (unpaired) devices section
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                visible: BluetoothService.powered

                Text {
                    text: "Available"
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    Layout.preferredHeight: 20
                    Layout.preferredWidth: 20
                    radius: 10
                    color: refreshMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                    Behavior on color { ColorAnimation { duration: 200 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰑐"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        rotation: BluetoothService.scanning ? rotation : 0
                        RotationAnimation on rotation {
                            running: BluetoothService.scanning
                            loops: Animation.Infinite
                            from: 0; to: 360
                            duration: 1500
                        }
                    }

                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (BluetoothService.scanning) BluetoothService.stopScan()
                            else BluetoothService.startScan()
                        }
                    }
                }
            }

            ListView {
                id: availList
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 180)
                visible: BluetoothService.powered
                clip: true
                model: BluetoothService.availableDevices
                spacing: 2

                delegate: Item {
                    width: availList.width
                    height: 36
                    required property var modelData

                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: rowMouse2.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                text: root.deviceIcon(modelData)
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                            }
                            Text {
                                text: modelData.name || "Unknown"
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: modelData.pairing ? "Pairing…" : ""
                                color: Theme.fgDim
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                visible: text.length > 0
                            }
                        }

                        MouseArea {
                            id: rowMouse2
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.pair()
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: BluetoothService.powered && BluetoothService.availableDevices.length === 0
                text: BluetoothService.scanning ? "Scanning…" : "Click refresh to scan"
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: 10
                horizontalAlignment: Text.AlignHCenter
                Layout.topMargin: 4
                Layout.bottomMargin: 8
            }

            Text {
                Layout.fillWidth: true
                text: "Ctrl+R rescan · Right-click paired to forget · Esc to close"
                color: Theme.fgVeryDim
                font.family: Theme.fontFamily
                font.pixelSize: 9
                horizontalAlignment: Text.AlignHCenter
                visible: BluetoothService.powered
            }
        }
    }
}
