import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.services

PanelWindow {
    id: root

    property Item anchorItem: null
    property int popupWidth: 380
    property int popupHeight: 200
    default property alias contentChildren: contentArea.data

    visible: false
    color: "transparent"

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    property bool keepOpen: false

    function toggle() { visible = !visible }
    function close()  { visible = false }

    onVisibleChanged: if (visible) PopupManager.open(root)

    // Click-outside-to-close
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: card
        width: root.popupWidth
        height: root.popupHeight

        x: {
            if (!root.anchorItem) return 20
            const p = root.anchorItem.mapToItem(null, 0, 0)
            const desired = p.x + (root.anchorItem.width / 2) - (width / 2)
            return Math.max(8, Math.min(root.width - width - 8, desired))
        }
        y: Theme.barHeight + 8

        color: Theme.popupBg
        radius: 14
        border.width: 1
        border.color: "#f38c6f"

        opacity: root.visible ? 1 : 0
        scale: root.visible ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }

        // Eat clicks so they don't fall through to the close area
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
        Timer {
            id: autoCloseTimer
            interval: 2000
            onTriggered: if (!root.keepOpen) root.close()
        }

        Item {
            id: contentArea
            anchors.fill: parent
            anchors.margins: 12
        }
    }
}
