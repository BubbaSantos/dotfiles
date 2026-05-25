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
    visible: TimepiecesStore.remindersBarShow &&
             (TimepiecesStore.reminders.length > 0 || TimepiecesStore.firedCount > 0)
    color: mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
    radius: 6

    readonly property int firedCount: TimepiecesStore.firedCount

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
                text: root.firedCount > 0 ? "󰂞" : "󰂟"
                color: root.firedCount > 0 ? Theme.red : Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeIcon
                Behavior on color { ColorAnimation { duration: 200 } }

                // Pulse animation when fired
                SequentialAnimation on scale {
                    running: root.firedCount > 0
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 1.15; duration: 600; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 1.15; to: 1.0; duration: 600; easing.type: Easing.InOutQuad }
                }
            }

            // Red dot badge for fired count
            Rectangle {
                visible: root.firedCount > 0
                width: countText.implicitWidth + 6
                height: 12
                radius: 6
                color: Theme.red
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: -4
                anchors.topMargin: -2

                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: root.firedCount
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
        onClicked: remindersPopup.toggle()
    }

    Reminders {
        id: remindersPopup
        anchorItem: root
    }

    GlobalShortcut {
        name: "toggleReminders"
        description: "Toggle the Reminders popup"
        onPressed: remindersPopup.toggle()
    }
}
