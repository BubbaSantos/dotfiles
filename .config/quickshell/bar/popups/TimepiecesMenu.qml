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

    function toggle() { visible = !visible }
    function close()  { visible = false }

    readonly property var items: [
        { label: "Calendar",   icon: "󰸗", key: "calendar" },
        { label: "Todos",      icon: "󰄬", key: "todos" },
        { label: "Reminders",  icon: "󰂟", key: "reminders" },
        { label: "Pomodoro",   icon: "󰔟", key: "pomodoro" },
        { label: "Stopwatch",  icon: "󰓅", key: "stopwatch" },
        { label: "Timer",      icon: "󰔛", key: "timer" }
    ]

    function openItem(key) {
        root.close()
        // These IDs reference popups declared below
        if (key === "calendar") calendarPopup.toggle()
        else if (key === "todos") todosPopup.toggle()
        else if (key === "reminders") remindersPopup.toggle()
        else if (key === "pomodoro") pomodoroPopup.toggle()
        else if (key === "stopwatch") stopwatchPopup.toggle()
        else if (key === "timer") timerPopup.toggle()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: card
        width: 240
        height: menuColumn.implicitHeight + 24

        x: {
            if (!root.anchorItem) return 20
            const p = root.anchorItem.mapToItem(null, 0, 0)
            const desired = p.x + (root.anchorItem.width / 2) - (width / 2)
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

        Item {
            anchors.fill: parent
            focus: root.visible
            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) {
                    root.close()
                    event.accepted = true
                }
            }
        }

        ColumnLayout {
            id: menuColumn
            anchors.fill: parent
            anchors.margins: 8
            spacing: 2

            Repeater {
                model: root.items

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: 6
                    color: itemMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        Text {
                            text: modelData.icon
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                        }
                        Text {
                            text: modelData.label
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openItem(modelData.key)
                    }
                }
            }
        }
    }

    // Sub-popups (these will be stub-anchored to the clock for now)
    Calendar { id: calendarPopup; anchorItem: root.anchorItem }
    // The others get added as we build them. For now, alias them to calendar
    // so the menu compiles. Replace these as we create real popups.
    Calendar { id: todosPopup; anchorItem: root.anchorItem }
    Calendar { id: remindersPopup; anchorItem: root.anchorItem }
    Calendar { id: pomodoroPopup; anchorItem: root.anchorItem }
    Calendar { id: stopwatchPopup; anchorItem: root.anchorItem }
    Calendar { id: timerPopup; anchorItem: root.anchorItem }
}
