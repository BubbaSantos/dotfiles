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

    property bool addingNew: false
    property string snoozingId: ""

    // Add form state
    property string newText: ""
    property int newHour: 9
    property int newMinute: 0
    property string newDate: ""   // ISO yyyy-mm-dd
    property string newRepeat: "none"
    property bool repeatDropdownOpen: false

    function open_() {
        addingNew = false
        snoozingId = ""
        TimepiecesStore.checkReminders()
        visible = true
    }
    function close() {
        visible = false
        addingNew = false
        snoozingId = ""
        repeatDropdownOpen = false
    }
    function toggle() { if (visible) close(); else open_() }

    function resetAddForm() {
        newText = ""
        const now = new Date()
        newHour = now.getHours()
        newMinute = Math.ceil(now.getMinutes() / 5) * 5
        if (newMinute >= 60) { newHour = (newHour + 1) % 24; newMinute = 0 }
        // Default date to today
        newDate = Qt.formatDate(now, "yyyy-MM-dd")
        newRepeat = "none"
        repeatDropdownOpen = false
    }

    function openAddForm() {
        resetAddForm()
        addingNew = true
    }

    function applyPreset(preset) {
        const now = new Date()
        if (preset === "15m") {
            const t = new Date(now.getTime() + 15 * 60000)
            newHour = t.getHours(); newMinute = t.getMinutes()
            newDate = Qt.formatDate(t, "yyyy-MM-dd")
        } else if (preset === "1h") {
            const t = new Date(now.getTime() + 60 * 60000)
            newHour = t.getHours(); newMinute = t.getMinutes()
            newDate = Qt.formatDate(t, "yyyy-MM-dd")
        } else if (preset === "tomorrow") {
            const t = new Date(now)
            t.setDate(t.getDate() + 1)
            t.setHours(9, 0, 0, 0)
            newHour = 9; newMinute = 0
            newDate = Qt.formatDate(t, "yyyy-MM-dd")
        } else if (preset === "tonight") {
            newHour = 20; newMinute = 0
            newDate = Qt.formatDate(now, "yyyy-MM-dd")
        }
    }

    function commitAdd() {
        if (!newText.trim()) return
        // Build ISO datetime from newDate + newHour:newMinute
        const dateParts = newDate.split("-")
        if (dateParts.length !== 3) return
        const dt = new Date(
            parseInt(dateParts[0]),
            parseInt(dateParts[1]) - 1,
            parseInt(dateParts[2]),
            newHour, newMinute, 0, 0
        )
        const next = TimepiecesStore.reminders.slice()
        next.push({
            id: Date.now() + "_" + Math.floor(Math.random() * 1000),
            text: newText.trim(),
            triggerAt: dt.toISOString(),
            repeat: newRepeat,
            state: "pending",
            firedAt: "",
            createdAt: new Date().toISOString()
        })
        TimepiecesStore.reminders = next
        TimepiecesStore.save()
        addingNew = false
    }

    function isoToUk(iso) {
        if (!iso || iso.length !== 10) return ""
        const parts = iso.split("-")
        return parts[2] + "/" + parts[1] + "/" + parts[0]
    }
    function ukToIso(uk) {
        if (!uk || uk.length !== 10) return ""
        const parts = uk.split("/")
        if (parts.length !== 3) return ""
        return parts[2] + "-" + parts[1] + "-" + parts[0]
    }

    function repeatLabelLong(r) {
        if (r === "daily") return "Daily"
        if (r === "weekdays") return "Weekdays"
        if (r === "weekly") return "Weekly"
        if (r === "monthly") return "Monthly"
        return "None"
    }

    readonly property var firedReminders: TimepiecesStore.reminders
        .filter(r => r.state === "fired")
        .sort((a, b) => new Date(a.firedAt) - new Date(b.firedAt))

    readonly property var upcomingReminders: TimepiecesStore.reminders
        .filter(r => r.state === "pending")
        .sort((a, b) => new Date(a.triggerAt) - new Date(b.triggerAt))

    function relativeTime(iso) {
        const target = new Date(iso)
        const now = new Date()
        const diffMs = target - now
        const diffMins = Math.round(diffMs / 60000)
        const diffHours = Math.round(diffMs / 3600000)
        const diffDays = Math.round(diffMs / 86400000)

        if (Math.abs(diffMins) < 1) return "now"
        if (diffMins < 0) {
            if (Math.abs(diffMins) < 60) return Math.abs(diffMins) + "m ago"
            if (Math.abs(diffHours) < 24) return Math.abs(diffHours) + "h ago"
            return Math.abs(diffDays) + "d ago"
        }
        if (diffMins < 60) return "in " + diffMins + "m"
        if (diffHours < 24) {
            const sameDay = target.getDate() === now.getDate() &&
                            target.getMonth() === now.getMonth() &&
                            target.getFullYear() === now.getFullYear()
            if (sameDay) return "in " + diffHours + "h"
            return "tomorrow at " + Qt.formatTime(target, "HH:mm")
        }
        if (diffDays < 7) return Qt.formatDate(target, "ddd") + " at " + Qt.formatTime(target, "HH:mm")
        return Qt.formatDate(target, "d MMM") + " at " + Qt.formatTime(target, "HH:mm")
    }

    function repeatLabel(r) {
        if (!r.repeat || r.repeat === "none") return ""
        if (r.repeat === "daily") return "↻ Daily"
        if (r.repeat === "weekdays") return "↻ Weekdays"
        if (r.repeat === "weekly") return "↻ Weekly"
        if (r.repeat === "monthly") return "↻ Monthly"
        return ""
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: card
        width: 460
        height: Math.min(cardCol.implicitHeight + 24, 640)

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
        clip: false

        opacity: root.visible ? 1 : 0
        scale: root.visible ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.snoozingId = ""
                root.repeatDropdownOpen = false
            }
        }

        Item {
            anchors.fill: parent
            focus: root.visible && !root.addingNew
            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) { root.close(); event.accepted = true }
            }
        }

        ColumnLayout {
            id: cardCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Reminders"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: 64
                    radius: 12
                    color: addBtnMouse.containsMouse ? Theme.brightYellow : Theme.yellow

                    Text {
                        anchors.centerIn: parent
                        text: "+ Add"
                        color: Theme.bg
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                    }

                    MouseArea {
                        id: addBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.addingNew) root.addingNew = false
                            else root.openAddForm()
                        }
                    }
                }

                Rectangle {
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: 24
                    radius: 12
                    color: closeMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"

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
            }

            // ---- ADD FORM ----
            Rectangle {
                id: addBox
                Layout.fillWidth: true
                Layout.preferredHeight: root.addingNew ? addCol.implicitHeight + 16 : 0
                visible: Layout.preferredHeight > 0
                clip: true
                radius: 6
                color: Qt.rgba(0, 0, 0, 0.25)

                Behavior on Layout.preferredHeight {
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }

                ColumnLayout {
                    id: addCol
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    // Text input
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        radius: 4
                        color: Qt.rgba(0, 0, 0, 0.3)
                        border.width: 1
                        border.color: addTextInput.activeFocus ? Theme.yellow : Qt.rgba(1, 1, 1, 0.08)

                        TextInput {
                            id: addTextInput
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            focus: root.addingNew
                            text: root.newText
                            onTextChanged: root.newText = text
                            Keys.onReturnPressed: root.commitAdd()
                            Keys.onEscapePressed: root.addingNew = false

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "Remind me to…"
                                color: Theme.fgVeryDim
                                font: parent.font
                                visible: !parent.text && !parent.activeFocus
                            }
                        }
                    }

                    // Quick presets
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Repeater {
                            model: [
                                { key: "15m", label: "In 15m" },
                                { key: "1h", label: "In 1h" },
                                { key: "tonight", label: "Tonight 8pm" },
                                { key: "tomorrow", label: "Tomorrow 9am" }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 22
                                radius: 4
                                color: presetMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.3)
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.08)
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                }

                                MouseArea {
                                    id: presetMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.applyPreset(modelData.key)
                                }
                            }
                        }
                    }

                    // Time + Date + Repeat row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        // Time spinner (hour:minute)
                        Rectangle {
                            Layout.preferredWidth: 110
                            Layout.preferredHeight: 30
                            radius: 4
                            color: Qt.rgba(0, 0, 0, 0.3)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.08)

                            RowLayout {
                                anchors.fill: parent
                                spacing: 0

                                // Hour
                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    Text {
                                        anchors.centerIn: parent
                                        text: ("0" + root.newHour).slice(-2)
                                        color: Theme.fg
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 14
                                        font.bold: true
                                    }

                                    // Up arrow
                                    Rectangle {
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.topMargin: 1
                                        anchors.rightMargin: 1
                                        width: 14; height: 12
                                        radius: 2
                                        color: hourUpMouse.containsMouse ? Qt.rgba(1,1,1,0.12) : "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: "▴"
                                            color: Theme.fgDim
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 8
                                        }
                                        MouseArea {
                                            id: hourUpMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.newHour = (root.newHour + 1) % 24
                                        }
                                    }
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        anchors.right: parent.right
                                        anchors.bottomMargin: 1
                                        anchors.rightMargin: 1
                                        width: 14; height: 12
                                        radius: 2
                                        color: hourDownMouse.containsMouse ? Qt.rgba(1,1,1,0.12) : "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: "▾"
                                            color: Theme.fgDim
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 8
                                        }
                                        MouseArea {
                                            id: hourDownMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.newHour = (root.newHour - 1 + 24) % 24
                                        }
                                    }
                                }

                                Text {
                                    text: ":"
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 14
                                    font.bold: true
                                }

                                // Minute
                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    Text {
                                        anchors.centerIn: parent
                                        text: ("0" + root.newMinute).slice(-2)
                                        color: Theme.fg
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 14
                                        font.bold: true
                                    }

                                    Rectangle {
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.topMargin: 1
                                        anchors.rightMargin: 1
                                        width: 14; height: 12
                                        radius: 2
                                        color: minUpMouse.containsMouse ? Qt.rgba(1,1,1,0.12) : "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: "▴"
                                            color: Theme.fgDim
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 8
                                        }
                                        MouseArea {
                                            id: minUpMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.newMinute = (root.newMinute + 5) % 60
                                            }
                                        }
                                    }
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        anchors.right: parent.right
                                        anchors.bottomMargin: 1
                                        anchors.rightMargin: 1
                                        width: 14; height: 12
                                        radius: 2
                                        color: minDownMouse.containsMouse ? Qt.rgba(1,1,1,0.12) : "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: "▾"
                                            color: Theme.fgDim
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 8
                                        }
                                        MouseArea {
                                            id: minDownMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.newMinute = (root.newMinute - 5 + 60) % 60
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Date input
                        Rectangle {
                            Layout.preferredWidth: 110
                            Layout.preferredHeight: 30
                            radius: 4
                            color: Qt.rgba(0, 0, 0, 0.3)
                            border.width: 1
                            border.color: dateInput.activeFocus ? Theme.yellow : Qt.rgba(1, 1, 1, 0.08)

                            TextInput {
                                id: dateInput
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                verticalAlignment: TextInput.AlignVCenter
                                horizontalAlignment: TextInput.AlignHCenter
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                text: root.isoToUk(root.newDate)
                                onTextChanged: {
                                    if (text.length === 10 && text.indexOf("/") === 2) {
                                        root.newDate = root.ukToIso(text)
                                    }
                                }
                                inputMask: "99/99/9999;_"

                                Text {
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    text: "dd/mm/yyyy"
                                    color: Theme.fgVeryDim
                                    font: parent.font
                                    visible: !parent.text && !parent.activeFocus
                                }
                            }
                        }

                        // Repeat dropdown
                        Item {
                            id: repeatField
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30
                            z: 5

                            Rectangle {
                                anchors.fill: parent
                                radius: 4
                                color: repeatMouse.containsMouse || root.repeatDropdownOpen
                                       ? Qt.rgba(1, 1, 1, 0.12)
                                       : Qt.rgba(0, 0, 0, 0.3)
                                border.width: 1
                                border.color: root.repeatDropdownOpen ? Theme.yellow : Qt.rgba(1, 1, 1, 0.08)
                                Behavior on color { ColorAnimation { duration: 150 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 4

                                    Text {
                                        text: "↻"
                                        color: root.newRepeat === "none" ? Theme.fgDim : Theme.blue
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                    }
                                    Text {
                                        text: root.repeatLabelLong(root.newRepeat)
                                        color: Theme.fg
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: "▾"
                                        color: Theme.fgDim
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                    }
                                }

                                MouseArea {
                                    id: repeatMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.repeatDropdownOpen = !root.repeatDropdownOpen
                                }
                            }
                        }
                    }

                    // Cancel / Add
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 2
                        spacing: 6

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            Layout.preferredHeight: 26
                            Layout.preferredWidth: 70
                            radius: 4
                            color: cancelMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.1)

                            Text {
                                anchors.centerIn: parent
                                text: "Cancel"
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                            }

                            MouseArea {
                                id: cancelMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.addingNew = false
                            }
                        }

                        Rectangle {
                            Layout.preferredHeight: 26
                            Layout.preferredWidth: 70
                            radius: 4
                            color: addCommitMouse.containsMouse ? Theme.brightYellow : Theme.yellow

                            Text {
                                anchors.centerIn: parent
                                text: "Add"
                                color: Theme.bg
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                            }

                            MouseArea {
                                id: addCommitMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.commitAdd()
                            }
                        }
                    }
                }
            }

            // Fired section
            Text {
                Layout.fillWidth: true
                visible: root.firedReminders.length > 0
                text: "Fired (" + root.firedReminders.length + ")"
                color: Theme.red
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                font.bold: true
            }

            ListView {
                id: firedList
                Layout.fillWidth: true
                Layout.preferredHeight: contentHeight
                visible: root.firedReminders.length > 0
                interactive: false
                model: root.firedReminders
                spacing: 4

                delegate: Rectangle {
                    id: firedDelegate
                    required property var modelData
                    width: firedList.width
                    height: root.snoozingId === modelData.id ? 72 : 44
                    radius: 6
                    color: Qt.rgba(251/255, 73/255, 52/255, 0.12)
                    border.width: 1
                    border.color: Qt.rgba(251/255, 73/255, 52/255, 0.4)
                    Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "󰂟"
                                color: Theme.red
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    text: firedDelegate.modelData.text
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: "Fired " + root.relativeTime(firedDelegate.modelData.firedAt)
                                    color: Theme.fgDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                }
                            }

                            Rectangle {
                                Layout.preferredHeight: 24
                                Layout.preferredWidth: 60
                                radius: 4
                                color: snoozeMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.25)
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.1)

                                Text {
                                    anchors.centerIn: parent
                                    text: "Snooze"
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                }

                                MouseArea {
                                    id: snoozeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.snoozingId = root.snoozingId === firedDelegate.modelData.id ? "" : firedDelegate.modelData.id
                                }
                            }

                            Rectangle {
                                Layout.preferredHeight: 24
                                Layout.preferredWidth: 64
                                radius: 4
                                color: dismissMouse.containsMouse ? Theme.brightYellow : Theme.yellow

                                Text {
                                    anchors.centerIn: parent
                                    text: "Dismiss"
                                    color: Theme.bg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: true
                                }

                                MouseArea {
                                    id: dismissMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: TimepiecesStore.dismissReminder(firedDelegate.modelData.id)
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            visible: root.snoozingId === firedDelegate.modelData.id
                            spacing: 4

                            Repeater {
                                model: [
                                    { mins: 5, label: "5m" },
                                    { mins: 10, label: "10m" },
                                    { mins: 15, label: "15m" },
                                    { mins: 30, label: "30m" },
                                    { mins: 60, label: "1h" },
                                    { mins: 1440, label: "Tomorrow" }
                                ]
                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 22
                                    radius: 4
                                    color: snoozeOptMouse.containsMouse ? Theme.yellow : Qt.rgba(0, 0, 0, 0.3)
                                    border.width: 1
                                    border.color: Qt.rgba(1, 1, 1, 0.08)
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: parent.modelData.label
                                        color: snoozeOptMouse.containsMouse ? Theme.bg : Theme.fg
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.bold: snoozeOptMouse.containsMouse
                                    }

                                    MouseArea {
                                        id: snoozeOptMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            TimepiecesStore.snoozeReminder(firedDelegate.modelData.id, parent.modelData.mins)
                                            root.snoozingId = ""
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.06)
                visible: root.firedReminders.length > 0 && root.upcomingReminders.length > 0
            }

            Text {
                Layout.fillWidth: true
                visible: root.upcomingReminders.length > 0
                text: "Upcoming (" + root.upcomingReminders.length + ")"
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
            }

            ListView {
                id: upcomingList
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 300)
                visible: root.upcomingReminders.length > 0
                clip: true
                model: root.upcomingReminders
                spacing: 2

                delegate: Rectangle {
                    required property var modelData
                    width: upcomingList.width
                    height: 36
                    radius: 4
                    color: rowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 6
                        spacing: 8

                        Text {
                            text: "󰂠"
                            color: Theme.fgDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                text: modelData.text
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            RowLayout {
                                spacing: 6
                                Text {
                                    text: root.relativeTime(modelData.triggerAt)
                                    color: Theme.fgDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                }
                                Text {
                                    text: root.repeatLabel(modelData)
                                    color: Theme.blue
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    visible: text.length > 0
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 18
                            Layout.preferredHeight: 18
                            radius: 9
                            color: delMouse.containsMouse ? Theme.red : "transparent"
                            opacity: rowMouse.containsMouse || delMouse.containsMouse ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: delMouse.containsMouse ? Theme.bg : Theme.fgDim
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                            }

                            MouseArea {
                                id: delMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: TimepiecesStore.deleteReminder(modelData.id)
                            }
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                        propagateComposedEvents: true
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: root.firedReminders.length === 0 && root.upcomingReminders.length === 0 && !root.addingNew
                text: "No reminders. Click + Add."
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                Layout.topMargin: 16
                Layout.bottomMargin: 16
            }

            Text {
                Layout.fillWidth: true
                text: "Enter to save · Esc to close"
                color: Theme.fgVeryDim
                font.family: Theme.fontFamily
                font.pixelSize: 9
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // -------- Floating repeat dropdown --------
        Rectangle {
            visible: root.repeatDropdownOpen
            x: {
                if (!repeatField.visible) return 0
                const p = repeatField.mapToItem(card, 0, 0)
                return p.x
            }
            y: {
                if (!repeatField.visible) return 0
                const p = repeatField.mapToItem(card, 0, 0)
                return p.y + repeatField.height + 4
            }
            width: repeatField.visible ? repeatField.width : 0
            height: repeatCol.implicitHeight + 8
            color: "#2a2a2a"
            radius: 8
            border.width: 1
            border.color: "#f38c6f"
            z: 1000

            ColumnLayout {
                id: repeatCol
                anchors.fill: parent
                anchors.margins: 4
                spacing: 0

                Repeater {
                    model: [
                        { key: "none", label: "None" },
                        { key: "daily", label: "Daily" },
                        { key: "weekdays", label: "Weekdays" },
                        { key: "weekly", label: "Weekly" },
                        { key: "monthly", label: "Monthly" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 26
                        radius: 4
                        color: repeatItemMouse.containsMouse
                               ? Qt.rgba(1, 1, 1, 0.12)
                               : (modelData.key === root.newRepeat ? Qt.rgba(1,1,1,0.06) : "transparent")
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 6

                            Text {
                                text: modelData.key === root.newRepeat ? "✓" : ""
                                color: Theme.yellow
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                Layout.preferredWidth: 10
                            }
                            Text {
                                text: modelData.label
                                color: modelData.key === root.newRepeat ? Theme.yellow : Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            id: repeatItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.newRepeat = modelData.key
                                root.repeatDropdownOpen = false
                            }
                        }
                    }
                }
            }
        }
    }
}
