import "."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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

    function toggle() { if (visible) close(); else open_() }
    function open_() { NotifService.markAllRead(); visible = true }
    function close() { visible = false }

    onVisibleChanged: if (visible) PopupManager.open(root)

    property int focusIndex: 0

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: card
        width: 380
        height: Math.min(cardCol.implicitHeight + 24, root.height - 16)

        x: {
            if (!root.anchorItem) return root.width - width - 12
            const p = root.anchorItem.mapToItem(null, 0, 0)
            const desired = p.x + (root.anchorItem.width / 2) - (width / 2)
            return Math.max(8, Math.min(root.width - width - 8, desired))
        }
        y: 0

        color: Theme.popupBg
        radius: 10
        border.width: 1
        border.color: "#f38c6f"
        clip: true

        opacity: root.visible ? 1 : 0
        scale: root.visible ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent; onClicked: {} }

        HoverHandler {
            onHoveredChanged: {
                if (!hovered) autoCloseTimer.restart()
                else autoCloseTimer.stop()
            }
        }
        Timer { id: autoCloseTimer; interval: 2000; onTriggered: root.close() }

        Item {
            anchors.fill: parent
            focus: root.visible
            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) {
                    root.close(); event.accepted = true
                } else if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
                    root.focusIndex = Math.min(root.focusIndex + 1, NotifService.notifications.length - 1)
                    event.accepted = true
                } else if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
                    root.focusIndex = Math.max(root.focusIndex - 1, 0)
                    event.accepted = true
                } else if (event.key === Qt.Key_D || event.key === Qt.Key_Delete) {
                    const notifs = NotifService.notifications
                    if (notifs.length > 0) {
                        NotifService.dismiss(notifs[root.focusIndex])
                        root.focusIndex = Math.min(root.focusIndex, NotifService.notifications.length - 1)
                    }
                    event.accepted = true
                } else if (event.key === Qt.Key_C) {
                    NotifService.dismissAll()
                    event.accepted = true
                }
            }
        }

        ColumnLayout {
            id: cardCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 8

            // Header
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: NotifService.hasUnread ? "󰂞" : "󰂚"
                    color: NotifService.hasUnread ? Theme.yellow : Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Text {
                    text: "Notifications"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                }
                Rectangle {
                    visible: NotifService.unreadCount > 0
                    width: Math.max(16, badgeText.implicitWidth + 8)
                    height: 16
                    radius: 8
                    color: Theme.red
                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: NotifService.unreadCount > 99 ? "99+" : NotifService.unreadCount
                        color: Theme.bg
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.bold: true
                    }
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    visible: NotifService.notifications.length > 0
                    Layout.preferredHeight: 20
                    Layout.preferredWidth: clearText.implicitWidth + 14
                    radius: 10
                    color: clearMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Text {
                        id: clearText
                        anchors.centerIn: parent
                        text: "Clear all"
                        color: Theme.fgDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }
                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotifService.dismissAll()
                    }
                }
                Rectangle {
                    Layout.preferredWidth: 20; Layout.preferredHeight: 20
                    radius: 10
                    color: closeXMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: closeXMouse.containsMouse ? Theme.fg : Theme.fgDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                    MouseArea {
                        id: closeXMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            // Empty state
            Item {
                visible: NotifService.notifications.length === 0
                Layout.fillWidth: true
                Layout.preferredHeight: 90
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰂚"
                        color: Theme.fgVeryDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 30
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "No notifications"
                        color: Theme.fgVeryDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                }
            }

            // Notification list
            Flickable {
                id: notifFlick
                visible: NotifService.notifications.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(notifCol.implicitHeight, 460)
                contentHeight: notifCol.implicitHeight
                clip: true
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                ColumnLayout {
                    id: notifCol
                    width: notifFlick.width
                    spacing: 4

                    Repeater {
                        model: NotifService.notifications

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            id: notifCard
                            property bool showSnoozePicker: false
                            property string countdown: modelData.snoozedUntil ? NotifService.snoozeCountdown(modelData.snoozedUntil) : ""

                            Timer {
                                running: modelData.snoozedUntil
                                interval: 1000
                                repeat: true
                                onTriggered: notifCard.countdown = NotifService.snoozeCountdown(modelData.snoozedUntil || 0)
                            }
                            Layout.fillWidth: true
                            Layout.preferredHeight: notifInner.implicitHeight + 16
                            radius: 8
                            color: index === root.focusIndex
                                   ? Qt.rgba(1, 1, 1, 0.07)
                                   : modelData.snoozedUntil
                                       ? Qt.rgba(0.87, 0.72, 0.19, 0.07)
                                       : Qt.rgba(0, 0, 0, 0.18)
                            Behavior on color { ColorAnimation { duration: 120 } }

                            // Urgency stripe
                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.margins: 5
                                width: 3
                                radius: 2
                                color: {
                                    if (modelData.snoozedUntil) return Theme.yellow
                                    const u = modelData.notif.urgency
                                    if (u === 2) return Theme.red
                                    if (u === 0) return Theme.fgVeryDim
                                    return "#f38c6f"
                                }
                            }

                            ColumnLayout {
                                id: notifInner
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.leftMargin: 16
                                anchors.rightMargin: 104
                                anchors.topMargin: 8
                                spacing: 2

                                // App name row with icon
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 5

                                    Image {
                                        source: NotifService.iconSource(modelData.notif)
                                        width: 14; height: 14
                                        sourceSize: Qt.size(14, 14)
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        visible: status === Image.Ready
                                    }
                                    Text {
                                        text: NotifService.displayName(modelData.notif)
                                        color: Theme.fgDim
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        visible: !modelData.snoozedUntil
                                        text: NotifService.relativeTime(modelData.arrivedAt)
                                        color: Theme.fgVeryDim
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                    }
                                }

                                Text {
                                    visible: text.length > 0
                                    text: modelData.notif.summary
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                    textFormat: Text.StyledText
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    visible: modelData.notif.body.length > 0
                                    text: NotifService.cleanBody(modelData.notif)
                                    color: Theme.fgDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    textFormat: Text.StyledText
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                // Action buttons (hidden while snooze picker is open or snoozed)
                                RowLayout {
                                    visible: !notifCard.showSnoozePicker
                                             && !modelData.snoozedUntil
                                             && modelData.notif.actions
                                             && modelData.notif.actions.length > 0
                                    spacing: 4
                                    Layout.topMargin: 2

                                    Repeater {
                                        model: (modelData.notif.actions || []).filter(a => {
                                            const id = (a.identifier || "").toLowerCase()
                                            const txt = (a.text || "").toLowerCase()
                                            return id !== "settings" && txt !== "settings"
                                        })
                                        delegate: Rectangle {
                                            required property var modelData
                                            height: 22
                                            implicitWidth: actText.implicitWidth + 14
                                            radius: 4
                                            color: actMouse.containsMouse
                                                   ? Qt.rgba(1, 1, 1, 0.14)
                                                   : Qt.rgba(1, 1, 1, 0.07)
                                            Behavior on color { ColorAnimation { duration: 100 } }
                                            Text {
                                                id: actText
                                                anchors.centerIn: parent
                                                text: {
                                                    const t = modelData.text || modelData.identifier || ""
                                                    return t.toLowerCase() === "activate" ? "Open" : t
                                                }
                                                color: Theme.fg
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 10
                                            }
                                            MouseArea {
                                                id: actMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: { modelData.invoke(); root.close() }
                                            }
                                        }
                                    }
                                    Item { Layout.fillWidth: true }
                                }

                                // Snooze time picker
                                RowLayout {
                                    visible: notifCard.showSnoozePicker
                                    spacing: 4
                                    Layout.topMargin: 2

                                    Text {
                                        text: "Snooze:"
                                        color: Theme.fgDim
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                    }

                                    Repeater {
                                        model: [5, 10, 15]
                                        delegate: Rectangle {
                                            required property int modelData
                                            height: 22
                                            implicitWidth: snoozeMinText.implicitWidth + 14
                                            radius: 4
                                            color: snMouse.containsMouse
                                                   ? Qt.rgba(1, 1, 1, 0.18)
                                                   : Qt.rgba(1, 1, 1, 0.07)
                                            Behavior on color { ColorAnimation { duration: 100 } }
                                            Text {
                                                id: snoozeMinText
                                                anchors.centerIn: parent
                                                text: modelData + "m"
                                                color: Theme.yellow
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 10
                                            }
                                            MouseArea {
                                                id: snMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    NotifService.snooze(notifCard.modelData, modelData)
                                                    notifCard.showSnoozePicker = false
                                                }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        height: 22; implicitWidth: 22; radius: 4
                                        color: cancelSnMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: "✕"
                                            color: Theme.fgDim
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
                                        }
                                        MouseArea {
                                            id: cancelSnMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: notifCard.showSnoozePicker = false
                                        }
                                    }

                                    Item { Layout.fillWidth: true }
                                }

                                Item { height: 2 }
                            }

                            // Top-right controls: Snooze + ✕ dismiss
                            Row {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.topMargin: 5
                                anchors.rightMargin: 4
                                spacing: 2
                                z: 2

                                Rectangle {
                                    height: 16
                                    width: snoozeBtnText.implicitWidth + 10
                                    radius: 4
                                    color: snBtnMouse.containsMouse
                                        ? (modelData.snoozedUntil ? Qt.rgba(1, 0.3, 0.3, 0.18) : Qt.rgba(1, 1, 1, 0.14))
                                        : (modelData.snoozedUntil || notifCard.showSnoozePicker)
                                            ? Qt.rgba(1, 1, 1, 0.08)
                                            : "transparent"
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    Text {
                                        id: snoozeBtnText
                                        anchors.centerIn: parent
                                        text: modelData.snoozedUntil
                                            ? (snBtnMouse.containsMouse ? "Cancel snooze" : ("Snoozed " + notifCard.countdown))
                                            : "Snooze"
                                        color: modelData.snoozedUntil
                                            ? (snBtnMouse.containsMouse ? Theme.red : Theme.yellow)
                                            : (notifCard.showSnoozePicker ? Theme.yellow : Theme.fgDim)
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                    }
                                    MouseArea {
                                        id: snBtnMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (modelData.snoozedUntil)
                                                NotifService.cancelSnooze(notifCard.modelData)
                                            else
                                                notifCard.showSnoozePicker = !notifCard.showSnoozePicker
                                        }
                                    }
                                }

                                Rectangle {
                                    width: 16; height: 16; radius: 8
                                    color: dxMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    Text {
                                        anchors.centerIn: parent
                                        text: "✕"
                                        color: dxMouse.containsMouse ? Theme.fg : Theme.fgVeryDim
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                    }
                                    MouseArea {
                                        id: dxMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            NotifService.dismiss(notifCard.modelData)
                                            root.focusIndex = Math.min(root.focusIndex, NotifService.notifications.length - 1)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: NotifService.notifications.length > 0
                text: "j/k navigate · D dismiss · C clear all · Esc close"
                color: Theme.fgVeryDim
                font.family: Theme.fontFamily
                font.pixelSize: 9
                horizontalAlignment: Text.AlignHCenter
                Layout.bottomMargin: 2
            }
        }
    }
}
