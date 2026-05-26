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

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on Layout.preferredWidth { NumberAnimation { duration: Theme.animFast } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Item {
            Layout.preferredWidth: 14
            Layout.preferredHeight: 18

            Text {
                anchors.centerIn: parent
                text: NotifService.hasUnread ? "󰂞" : "󰂚"
                color: NotifService.hasUnread ? Theme.yellow : Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeIcon
                Behavior on color { ColorAnimation { duration: 200 } }

                SequentialAnimation on scale {
                    running: NotifService.hasUnread
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 1.12; duration: 700; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 1.12; to: 1.0; duration: 700; easing.type: Easing.InOutQuad }
                }
            }

            Rectangle {
                visible: NotifService.unreadCount > 0
                width: Math.max(12, cntText.implicitWidth + 6)
                height: 12
                radius: 6
                color: Theme.red
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: -4
                anchors.topMargin: -2

                Text {
                    id: cntText
                    anchors.centerIn: parent
                    text: NotifService.unreadCount > 9 ? "9+" : NotifService.unreadCount
                    color: Theme.bg
                    font.family: Theme.fontFamily
                    font.pixelSize: 8
                    font.bold: true
                }
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(ev) {
            if (ev.button === Qt.LeftButton) hub.toggle()
            else if (ev.button === Qt.RightButton) NotifService.dismissAll()
        }
    }

    NotifHub {
        id: hub
        anchorItem: root
    }

    NotifToast {}

    GlobalShortcut {
        name: "toggleNotifHub"
        description: "Toggle the notification hub"
        onPressed: hub.toggle()
    }
}
