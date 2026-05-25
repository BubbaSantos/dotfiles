import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs

PanelWindow {
    id: bar
    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight + Theme.barMargin

    // The three module groups, each with rounded background
    Item {
        anchors.fill: parent
        anchors.topMargin: 3
        anchors.bottomMargin: 1
        anchors.leftMargin: Theme.barMargin
        anchors.rightMargin: Theme.barMargin

        // LEFT GROUP
        Rectangle {
            id: leftGroup
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: Theme.barHeight - 4
            radius: Theme.groupRadius
            color: Theme.barBg
            width: leftRow.implicitWidth + 16

            RowLayout {
                id: leftRow
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 0

                NowPlaying {}
                Pulseaudio {}
            }
        }

        // CENTER GROUP
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            height: Theme.barHeight - 4
            radius: Theme.groupRadius
            color: Theme.barBg
            width: centerRow.implicitWidth + 8

            RowLayout {
                id: centerRow
                anchors.fill: parent
                spacing: 0
                Workspaces {}
            }
        }

        // RIGHT GROUP
        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: Theme.barHeight - 4
            radius: Theme.groupRadius
            color: Theme.barBg
            width: rightRow.implicitWidth + 16

            RowLayout {
                id: rightRow
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 4

                Tray {}
                Network {}
                Bluetooth {}
                RemindersIndicator {}
                TodosIndicator {}
                Clock {}
                Battery {}
            }
        }
    }
}
