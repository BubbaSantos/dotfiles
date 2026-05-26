import "."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
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

    // Password entry state
    property string passwordSsid: ""
    property string passwordValue: ""

    function toggle() {
        if (visible) close()
        else open_()
    }
    function open_() {
        passwordSsid = ""
        passwordValue = ""
        WifiService.refreshStatus()
        WifiService.refreshNetworks()
        WifiService.refreshKnown()
        WifiService.scan()
        visible = true
    }
    function close() {
        visible = false
        passwordSsid = ""
        passwordValue = ""
    }

    onVisibleChanged: if (visible) PopupManager.open(root)

    property int focusIndex: 0

    function clampFocus() {
        focusIndex = Math.max(0, Math.min(focusIndex, WifiService.networks.length - 1))
    }
    function activateFocused() {
        if (focusIndex < 0 || focusIndex >= WifiService.networks.length) return
        const net = WifiService.networks[focusIndex]
        if (!net || net.current) return
        if (net.security === "open" || isKnown(net.ssid)) {
            WifiService.connectToNetwork(net.ssid, "")
            root.close()
        } else {
            passwordSsid = net.ssid
            passwordValue = ""
        }
    }

    function isKnown(ssid) {
        for (const k of WifiService.knownNetworks) {
            if (k.ssid === ssid) return true
        }
        return false
    }

    function signalIcon(signalCount) {
        // signalCount is the number of asterisks from iwctl (1-4)
        if (signalCount >= 4) return "󰤨"
        if (signalCount >= 3) return "󰤥"
        if (signalCount >= 2) return "󰤢"
        if (signalCount >= 1) return "󰤟"
        return "󰤯"
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

        color: Theme.popupBg
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

        HoverHandler {
            onHoveredChanged: {
                if (!hovered) autoCloseTimer.restart()
                else autoCloseTimer.stop()
            }
        }
        Timer { id: autoCloseTimer; interval: 4000; onTriggered: root.close() }

        Item {
            anchors.fill: parent
            focus: root.visible && root.passwordSsid === ""
            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) {
                    if (root.passwordSsid) { root.passwordSsid = ""; root.passwordValue = ""; event.accepted = true; return }
                    root.close()
                    event.accepted = true
                } else if (event.key === Qt.Key_R && (event.modifiers & Qt.ControlModifier)) {
                    WifiService.scan()
                    event.accepted = true
                } else if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
                    root.focusIndex = Math.min(root.focusIndex + 1, WifiService.networks.length - 1)
                    netList.positionViewAtIndex(root.focusIndex, ListView.Contain)
                    event.accepted = true
                } else if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
                    root.focusIndex = Math.max(root.focusIndex - 1, 0)
                    netList.positionViewAtIndex(root.focusIndex, ListView.Contain)
                    event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.activateFocused()
                    event.accepted = true
                } else if (event.key === Qt.Key_W) {
                    WifiService.setPowered(!WifiService.powered)
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

            // Header: title + airplane mode toggle
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Wi-Fi"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                // Airplane mode pill
                Rectangle {
                    Layout.preferredHeight: 22
                    Layout.preferredWidth: powerToggleRow.implicitWidth + 16
                    radius: 11
                    color: WifiService.powered
                           ? Qt.rgba(0, 0, 0, 0.25)
                           : Theme.red
                    Behavior on color { ColorAnimation { duration: 200 } }

                    RowLayout {
                        id: powerToggleRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: WifiService.powered ? "󰖩" : "✈"
                            color: WifiService.powered ? Theme.fg : Theme.bg
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                        Text {
                            text: WifiService.powered ? "On" : "Airplane"
                            color: WifiService.powered ? Theme.fg : Theme.bg
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: !WifiService.powered
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WifiService.setPowered(!WifiService.powered)
                    }
                }
            }

            // Currently connected card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                radius: 6
                color: Qt.rgba(0, 0, 0, 0.2)
                visible: WifiService.connected && WifiService.powered

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: "󰤨"
                        color: Theme.green
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            text: WifiService.ssid
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: "Connected · " + WifiService.signal_ + "%"
                            color: Theme.fgDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                        }
                    }
                    Rectangle {
                        Layout.preferredHeight: 22
                        Layout.preferredWidth: 70
                        radius: 11
                        color: discMouse.containsMouse ? Theme.red : Qt.rgba(1, 1, 1, 0.08)
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Disconnect"
                            color: discMouse.containsMouse ? Theme.bg : Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }

                        MouseArea {
                            id: discMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WifiService.disconnect()
                        }
                    }
                }
            }

            // Header for available networks
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                visible: WifiService.powered

                Text {
                    text: "Available networks"
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
                        rotation: WifiService.scanning ? rotation : 0
                        RotationAnimation on rotation {
                            running: WifiService.scanning
                            loops: Animation.Infinite
                            from: 0; to: 360
                            duration: 1000
                        }
                    }

                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WifiService.scan()
                    }
                }
            }

            // Network list
            ListView {
                id: netList
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 280)
                visible: WifiService.powered
                clip: true
                model: WifiService.networks
                spacing: 2

                delegate: Item {
                    width: netList.width
                    height: root.passwordSsid === modelData.ssid ? 70 : 36

                    Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                    required property var modelData
                    required property int index

                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: modelData.current
                               ? Qt.rgba(141/255, 161/255, 152/255, 0.15)
                               : (index === root.focusIndex ? Qt.rgba(1, 1, 1, 0.10) : (rowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"))
                        Behavior on color { ColorAnimation { duration: 150 } }

                        // Row content
                        RowLayout {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 36
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                text: root.signalIcon(modelData.signal)
                                color: modelData.current ? Theme.green : Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                            }
                            Text {
                                text: modelData.security !== "open" ? "󰌾" : ""
                                color: Theme.fgDim
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                visible: text.length > 0
                            }
                            Text {
                                text: modelData.ssid
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: modelData.current
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: root.isKnown(modelData.ssid) ? "Saved" : ""
                                color: Theme.fgDim
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                visible: text.length > 0 && !modelData.current
                            }
                        }

                        // Password prompt (shown when this row is the active password target)
                        RowLayout {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            anchors.bottomMargin: 6
                            height: 28
                            spacing: 6
                            visible: root.passwordSsid === modelData.ssid

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 26
                                radius: 4
                                color: Qt.rgba(0, 0, 0, 0.3)
                                border.width: 1
                                border.color: pwField.activeFocus ? Theme.yellow : Qt.rgba(1, 1, 1, 0.08)

                                TextInput {
                                    id: pwField
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    echoMode: TextInput.Password
                                    focus: root.passwordSsid === modelData.ssid
                                    text: root.passwordValue
                                    onTextChanged: root.passwordValue = text
                                    Keys.onReturnPressed: {
                                        WifiService.connectToNetwork(modelData.ssid, root.passwordValue)
                                        root.close()
                                    }
                                    Keys.onEscapePressed: {
                                        root.passwordSsid = ""
                                        root.passwordValue = ""
                                    }
                                }
                            }

                            Rectangle {
                                Layout.preferredHeight: 26
                                Layout.preferredWidth: 60
                                radius: 4
                                color: connectMouse.containsMouse ? Theme.brightYellow : Theme.yellow
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "Connect"
                                    color: Theme.bg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: true
                                }

                                MouseArea {
                                    id: connectMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        WifiService.connectToNetwork(modelData.ssid, root.passwordValue)
                                        root.close()
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            visible: root.passwordSsid !== modelData.ssid

                            onClicked: function(ev) {
                                if (ev.button === Qt.LeftButton) {
                                    if (modelData.current) return
                                    if (modelData.security === "open" || root.isKnown(modelData.ssid)) {
                                        WifiService.connectToNetwork(modelData.ssid, "")
                                        root.close()
                                    } else {
                                        root.passwordSsid = modelData.ssid
                                        root.passwordValue = ""
                                    }
                                } else if (ev.button === Qt.RightButton) {
                                    if (root.isKnown(modelData.ssid)) {
                                        WifiService.forgetNetwork(modelData.ssid)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Empty state
            Text {
                Layout.fillWidth: true
                visible: !WifiService.powered
                text: "Wi-Fi is off"
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                Layout.topMargin: 20
                Layout.bottomMargin: 20
            }

            Text {
                Layout.fillWidth: true
                text: "j/k navigate · Enter connect · W toggle Wi-Fi · Ctrl+R rescan · Esc close"
                color: Theme.fgVeryDim
                font.family: Theme.fontFamily
                font.pixelSize: 9
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                visible: WifiService.powered
            }
        }
    }
}
