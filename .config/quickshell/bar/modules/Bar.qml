import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.services

PanelWindow {
    id: bar
    color: "transparent"

    anchors.top:    SettingsStore.barPosition === "top"
    anchors.bottom: SettingsStore.barPosition === "bottom"
    anchors.left:  true
    anchors.right: true

    implicitHeight: Theme.barHeight + Theme.barMargin

    // ── Unified full-width background (only in unified mode) ───────────
    Rectangle {
        visible: SettingsStore.barStyle === "unified"
        anchors.fill: parent
        anchors.topMargin:    SettingsStore.barPosition === "top"    ? Theme.barMargin : 1
        anchors.bottomMargin: SettingsStore.barPosition === "bottom" ? Theme.barMargin : 1
        anchors.leftMargin:  2
        anchors.rightMargin: 2
        radius: Theme.groupRadius
        color: Theme.barBg
    }

    Item {
        anchors.fill: parent
        anchors.topMargin:    SettingsStore.barPosition === "top"    ? 3 : 1
        anchors.bottomMargin: SettingsStore.barPosition === "bottom" ? 3 : 1
        anchors.leftMargin:  SettingsStore.barStyle === "floating" ? Theme.barMargin : 4
        anchors.rightMargin: SettingsStore.barStyle === "floating" ? Theme.barMargin : 4

        // LEFT GROUP
        Rectangle {
            id: leftGroup
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: Theme.barHeight - 4
            radius: SettingsStore.barStyle === "floating" ? Theme.groupRadius : 0
            color: SettingsStore.barStyle === "floating" ? Theme.barBg : "transparent"
            width: leftRow.implicitWidth + (SettingsStore.barStyle === "floating" ? 16 : 8)
            visible: SettingsStore.showNowPlaying

            RowLayout {
                id: leftRow
                anchors.fill: parent
                anchors.leftMargin: SettingsStore.barStyle === "floating" ? 8 : 4
                anchors.rightMargin: SettingsStore.barStyle === "floating" ? 8 : 4
                spacing: 0
                NowPlaying {}
            }
        }

        // CENTER GROUP
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            height: Theme.barHeight - 4
            radius: SettingsStore.barStyle === "floating" ? Theme.groupRadius : 0
            color: SettingsStore.barStyle === "floating" ? Theme.barBg : "transparent"
            width: centerRow.implicitWidth + 8

            RowLayout {
                id: centerRow
                anchors.centerIn: parent
                spacing: 0
                Workspaces {}
            }
        }

        // RIGHT GROUP
        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: Theme.barHeight - 4
            radius: SettingsStore.barStyle === "floating" ? Theme.groupRadius : 0
            color: SettingsStore.barStyle === "floating" ? Theme.barBg : "transparent"
            width: rightRow.implicitWidth + (SettingsStore.barStyle === "floating" ? 16 : 8)

            RowLayout {
                id: rightRow
                anchors.fill: parent
                anchors.leftMargin: SettingsStore.barStyle === "floating" ? 8 : 4
                anchors.rightMargin: SettingsStore.barStyle === "floating" ? 8 : 4
                spacing: 4

                Tray              { visible: SettingsStore.showTray          }
                Network           { visible: SettingsStore.showNetwork       }
                Bluetooth         { visible: SettingsStore.showBluetooth     }
                RemindersIndicator{ visible: SettingsStore.showReminders     }
                TodosIndicator    { visible: SettingsStore.showTodos         }
                NotifIndicator    { visible: SettingsStore.showNotifications }
                Clock             { visible: SettingsStore.showClock         }
                Battery           { visible: SettingsStore.showBattery       }
            }
        }
    }
}
