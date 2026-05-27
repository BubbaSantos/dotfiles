import "."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs
import qs.services

PanelWindow {
    id: root
    visible: false
    color: "transparent"

    anchors.top: true
    anchors.right: true

    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    property var item: null
    readonly property int cardWidth: 340

    width: cardWidth + 16
    height: Theme.barHeight + 8 + toastCard.height + 12

    function show(newItem) {
        fadeOut.stop()
        snoozeExit.stop()
        toastCard.opacity = 1
        toastCard.x = 8
        toastCard.snoozeFlash = 0
        toastCard.snoozed = false
        item = newItem
        visible = true
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 8000
        onTriggered: fadeOut.start()
    }

    NumberAnimation {
        id: fadeOut
        target: toastCard
        property: "opacity"
        to: 0
        duration: 250
        easing.type: Easing.OutCubic
        onFinished: root.visible = false
    }

    SequentialAnimation {
        id: snoozeExit
        NumberAnimation { target: toastCard; property: "snoozeFlash"; to: 1.0; duration: 80; easing.type: Easing.OutCubic }
        PauseAnimation { duration: 100 }
        ParallelAnimation {
            NumberAnimation { target: toastCard; property: "x"; to: root.cardWidth + 24; duration: 250; easing.type: Easing.InCubic }
            NumberAnimation { target: toastCard; property: "opacity"; to: 0; duration: 250; easing.type: Easing.InCubic }
        }
        onFinished: { toastCard.x = 8; toastCard.opacity = 1; toastCard.snoozeFlash = 0; toastCard.snoozed = false; root.visible = false }
    }

    GlobalShortcut {
        name: "dismissToast"
        onPressed: { if (root.visible) { hideTimer.stop(); snoozeExit.stop(); fadeOut.start() } }
    }

    GlobalShortcut {
        name: "snoozeToast"
        onPressed: {
            if (!root.visible) return
            if (root.item) NotifService.snooze(root.item, 15)
            hideTimer.stop()
            fadeOut.stop()
            toastCard.snoozed = true
            snoozeExit.start()
        }
    }

    Connections {
        target: NotifService
        function onNewNotification(item) { root.show(item) }
    }

    Rectangle {
        id: toastCard
        width: root.cardWidth
        x: 8
        y: Theme.barHeight + 8
        height: toastContent.implicitHeight + 20
        radius: 10
        color: Theme.popupBg
        property real snoozeFlash: 0.0
        property bool snoozed: false
        border.width: 1
        border.color: {
            if (!root.item) return "#f38c6f"
            const u = root.item.notif.urgency
            return u === 2 ? Theme.red : "#f38c6f"
        }

        // Snooze flash overlay
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Theme.yellow
            opacity: toastCard.snoozeFlash * 0.28
            z: 10
        }

        // Urgency stripe
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 5
            width: 3
            radius: 2
            color: {
                if (!root.item) return "#f38c6f"
                const u = root.item.notif.urgency
                if (u === 2) return Theme.red
                if (u === 0) return Theme.fgVeryDim
                return "#f38c6f"
            }
        }

        // Snooze panel — full height, right side, declared first so content can anchor to it
        Rectangle {
            id: snoozePanel
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: 2
            anchors.bottomMargin: 2
            anchors.rightMargin: 2
            width: 64
            radius: 8
            color: toastSnM.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)
            Behavior on color { ColorAnimation { duration: 100 } }

            Text {
                anchors.centerIn: parent
                text: toastCard.snoozed ? "Snoozed!" : "Snooze\n15m"
                horizontalAlignment: Text.AlignHCenter
                color: Theme.yellow
                font.family: Theme.fontFamily
                font.pixelSize: 11
                lineHeight: 1.3
            }

            MouseArea {
                id: toastSnM
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.item) NotifService.snooze(root.item, 15)
                    hideTimer.stop()
                    fadeOut.stop()
                    toastCard.snoozed = true
                    snoozeExit.start()
                }
            }
        }

        // Text content
        ColumnLayout {
            id: toastContent
            anchors.left: parent.left
            anchors.right: snoozePanel.left
            anchors.top: parent.top
            anchors.leftMargin: 16
            anchors.rightMargin: 8
            anchors.topMargin: 10
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: 5

                Image {
                    source: root.item ? NotifService.iconSource(root.item.notif) : ""
                    width: 13; height: 13
                    sourceSize: Qt.size(13, 13)
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    visible: status === Image.Ready
                }
                Text {
                    text: root.item ? NotifService.displayName(root.item.notif) : ""
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
            Text {
                text: root.item ? root.item.notif.summary : ""
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.bold: true
                textFormat: Text.StyledText
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text.length > 0
            }
            Text {
                visible: root.item && root.item.notif.body.length > 0
                text: root.item ? NotifService.cleanBody(root.item.notif) : ""
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: 11
                textFormat: Text.StyledText
                maximumLineCount: 2
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Item { height: 2 }
        }

        // Dismiss X — anchored to content area top-right
        Rectangle {
            anchors.top: parent.top
            anchors.right: snoozePanel.left
            anchors.topMargin: 6
            anchors.rightMargin: 4
            width: 16; height: 16; radius: 8
            color: xMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : "transparent"
            Behavior on color { ColorAnimation { duration: 100 } }
            z: 2

            Text {
                anchors.centerIn: parent
                text: "✕"
                color: xMouse.containsMouse ? Theme.fg : Theme.fgVeryDim
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
            MouseArea {
                id: xMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { hideTimer.stop(); fadeOut.start() }
            }
        }

        // Click-to-open — covers only the content area
        MouseArea {
            anchors.left: parent.left
            anchors.right: snoozePanel.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            onClicked: {
                hideTimer.stop()
                fadeOut.start()
                if (root.item) {
                    const actions = root.item.notif.actions || []
                    const def = actions.find(a => a.identifier === "default") || actions[0]
                    if (def) def.invoke()
                }
            }
        }
    }
}
