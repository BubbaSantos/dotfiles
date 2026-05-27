import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.popups

PanelWindow {
    id: bar
    color: "transparent"

    anchors.top:    SettingsStore.barPosition === "top"
    anchors.bottom: SettingsStore.barPosition === "bottom"
    anchors.left:  true
    anchors.right: true

    implicitHeight: Theme.barHeight + Theme.barMargin

    BrightnessSlider { id: brightnessOSD }

    // ── Module components (always instantiated so services keep running) ──
    Component { id: trayComp;    Tray              {} }
    Component { id: networkComp; Network           {} }
    Component { id: btComp;      Bluetooth         {} }
    Component { id: remComp;     RemindersIndicator {} }
    Component { id: todoComp;    TodosIndicator    {} }
    Component { id: notifComp;   NotifIndicator    {} }
    Component { id: clockComp;   Clock             {} }
    Component { id: battComp;    Battery           {} }

    function moduleComponent(name) {
        switch(name) {
            case "Tray":          return trayComp
            case "Network":       return networkComp
            case "Bluetooth":     return btComp
            case "Reminders":     return remComp
            case "Todos":         return todoComp
            case "Notifications": return notifComp
            case "Clock":         return clockComp
            case "Battery":       return battComp
            default: return null
        }
    }

    function moduleVisible(name) {
        switch(name) {
            case "Tray":          return SettingsStore.showTray
            case "Network":       return SettingsStore.showNetwork
            case "Bluetooth":     return SettingsStore.showBluetooth
            case "Reminders":     return SettingsStore.showReminders
            case "Todos":         return SettingsStore.showTodos
            case "Notifications": return SettingsStore.showNotifications
            case "Clock":         return SettingsStore.showClock
            case "Battery":       return SettingsStore.showBattery
            default: return true
        }
    }

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

                Repeater {
                    model: SettingsStore.rightModuleOrder
                    delegate: Loader {
                        id: modLoader
                        required property string modelData
                        required property int index

                        visible: bar.moduleVisible(modelData)
                        sourceComponent: bar.moduleComponent(modelData)
                        Layout.preferredHeight: 22

                        Binding {
                            target: modLoader
                            property: "Layout.preferredWidth"
                            value: modLoader.item ? modLoader.item.Layout.preferredWidth : 0
                            when: modLoader.status === Loader.Ready
                        }
                    }
                }
            }
        }
    }
}
