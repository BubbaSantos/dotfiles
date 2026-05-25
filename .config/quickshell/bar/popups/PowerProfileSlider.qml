import "."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import qs

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

    function toggle() { visible = !visible }
    function close()  { visible = false }

    Timer {
        id: closeTimer
        interval: 450
        onTriggered: root.close()
    }

    readonly property var profiles: PowerProfiles.hasPerformanceProfile
        ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
        : [PowerProfile.PowerSaver, PowerProfile.Balanced]

    function profileLabel(p) {
        if (p === PowerProfile.PowerSaver) return "Saver"
        if (p === PowerProfile.Performance) return "Performance"
        return "Balanced"
    }

    function profileIcon(p) {
        if (p === PowerProfile.PowerSaver) return "󰌪"
        if (p === PowerProfile.Performance) return "󰓅"
        return "󰊚"
    }

    readonly property var batteries: {
        const devs = UPower.devices.values || []
        return devs.filter(d => d.ready && (
            d.isLaptopBattery
            || d.type === UPowerDeviceType.Mouse
            || d.type === UPowerDeviceType.Keyboard
            || d.type === UPowerDeviceType.Headphones
            || d.type === UPowerDeviceType.Headset
        ))
    }

    function deviceLabel(d) {
        if (!d.isLaptopBattery) return "External device"
        if (d.nativePath === "BAT1") return "External (bay)"
        return "Internal"
    }

    function deviceIcon(d) {
        if (d.isLaptopBattery) return "󰂄"
        if (d.type === UPowerDeviceType.Mouse) return "󰍽"
        if (d.type === UPowerDeviceType.Keyboard) return "󰌌"
        if (d.type === UPowerDeviceType.Headphones) return "󰋋"
        if (d.type === UPowerDeviceType.Headset) return "󰋎"
        return "󰂁"
    }

    function levelColor(pct) {
        if (pct <= 10) return Theme.red
        if (pct <= 25) return Theme.brightYellow
        return Theme.green
    }

    function healthColor(pct) {
        if (pct >= 80) return Theme.green
        if (pct >= 60) return Theme.brightYellow
        return Theme.red
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: card
        width: 360
        height: menuColumn.implicitHeight + 28

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

        // Keyboard shortcuts when popup is open
        Item {
            id: keyHandler
            anchors.fill: parent
            focus: root.visible
            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_S) {
                    PowerProfiles.profile = PowerProfile.PowerSaver
                    closeTimer.restart()
                    event.accepted = true
                } else if (event.key === Qt.Key_B) {
                    PowerProfiles.profile = PowerProfile.Balanced
                    closeTimer.restart()
                    event.accepted = true
                } else if (event.key === Qt.Key_P && PowerProfiles.hasPerformanceProfile) {
                    PowerProfiles.profile = PowerProfile.Performance
                    closeTimer.restart()
                    event.accepted = true
                } else if (event.key === Qt.Key_Escape) {
                    root.close()
                    event.accepted = true
                }
            }
        }

        Rectangle {
            id: closeBtn
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
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
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
            spacing: 12

            Text {
                text: "Power Profile"
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
            }

            Rectangle {
                id: track
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                radius: 21
                color: Qt.rgba(0, 0, 0, 0.25)

                Rectangle {
                    id: thumb
                    height: parent.height - 4
                    y: 2
                    radius: (parent.height - 4) / 2
                    color: Theme.yellow

                    readonly property int activeIndex: {
                        const idx = root.profiles.indexOf(PowerProfiles.profile)
                        return idx < 0 ? 1 : idx
                    }

                    width: (parent.width - 4) / root.profiles.length
                    x: 2 + activeIndex * width

                    Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutExpo } }
                    Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.OutExpo } }
                }

                Row {
                    anchors.fill: parent

                    Repeater {
                        model: root.profiles

                        delegate: Item {
                            required property var modelData
                            width: track.width / root.profiles.length
                            height: track.height

                            readonly property bool isActive: modelData === PowerProfiles.profile

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: root.profileIcon(parent.parent.modelData)
                                    color: parent.parent.isActive ? Theme.bg : Theme.fgDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }
                                Text {
                                    text: root.profileLabel(parent.parent.modelData)
                                    color: parent.parent.isActive ? Theme.bg : Theme.fgDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.bold: parent.parent.isActive
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    PowerProfiles.profile = parent.modelData
                                    closeTimer.restart()
                                }
                            }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: PowerProfiles.hasPerformanceProfile
                      ? "Press S / B / P · Esc to close"
                      : "Press S / B · Esc to close"
                color: Theme.fgVeryDim
                font.family: Theme.fontFamily
                font.pixelSize: 9
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                Layout.fillWidth: true
                visible: PowerProfiles.degradationReason !== PerformanceDegradationReason.None
                text: {
                    const r = PowerProfiles.degradationReason
                    if (r === PerformanceDegradationReason.LapDetected) return "⚠ Limited: lap detected"
                    if (r === PerformanceDegradationReason.HighTemperature) return "⚠ Limited: high temperature"
                    return "⚠ Performance limited"
                }
                color: Theme.brightYellow
                font.family: Theme.fontFamily
                font.pixelSize: 10
                elide: Text.ElideRight
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 4
                height: 1
                color: Qt.rgba(1, 1, 1, 0.06)
                visible: root.batteries.length > 0
            }

            Text {
                text: "Batteries"
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                visible: root.batteries.length > 0
            }

            Repeater {
                model: root.batteries

                delegate: ColumnLayout {
                    id: batDelegate
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 4

                    readonly property real pctVal: modelData.percentage * 100
                    readonly property int filledSegments: Math.round(pctVal / 5)

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: root.deviceIcon(batDelegate.modelData)
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                        }
                        Text {
                            text: root.deviceLabel(batDelegate.modelData)
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: Math.round(batDelegate.pctVal) + "%"
                            color: root.levelColor(batDelegate.pctVal)
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }

                    Row {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 8
                        spacing: 2

                        Repeater {
                            model: 20

                            delegate: Rectangle {
                                required property int index
                                width: (parent.width - 38) / 20
                                height: 8
                                radius: 1
                                color: index < batDelegate.filledSegments
                                       ? root.levelColor(batDelegate.pctVal)
                                       : Qt.rgba(0, 0, 0, 0.3)

                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 2
                        spacing: 8
                        visible: batDelegate.modelData.healthSupported && batDelegate.modelData.healthPercentage > 0

                        Text {
                            text: "Health"
                            color: Theme.fgDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 3
                            radius: 1.5
                            color: Qt.rgba(0, 0, 0, 0.25)

                            Rectangle {
                                height: parent.height
                                width: parent.width * (batDelegate.modelData.healthPercentage / 100)
                                radius: 1.5
                                color: root.healthColor(batDelegate.modelData.healthPercentage)
                            }
                        }
                        Text {
                            text: Math.round(batDelegate.modelData.healthPercentage) + "%"
                            color: root.healthColor(batDelegate.modelData.healthPercentage)
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }
    }
}
