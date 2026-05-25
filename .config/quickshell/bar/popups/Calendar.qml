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

    // Displayed month state (separate from today)
    property date today: new Date()
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()   // 0-11

    function toggle() {
        if (visible) close()
        else open_()
    }
    function open_() {
        today = new Date()
        viewYear = today.getFullYear()
        viewMonth = today.getMonth()
        visible = true
    }
    function close() { visible = false }

    function prevMonth() {
        if (viewMonth === 0) {
            viewMonth = 11
            viewYear -= 1
        } else {
            viewMonth -= 1
        }
    }
    function nextMonth() {
        if (viewMonth === 11) {
            viewMonth = 0
            viewYear += 1
        } else {
            viewMonth += 1
        }
    }
    function goToday() {
        viewYear = today.getFullYear()
        viewMonth = today.getMonth()
    }

    readonly property string monthLabel: {
        const d = new Date(viewYear, viewMonth, 1)
        return Qt.formatDate(d, "MMMM yyyy")
    }

    // Build a 6-row x 7-col grid of dates for the current view month
    // Week starts on Monday
    readonly property var monthGrid: {
        const firstOfMonth = new Date(viewYear, viewMonth, 1)
        // Day of week (0=Sun..6=Sat). Convert to Mon=0..Sun=6
        const firstDow = (firstOfMonth.getDay() + 6) % 7
        const daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate()
        const daysInPrev = new Date(viewYear, viewMonth, 0).getDate()

        const cells = []
        // Leading cells from previous month
        for (let i = firstDow - 1; i >= 0; i--) {
            cells.push({ day: daysInPrev - i, inMonth: false, isToday: false })
        }
        // Current month
        for (let d = 1; d <= daysInMonth; d++) {
            const isToday = (d === today.getDate()
                             && viewMonth === today.getMonth()
                             && viewYear === today.getFullYear())
            cells.push({ day: d, inMonth: true, isToday: isToday })
        }
        // Trailing cells to fill 42 (6 weeks)
        let nextDay = 1
        while (cells.length < 42) {
            cells.push({ day: nextDay++, inMonth: false, isToday: false })
        }
        return cells
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: card
        width: 360
        height: cardCol.implicitHeight + 24

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
                if (event.key === Qt.Key_Escape) { root.close(); event.accepted = true }
                else if (event.key === Qt.Key_Left) { root.prevMonth(); event.accepted = true }
                else if (event.key === Qt.Key_Right) { root.nextMonth(); event.accepted = true }
                else if (event.key === Qt.Key_T) { root.goToday(); event.accepted = true }
            }
        }

        // X close
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 8
            anchors.rightMargin: 8
            width: 20; height: 20; radius: 10
            color: closeMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
            z: 2
            Behavior on color { ColorAnimation { duration: Theme.animFast } }

            Text {
                anchors.centerIn: parent
                text: "✕"
                color: closeMouse.containsMouse ? Theme.fg : Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: 12
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
            id: cardCol
            anchors.fill: parent
            anchors.margins: 12
            anchors.topMargin: 12
            anchors.rightMargin: 36
            spacing: 10

            // Month navigation row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    radius: 6
                    color: prevMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Text {
                        anchors.centerIn: parent
                        text: "‹"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                    }
                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.prevMonth()
                    }
                }

                Text {
                    text: root.monthLabel
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.goToday()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    radius: 6
                    color: nextMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Text {
                        anchors.centerIn: parent
                        text: "›"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                    }
                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.nextMonth()
                    }
                }
            }

            // Day-of-week header
            GridLayout {
                Layout.fillWidth: true
                columns: 7
                columnSpacing: 0
                rowSpacing: 0

                Repeater {
                    model: ["Mo","Tu","We","Th","Fr","Sa","Su"]
                    delegate: Item {
                        required property string modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 18
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: Theme.fgDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }
                    }
                }
            }

            // Date grid
            GridLayout {
                Layout.fillWidth: true
                columns: 7
                columnSpacing: 2
                rowSpacing: 2

                Repeater {
                    model: root.monthGrid

                    delegate: Item {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30

                        Rectangle {
                            anchors.centerIn: parent
                            width: 28
                            height: 28
                            radius: 14
                            color: modelData.isToday ? Theme.yellow : "transparent"
                            border.width: dayMouse.containsMouse && !modelData.isToday ? 1 : 0
                            border.color: Qt.rgba(1, 1, 1, 0.2)

                            Text {
                                anchors.centerIn: parent
                                text: modelData.day
                                color: modelData.isToday ? Theme.bg
                                       : modelData.inMonth ? Theme.fg : Theme.fgVeryDim
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: modelData.isToday
                            }
                        }

                        MouseArea {
                            id: dayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 4
                height: 1
                color: Qt.rgba(1, 1, 1, 0.06)
            }

            // Tool launcher grid
            GridLayout {
                Layout.fillWidth: true
                columns: 3
                columnSpacing: 6
                rowSpacing: 6

                Repeater {
                    model: [
                        { label: "Todos",     icon: "󰄬", target: "todos" },
                        { label: "Reminders", icon: "󰂟", target: "reminders" },
                        { label: "Pomodoro",  icon: "󰔟", target: "pomodoro" },
                        { label: "Stopwatch", icon: "󰓅", target: "stopwatch" },
                        { label: "Timer",     icon: "󰔛", target: "timer" }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        radius: 8
                        color: launcherMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.15)
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.icon
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 16
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.label
                                color: Theme.fgDim
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                            }
                        }

                        MouseArea {
                            id: launcherMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.close()
                                if (modelData.target === "todos") todosPopup.open_()
                                else if (modelData.target === "reminders") remindersPopup.open_()
                                else if (modelData.target === "pomodoro") pomodoroPopup.open_()
                                else if (modelData.target === "stopwatch") stopwatchPopup.open_()
                                else if (modelData.target === "timer") timerPopup.open_()
                            }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: "← → months · T today · Esc close"
                color: Theme.fgVeryDim
                font.family: Theme.fontFamily
                font.pixelSize: 9
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    // Sub-popups, anchored to the same item as Calendar
    Todos { id: todosPopup; anchorItem: root.anchorItem }
    Reminders { id: remindersPopup; anchorItem: root.anchorItem }
    Pomodoro { id: pomodoroPopup; anchorItem: root.anchorItem }
    Stopwatch { id: stopwatchPopup; anchorItem: root.anchorItem }
    TimerPopup { id: timerPopup; anchorItem: root.anchorItem }
}
