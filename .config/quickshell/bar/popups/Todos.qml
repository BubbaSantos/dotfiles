import "."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
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

    readonly property string completeSoundPath: "/usr/share/sounds/freedesktop/stereo/complete.oga"

    property string activeCategory: "All"
    property bool showDone: false
    property bool addingNew: false
    property string newText: ""
    property int newPriority: 0
    property string newCategory: ""
    property string newDueDate: ""
    property bool newCategoryAddMode: false
    property string editingId: ""
    property bool showSettings: false

    property bool filterDropdownOpen: false
    property bool newCatDropdownOpen: false
    property int  filterDropdownIndex: 0
    property int  editPriority: 0
    property string editCategory: ""
    property string editDueDate: ""

    onFilterDropdownOpenChanged: {
        if (filterDropdownOpen) {
            filterDropdownIndex = filterCategories.indexOf(activeCategory)
            if (filterDropdownIndex < 0) filterDropdownIndex = 0
        }
    }

    onActiveCategoryChanged: {
        if (addingNew) newCategory = activeCategory === "All" ? "" : activeCategory
    }

    // Keyboard focus: zone = "active" | "done" | "header"
    property string focusZone: "active"
    property int focusIndex: 0   // index into the current zone's items
    // Header zone has 3 buttons in order: 0 = Add, 1 = Settings, 2 = Close

    function open_() {
        addingNew = false
        newText = ""
        newPriority = 0
        newCategory = activeCategory === "All" ? "" : activeCategory
        newDueDate = ""
        newCategoryAddMode = false
        editingId = ""
        filterDropdownOpen = false
        newCatDropdownOpen = false
        showSettings = false
        editPriority = 0
        editCategory = ""
        editDueDate = ""
        focusZone = activeTodos.length > 0 ? "active" : "header"
        focusIndex = 0
        visible = true
    }
    function close() {
        visible = false
        addingNew = false
        editingId = ""
        filterDropdownOpen = false
        newCatDropdownOpen = false
        showSettings = false
    }
    function toggle() { if (visible) close(); else open_() }

    onVisibleChanged: if (visible) PopupManager.open(root)

    readonly property var allCategoryNames: {
        const set = new Set(["Work", "Personal"])
        for (const t of TimepiecesStore.todos) {
            if (t.category) set.add(t.category)
        }
        return Array.from(set).sort()
    }
    readonly property var filterCategories: ["All", ...allCategoryNames]

    function filtered(includeDone) {
        const result = TimepiecesStore.todos.filter(t => {
            if (!includeDone && t.done) return false
            if (includeDone && !t.done) return false
            if (activeCategory === "All") return true
            return (t.category || "") === activeCategory
        })
        return result.slice().sort((a, b) => {
            if (TimepiecesStore.todosPriorityFirst) {
                const diff = (b.priority || 0) - (a.priority || 0)
                if (diff !== 0) return diff
            }
            const s = TimepiecesStore.todosSort
            if (s === "newestFirst") return new Date(b.createdAt || 0) - new Date(a.createdAt || 0)
            if (s === "oldestFirst") return new Date(a.createdAt || 0) - new Date(b.createdAt || 0)
            return (a.order || 0) - (b.order || 0)
        })
    }

    readonly property var activeTodos: filtered(false)
    readonly property var doneTodos: filtered(true)

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

    function addTodo() {
        if (!newText.trim()) return
        const next = TimepiecesStore.todos.slice()
        next.push({
            id: Date.now() + "_" + Math.floor(Math.random() * 1000),
            text: newText.trim(),
            done: false,
            priority: newPriority,
            category: newCategory || "",
            dueDate: newDueDate || "",
            createdAt: new Date().toISOString(),
            order: next.length
        })
        TimepiecesStore.todos = next
        TimepiecesStore.save()
        newText = ""
        newPriority = 0
        newDueDate = ""
        newCategoryAddMode = false
        addingNew = false
    }

    function toggleTodo(id) {
        let becameDone = false
        const next = TimepiecesStore.todos.map(t => {
            if (t.id === id) {
                if (!t.done) becameDone = true
                return Object.assign({}, t, { done: !t.done })
            }
            return t
        })
        TimepiecesStore.todos = next
        TimepiecesStore.save()
        if (becameDone) soundProc.running = true
    }

    function saveTodo(id, newTextVal) {
        if (!newTextVal.trim()) return
        TimepiecesStore.todos = TimepiecesStore.todos.map(t =>
            t.id === id ? Object.assign({}, t, {
                text:     newTextVal.trim(),
                priority: editPriority,
                category: editCategory,
                dueDate:  editDueDate
            }) : t)
        TimepiecesStore.save()
        editingId = ""
    }

    function startEditing(todo) {
        editPriority = todo.priority || 0
        editCategory = todo.category || ""
        editDueDate  = todo.dueDate  || ""
        editingId    = todo.id
    }

    function deleteTodo(id) {
        TimepiecesStore.todos = TimepiecesStore.todos.filter(t => t.id !== id)
        TimepiecesStore.save()
    }

    function moveTodo(fromId, toId) {
        if (fromId === toId) return
        const arr = TimepiecesStore.todos.slice()
        const fromIdx = arr.findIndex(t => t.id === fromId)
        const toIdx = arr.findIndex(t => t.id === toId)
        if (fromIdx === -1 || toIdx === -1) return
        const [moved] = arr.splice(fromIdx, 1)
        arr.splice(toIdx, 0, moved)
        for (let i = 0; i < arr.length; i++) arr[i].order = i
        TimepiecesStore.todos = arr
        TimepiecesStore.save()
    }

    // ---- Keyboard navigation helpers ----

    function zoneItems(zone) {
        if (zone === "active") return activeTodos
        if (zone === "done") return doneTodos
        if (zone === "header") return [0, 1, 2]
        return []
    }

    function clampFocus() {
        const items = zoneItems(focusZone)
        if (items.length === 0) {
            // Try to find a populated zone
            if (activeTodos.length > 0) { focusZone = "active"; focusIndex = 0 }
            else if (showDone && doneTodos.length > 0) { focusZone = "done"; focusIndex = 0 }
            else { focusZone = "header"; focusIndex = 0 }
            return
        }
        if (focusIndex >= items.length) focusIndex = items.length - 1
        if (focusIndex < 0) focusIndex = 0
    }

    function nextZone() {
        if (focusZone === "active") {
            if (showDone && doneTodos.length > 0) focusZone = "done"
            else focusZone = "header"
        } else if (focusZone === "done") {
            focusZone = "header"
        } else {
            focusZone = activeTodos.length > 0 ? "active" : (showDone && doneTodos.length > 0 ? "done" : "header")
        }
        focusIndex = 0
    }

    function prevZone() {
        if (focusZone === "header") {
            if (showDone && doneTodos.length > 0) focusZone = "done"
            else focusZone = activeTodos.length > 0 ? "active" : "header"
        } else if (focusZone === "done") {
            focusZone = activeTodos.length > 0 ? "active" : "header"
        } else {
            focusZone = "header"
        }
        focusIndex = 0
    }

    function focusedTodoId() {
        const items = zoneItems(focusZone)
        if (focusZone === "header") return ""
        if (items.length === 0) return ""
        return items[focusIndex] ? items[focusIndex].id : ""
    }

    function reorderKeyboard(delta) {
        // delta = -1 (up) or +1 (down)
        if (focusZone !== "active") return
        if (TimepiecesStore.todosSort !== "manual") return
        const id = focusedTodoId()
        if (!id) return
        const idx = activeTodos.findIndex(t => t.id === id)
        const targetIdx = idx + delta
        if (targetIdx < 0 || targetIdx >= activeTodos.length) return
        const targetId = activeTodos[targetIdx].id
        moveTodo(id, targetId)
        focusIndex = targetIdx
    }

    function activateFocused() {
        // Called on Enter
        if (focusZone === "header") {
            if (focusIndex === 0) {
                addingNew = !addingNew
                if (addingNew) newCategory = activeCategory === "All" ? "" : activeCategory
            }
            else if (focusIndex === 1) showSettings = !showSettings
            else if (focusIndex === 2) close()
            return
        }
        const items = zoneItems(focusZone)
        const todo = items[focusIndex]
        if (todo) root.startEditing(todo)
    }

    function spaceFocused() {
        if (focusZone === "header") return
        const id = focusedTodoId()
        if (id) toggleTodo(id)
    }

    function deleteFocused() {
        if (focusZone === "header") return
        const id = focusedTodoId()
        if (id) {
            deleteTodo(id)
            clampFocus()
        }
    }

    function priorityColor(p) {
        if (p === 3) return Theme.red
        if (p === 2) return Theme.brightYellow
        if (p === 1) return Theme.blue
        return "transparent"
    }

    function dueLabel(iso) {
        if (!iso) return ""
        const due = new Date(iso + "T00:00:00")
        const today = new Date()
        today.setHours(0,0,0,0)
        const diffDays = Math.round((due - today) / (1000 * 60 * 60 * 24))
        if (diffDays === 0) return "Today"
        if (diffDays === 1) return "Tomorrow"
        if (diffDays === -1) return "Yesterday"
        if (diffDays < 0) return Math.abs(diffDays) + "d ago"
        if (diffDays < 7) return Qt.formatDate(due, "ddd")
        return Qt.formatDate(due, "d MMM")
    }

    function dueColor(iso) {
        if (!iso) return Theme.fgDim
        const due = new Date(iso + "T00:00:00")
        const today = new Date()
        today.setHours(0,0,0,0)
        if (due < today) return Theme.red
        if (due.getTime() === today.getTime()) return Theme.brightYellow
        return Theme.fgDim
    }

    Process {
        id: soundProc
        command: ["paplay", root.completeSoundPath]
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: card
        width: 440
        height: Math.min(cardCol.implicitHeight + 24, 620)

        x: {
            if (!root.anchorItem) return 20
            const p = root.anchorItem.mapToItem(null, 0, 0)
            const desired = p.x + (root.anchorItem.width / 2) - (width / 2)
            return Math.max(8, Math.min(root.width - width - 8, desired))
        }
        y: 0

        color: Theme.popupBg
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
                root.filterDropdownOpen = false
                root.newCatDropdownOpen = false
            }
        }

        HoverHandler {
            onHoveredChanged: {
                if (!hovered) autoCloseTimer.restart()
                else autoCloseTimer.stop()
            }
        }
        Timer { id: autoCloseTimer; interval: 2000; onTriggered: root.close() }

        Item {
            anchors.fill: parent
            focus: root.visible && !root.addingNew && root.editingId === ""
            Keys.onPressed: function(event) {
                if (root.filterDropdownOpen) {
                    if (event.key === Qt.Key_Escape) {
                        root.filterDropdownOpen = false
                    } else if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
                        root.filterDropdownIndex = Math.min(root.filterDropdownIndex + 1, root.filterCategories.length - 1)
                    } else if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
                        root.filterDropdownIndex = Math.max(root.filterDropdownIndex - 1, 0)
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.activeCategory = root.filterCategories[root.filterDropdownIndex]
                        root.filterDropdownOpen = false
                    }
                    event.accepted = true
                    return
                }
                if (event.key === Qt.Key_Escape) {
                    root.close()
                    event.accepted = true
                }
                else if (event.key === Qt.Key_N && (event.modifiers & Qt.ControlModifier)) {
                    root.addingNew = true
                    root.newCategory = root.activeCategory === "All" ? "" : root.activeCategory
                    event.accepted = true
                }
                else if (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier)) {
                    root.nextZone()
                    event.accepted = true
                }
                else if (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier)) {
                    root.prevZone()
                    event.accepted = true
                }
                else if (event.key === Qt.Key_Down) {
                    if (event.modifiers & Qt.ShiftModifier) {
                        root.reorderKeyboard(1)
                    } else {
                        const items = root.zoneItems(root.focusZone)
                        if (root.focusIndex < items.length - 1) root.focusIndex++
                        else root.nextZone()
                    }
                    event.accepted = true
                }
                else if (event.key === Qt.Key_Up) {
                    if (event.modifiers & Qt.ShiftModifier) {
                        root.reorderKeyboard(-1)
                    } else {
                        if (root.focusIndex > 0) root.focusIndex--
                        else {
                            // Go to previous zone, focus last item
                            root.prevZone()
                            const items = root.zoneItems(root.focusZone)
                            root.focusIndex = Math.max(0, items.length - 1)
                        }
                    }
                    event.accepted = true
                }
                else if (event.key === Qt.Key_J && !(event.modifiers & Qt.ShiftModifier)) {
                    const items = root.zoneItems(root.focusZone)
                    if (root.focusIndex < items.length - 1) root.focusIndex++
                    else root.nextZone()
                    event.accepted = true
                }
                else if (event.key === Qt.Key_K && !(event.modifiers & Qt.ShiftModifier)) {
                    if (root.focusIndex > 0) root.focusIndex--
                    else {
                        root.prevZone()
                        const items = root.zoneItems(root.focusZone)
                        root.focusIndex = Math.max(0, items.length - 1)
                    }
                    event.accepted = true
                }
                else if (event.key === Qt.Key_Left && root.focusZone === "header") {
                    if (root.focusIndex > 0) root.focusIndex--
                    event.accepted = true
                }
                else if (event.key === Qt.Key_Right && root.focusZone === "header") {
                    if (root.focusIndex < 2) root.focusIndex++
                    event.accepted = true
                }
                else if (event.key === Qt.Key_Space) {
                    root.spaceFocused()
                    event.accepted = true
                }
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.activateFocused()
                    event.accepted = true
                }
                else if (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) {
                    root.deleteFocused()
                    event.accepted = true
                }
                else if (event.key === Qt.Key_D && !(event.modifiers & Qt.ControlModifier)) {
                    root.showDone = !root.showDone
                    event.accepted = true
                }
                else if (event.key === Qt.Key_F && !(event.modifiers & Qt.ControlModifier)) {
                    root.filterDropdownOpen = !root.filterDropdownOpen
                    event.accepted = true
                }
            }
        }

        

        ColumnLayout {
            id: cardCol
            anchors.fill: parent
            anchors.margins: 12
            anchors.topMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Todos"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.bold: true
                }

                Rectangle {
                    id: filterPill
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: filterRow.implicitWidth + 18
                    radius: 12
                    color: filterMouse.containsMouse || root.filterDropdownOpen
                           ? Qt.rgba(1, 1, 1, 0.15)
                           : Qt.rgba(0, 0, 0, 0.35)
                    border.width: 1
                    border.color: root.filterDropdownOpen ? Theme.yellow : Qt.rgba(1, 1, 1, 0.1)
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                    RowLayout {
                        id: filterRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: root.activeCategory
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Text {
                            text: "▾"
                            color: Theme.fgDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                        }
                    }

                    MouseArea {
                        id: filterMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.newCatDropdownOpen = false
                            root.filterDropdownOpen = !root.filterDropdownOpen
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: 64
                    radius: 12
                    color: addBtnMouse.containsMouse ? Theme.brightYellow : Theme.yellow
                    border.width: root.focusZone === "header" && root.focusIndex === 0 ? 2 : 0
                    border.color: Theme.fg
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

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
                            root.addingNew = !root.addingNew
                            if (root.addingNew) {
                                root.newCategory = root.activeCategory === "All" ? "" : root.activeCategory
                                root.newCategoryAddMode = false
                            }
                        }
                    }
                  }

                // Settings gear
                Rectangle {
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: 24
                    radius: 12
                    color: settingsMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                    border.width: root.focusZone === "header" && root.focusIndex === 1 ? 1 : 0
                    border.color: Theme.yellow
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰒓"
                        color: root.showSettings ? Theme.yellow
                               : (settingsMouse.containsMouse ? Theme.fg : Theme.fgDim)
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }
                    MouseArea {
                        id: settingsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.showSettings = !root.showSettings
                    }
                }

                // X close
                Rectangle {
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: 24
                    radius: 12
                    color: closeMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                    border.width: root.focusZone === "header" && root.focusIndex === 2 ? 1 : 0
                    border.color: Theme.yellow
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
            }

            // Add form
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: root.addingNew ? addCol.implicitHeight + 16 : 0
                visible: Layout.preferredHeight > 0
                clip: true
                radius: 6
                color: Qt.rgba(0, 0, 0, 0.25)

                Behavior on Layout.preferredHeight {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                onVisibleChanged: {
                    if (visible) addCatInput.text = root.newCategory
                }

                ColumnLayout {
                    id: addCol
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        radius: 4
                        color: Qt.rgba(0, 0, 0, 0.3)
                        border.width: 1
                        border.color: addInput.activeFocus ? Theme.yellow : Qt.rgba(1, 1, 1, 0.08)

                        TextInput {
                            id: addInput
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
                            KeyNavigation.tab: priorityFocus
                            Keys.onReturnPressed: root.addTodo()
                            Keys.onEscapePressed: root.addingNew = false

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "What needs doing?"
                                color: Theme.fgVeryDim
                                font: parent.font
                                visible: !parent.text && !parent.activeFocus
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        FocusScope {
                            id: priorityFocus
                            Layout.preferredWidth: 130
                            Layout.preferredHeight: 24
                            activeFocusOnTab: true
                            KeyNavigation.backtab: addInput
                            KeyNavigation.tab: addCatInput

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: -2
                                radius: 5
                                color: "transparent"
                                border.width: priorityFocus.activeFocus ? 1 : 0
                                border.color: Theme.yellow
                            }

                            Keys.onPressed: function(event) {
                                if (event.key === Qt.Key_Right) {
                                    root.newPriority = Math.min(3, root.newPriority + 1)
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Left) {
                                    root.newPriority = Math.max(0, root.newPriority - 1)
                                    event.accepted = true
                                } else if (event.key === Qt.Key_0) { root.newPriority = 0; event.accepted = true }
                                else if (event.key === Qt.Key_1) { root.newPriority = 1; event.accepted = true }
                                else if (event.key === Qt.Key_2) { root.newPriority = 2; event.accepted = true }
                                else if (event.key === Qt.Key_3) { root.newPriority = 3; event.accepted = true }
                                else if (event.key === Qt.Key_Return) { root.addTodo(); event.accepted = true }
                                else if (event.key === Qt.Key_Escape) { root.addingNew = false; event.accepted = true }
                            }

                            RowLayout {
                                anchors.fill: parent
                                spacing: 6

                                Repeater {
                                    model: [
                                        { p: 0, label: "—" },
                                        { p: 1, label: "L" },
                                        { p: 2, label: "M" },
                                        { p: 3, label: "H" }
                                    ]
                                    delegate: Rectangle {
                                        required property var modelData
                                        Layout.preferredHeight: 24
                                        Layout.preferredWidth: 28
                                        radius: 4
                                        color: root.newPriority === modelData.p
                                               ? root.priorityColor(modelData.p) === "transparent"
                                                 ? Qt.rgba(1, 1, 1, 0.18)
                                                 : root.priorityColor(modelData.p)
                                               : Qt.rgba(0, 0, 0, 0.3)
                                        border.width: 1
                                        border.color: root.newPriority === modelData.p
                                                      ? Qt.rgba(1, 1, 1, 0.3)
                                                      : Qt.rgba(1, 1, 1, 0.05)
                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            color: root.newPriority === modelData.p && modelData.p > 0
                                                   ? Theme.bg : Theme.fg
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
                                            font.bold: true
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.newPriority = modelData.p
                                                priorityFocus.forceActiveFocus()
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Item { Layout.preferredWidth: 4 }

                        Item {
                            id: newCatField
                            Layout.fillWidth: true
                            Layout.preferredHeight: 24

                            Rectangle {
                                anchors.fill: parent
                                radius: 4
                                color: Qt.rgba(0, 0, 0, 0.3)
                                border.width: 1
                                border.color: addCatInput.activeFocus || root.newCatDropdownOpen
                                              ? Theme.yellow : Qt.rgba(1, 1, 1, 0.08)
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 2
                                    spacing: 0

                                    TextInput {
                                        id: addCatInput
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Theme.fg
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        selectByMouse: true
                                        onTextChanged: root.newCategory = text
                                        KeyNavigation.tab: dateInput
                                        KeyNavigation.backtab: priorityFocus
                                        Keys.onReturnPressed: root.addTodo()
                                        Keys.onEscapePressed: root.addingNew = false

                                        Text {
                                            anchors.fill: parent
                                            verticalAlignment: Text.AlignVCenter
                                            text: "Category"
                                            color: Theme.fgVeryDim
                                            font: parent.font
                                            visible: !parent.text && !parent.activeFocus
                                        }
                                    }

                                    Text {
                                        text: "▾"
                                        color: catDropBtnMouse.containsMouse ? Theme.fg : Theme.fgDim
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                        Layout.preferredWidth: 20
                                        horizontalAlignment: Text.AlignHCenter

                                        MouseArea {
                                            id: catDropBtnMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.filterDropdownOpen = false
                                                root.newCatDropdownOpen = !root.newCatDropdownOpen
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 100
                            Layout.preferredHeight: 24
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
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                text: root.isoToUk(root.newDueDate)
                                onTextChanged: {
                                    if (text.length === 10 && text.indexOf("/") === 2) {
                                        root.newDueDate = root.ukToIso(text)
                                    } else if (text.length === 0) {
                                        root.newDueDate = ""
                                    }
                                }
                                inputMask: "99/99/9999;_"
                                KeyNavigation.backtab: addCatInput
                                Keys.onReturnPressed: root.addTodo()
                                Keys.onEscapePressed: root.addingNew = false

                                Text {
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    text: "dd/mm/yyyy"
                                    color: Theme.fgVeryDim
                                    font: parent.font
                                    visible: !parent.text && !parent.activeFocus
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 2
                        spacing: 6

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            Layout.preferredHeight: 24
                            Layout.preferredWidth: 64
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
                            Layout.preferredHeight: 24
                            Layout.preferredWidth: 64
                            radius: 4
                            color: addConfirmMouse.containsMouse ? Theme.brightYellow : Theme.yellow

                            Text {
                                anchors.centerIn: parent
                                text: "Add"
                                color: Theme.bg
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                            }

                            MouseArea {
                                id: addConfirmMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.addTodo()
                            }
                        }
                    }
                }
            }

            // Settings panel
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: root.showSettings ? settingsCol.implicitHeight + 16 : 0
                visible: Layout.preferredHeight > 0
                clip: true
                radius: 6
                color: Qt.rgba(0, 0, 0, 0.25)

                Behavior on Layout.preferredHeight {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                ColumnLayout {
                    id: settingsCol
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Text {
                        text: "Settings"
                        color: Theme.fgDim
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "Show counter in bar"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 18
                            radius: 9
                            color: TimepiecesStore.todosBarShow ? Theme.green : Qt.rgba(1, 1, 1, 0.1)
                            Behavior on color { ColorAnimation { duration: 200 } }

                            Rectangle {
                                width: 14
                                height: 14
                                radius: 7
                                color: Theme.fg
                                anchors.verticalCenter: parent.verticalCenter
                                x: TimepiecesStore.todosBarShow ? parent.width - width - 2 : 2
                                Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    TimepiecesStore.todosBarShow = !TimepiecesStore.todosBarShow
                                    TimepiecesStore.save()
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        visible: TimepiecesStore.todosBarShow

                        Text {
                            text: "Count"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            Layout.preferredWidth: 50
                        }

                        Repeater {
                            model: [
                                { key: "all", label: "All" },
                                { key: "urgent", label: "Urgent" },
                                { key: "highPriority", label: "High" }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 22
                                radius: 4
                                color: TimepiecesStore.todosBarFilter === modelData.key
                                       ? Theme.yellow
                                       : (filterSegMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.3))
                                border.width: 1
                                border.color: TimepiecesStore.todosBarFilter === modelData.key
                                              ? Theme.yellow : Qt.rgba(1, 1, 1, 0.05)
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: TimepiecesStore.todosBarFilter === modelData.key
                                           ? Theme.bg : Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: TimepiecesStore.todosBarFilter === modelData.key
                                }

                                MouseArea {
                                    id: filterSegMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        TimepiecesStore.todosBarFilter = modelData.key
                                        TimepiecesStore.save()
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: TimepiecesStore.todosBarShow
                        text: {
                            const f = TimepiecesStore.todosBarFilter
                            if (f === "urgent") return "Counts todos due today or overdue."
                            if (f === "highPriority") return "Counts todos at priority M or H."
                            return "Counts all incomplete todos."
                        }
                        color: Theme.fgVeryDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Qt.rgba(1, 1, 1, 0.06)
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "Sort"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            Layout.preferredWidth: 70
                        }

                        Repeater {
                            model: [
                                { key: "manual", label: "Manual" },
                                { key: "newestFirst", label: "Newest" },
                                { key: "oldestFirst", label: "Oldest" }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 22
                                radius: 4
                                color: TimepiecesStore.todosSort === modelData.key
                                       ? Theme.yellow
                                       : (sortSegMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.3))
                                border.width: 1
                                border.color: TimepiecesStore.todosSort === modelData.key
                                              ? Theme.yellow : Qt.rgba(1, 1, 1, 0.05)
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: TimepiecesStore.todosSort === modelData.key
                                           ? Theme.bg : Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: TimepiecesStore.todosSort === modelData.key
                                }

                                MouseArea {
                                    id: sortSegMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        TimepiecesStore.todosSort = modelData.key
                                        TimepiecesStore.save()
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "Priority first"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 18
                            radius: 9
                            color: TimepiecesStore.todosPriorityFirst ? Theme.green : Qt.rgba(1, 1, 1, 0.1)
                            Behavior on color { ColorAnimation { duration: 200 } }

                            Rectangle {
                                width: 14
                                height: 14
                                radius: 7
                                color: Theme.fg
                                anchors.verticalCenter: parent.verticalCenter
                                x: TimepiecesStore.todosPriorityFirst ? parent.width - width - 2 : 2
                                Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    TimepiecesStore.todosPriorityFirst = !TimepiecesStore.todosPriorityFirst
                                    TimepiecesStore.save()
                                }
                            }
                        }
                    }
                }
            }

            ListView {
                id: activeList
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 280)
                clip: true
                model: root.activeTodos
                spacing: 4

                delegate: TodoRow {
                    width: activeList.width
                    todoData: modelData
                    isDone: false
                }
            }

            Text {
                Layout.fillWidth: true
                visible: root.activeTodos.length === 0
                text: root.activeCategory === "All"
                      ? "No todos yet. Click + Add."
                      : "No todos in " + root.activeCategory
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                Layout.topMargin: 16
                Layout.bottomMargin: 16
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                radius: 4
                color: doneMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
                visible: root.doneTodos.length > 0

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    spacing: 6

                    Text {
                        text: root.showDone ? "▾" : "▸"
                        color: Theme.fgDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }
                    Text {
                        text: "Done (" + root.doneTodos.length + ")"
                        color: Theme.fgDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                    Item { Layout.fillWidth: true }
                }

                MouseArea {
                    id: doneMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.showDone = !root.showDone
                }
            }

            ListView {
                id: doneList
                Layout.fillWidth: true
                Layout.preferredHeight: root.showDone && root.doneTodos.length > 0
                                        ? Math.min(contentHeight, 160) : 0
                visible: Layout.preferredHeight > 0
                clip: true
                model: root.doneTodos
                spacing: 4

                Behavior on Layout.preferredHeight {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                delegate: TodoRow {
                    width: doneList.width
                    todoData: modelData
                    isDone: true
                }
            }

            Text {
                Layout.fillWidth: true
                text: "↑↓/jk navigate · Space toggle · Enter edit · Del delete · Shift+↑↓ reorder · Tab zones · Ctrl+N new · Tab priority/cat/date · D done · F filter · Esc close"
                color: Theme.fgVeryDim
                font.family: Theme.fontFamily
                font.pixelSize: 9
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }

        // FLOATING DROPDOWNS

        Rectangle {
            id: filterDropdown
            visible: root.filterDropdownOpen
            x: {
                const p = filterPill.mapToItem(card, 0, 0)
                return p.x
            }
            y: {
                const p = filterPill.mapToItem(card, 0, 0)
                return p.y + filterPill.height + 4
            }
            width: 180
            height: filterDropdownCol.implicitHeight + 8
            color: "#2a2a2a"
            radius: 8
            border.width: 1
            border.color: "#f38c6f"
            z: 1000

            ColumnLayout {
                id: filterDropdownCol
                anchors.fill: parent
                anchors.margins: 4
                spacing: 0

                Repeater {
                    model: root.filterCategories
                    delegate: Rectangle {
                        required property string modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        radius: 4
                        color: filterItemMouse.containsMouse || root.filterDropdownIndex === index
                               ? Qt.rgba(1, 1, 1, 0.12)
                               : (modelData === root.activeCategory ? Qt.rgba(1,1,1,0.06) : "transparent")
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 6

                            Text {
                                text: modelData === root.activeCategory ? "✓" : ""
                                color: Theme.yellow
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                Layout.preferredWidth: 10
                            }
                            Text {
                                text: modelData
                                color: modelData === root.activeCategory ? Theme.yellow : Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: modelData === root.activeCategory
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            id: filterItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.activeCategory = modelData
                                root.filterDropdownOpen = false
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: newCatDropdown
            visible: root.newCatDropdownOpen
            x: {
                if (!newCatField.visible) return 0
                const p = newCatField.mapToItem(card, 0, 0)
                return p.x
            }
            y: {
                if (!newCatField.visible) return 0
                const p = newCatField.mapToItem(card, 0, 0)
                return p.y + newCatField.height + 4
            }
            width: newCatField.visible ? newCatField.width : 0
            height: newCatDropdownCol.implicitHeight + 8
            color: "#2a2a2a"
            radius: 8
            border.width: 1
            border.color: "#f38c6f"
            z: 1000

            ColumnLayout {
                id: newCatDropdownCol
                anchors.fill: parent
                anchors.margins: 4
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 26
                    radius: 4
                    color: noneMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "(No category)"
                        color: Theme.fgDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.italic: true
                    }

                    MouseArea {
                        id: noneMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            addCatInput.text = ""
                            root.newCatDropdownOpen = false
                        }
                    }
                }

                Repeater {
                    model: root.allCategoryNames
                    delegate: Rectangle {
                        required property string modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 26
                        radius: 4
                        color: newCatItemMouse.containsMouse
                               ? Qt.rgba(1, 1, 1, 0.12)
                               : (modelData === root.newCategory ? Qt.rgba(1,1,1,0.06) : "transparent")
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 6

                            Text {
                                text: modelData === root.newCategory ? "✓" : ""
                                color: Theme.yellow
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                Layout.preferredWidth: 10
                            }
                            Text {
                                text: modelData
                                color: modelData === root.newCategory ? Theme.yellow : Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            id: newCatItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                addCatInput.text = modelData
                                root.newCatDropdownOpen = false
                            }
                        }
                    }
                }
            }
        }
    }

    component TodoRow: Item {
        id: todoRow
        property var todoData
        property bool isDone

        readonly property bool isEditing: root.editingId === todoData.id
        height: isEditing ? 32 + editExpand.height + 4 : 32
        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        readonly property bool isFocused: {
            if (root.focusZone === (isDone ? "done" : "active")) {
                const list = isDone ? root.doneTodos : root.activeTodos
                return list[root.focusIndex] && list[root.focusIndex].id === todoData.id
            }
            return false
        }

        property bool dragging: false
        Drag.active: dragging
        Drag.source: todoRow
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2
        Drag.dragType: Drag.Automatic

        DropArea {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 32
            onDropped: function(drop) {
                if (drop.source && drop.source.todoData) {
                    root.moveTodo(drop.source.todoData.id, todoRow.todoData.id)
                }
            }
            onEntered: dropIndicator.visible = true
            onExited: dropIndicator.visible = false
        }

        Rectangle {
            id: dropIndicator
            visible: false
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
            color: Theme.yellow
            radius: 1
            z: 10
        }

        Rectangle {
            id: mainRow
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 1
            height: 30
            radius: 4
            color: rowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
            border.width: todoRow.isFocused ? 1 : 0
            border.color: Theme.yellow
            Behavior on color { ColorAnimation { duration: 150 } }
            opacity: todoRow.dragging ? 0.5 : 1

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 2
                width: 3
                radius: 1.5
                color: root.priorityColor(todoData.priority || 0)
                visible: (todoData.priority || 0) > 0
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 6
                spacing: 8

                Text {
                    text: "≡"
                    color: dragMouse.containsMouse ? Theme.fg : Theme.fgVeryDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    visible: TimepiecesStore.todosSort === "manual" && !todoRow.isEditing

                    MouseArea {
                        id: dragMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.SizeVerCursor
                        drag.target: todoRow
                        drag.axis: Drag.YAxis
                        onPressed: todoRow.dragging = true
                        onReleased: {
                            todoRow.dragging = false
                            todoRow.Drag.drop()
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    radius: 3
                    color: todoData.done ? Theme.green : "transparent"
                    border.width: 1
                    border.color: todoData.done ? Theme.green : Theme.fgDim
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "✓"
                        color: Theme.bg
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        visible: todoData.done
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleTodo(todoData.id)
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        visible: !todoRow.isEditing
                        text: todoData.text
                        color: todoData.done ? Theme.fgDim : Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.strikeout: todoData.done
                        elide: Text.ElideRight
                    }

                    TextInput {
                        id: editInput
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        visible: todoRow.isEditing
                        focus: todoRow.isEditing
                        text: todoData.text
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        selectByMouse: true

                        onVisibleChanged: {
                            if (visible) {
                                selectAll()
                                forceActiveFocus()
                            }
                        }

                        Keys.onReturnPressed: root.saveTodo(todoData.id, text)
                        Keys.onEscapePressed: root.editingId = ""
                    }

                    MouseArea {
                        anchors.fill: parent
                        visible: !todoRow.isEditing && !todoData.done
                        cursorShape: Qt.IBeamCursor
                        onClicked: root.startEditing(todoData)
                    }
                }

                Text {
                    visible: (todoData.category && todoData.category.length > 0) && !todoRow.isEditing
                    text: todoData.category || ""
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                }

                Text {
                    visible: (todoData.dueDate && todoData.dueDate.length > 0) && !todoRow.isEditing
                    text: root.dueLabel(todoData.dueDate)
                    color: root.dueColor(todoData.dueDate)
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }

                Rectangle {
                    Layout.preferredWidth: 18
                    Layout.preferredHeight: 18
                    radius: 9
                    visible: !todoRow.isEditing
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
                        onClicked: root.deleteTodo(todoData.id)
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

        Rectangle {
            id: editExpand
            visible: todoRow.isEditing
            anchors.top: mainRow.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 4
            height: editCol.implicitHeight + 16
            radius: 6
            color: Qt.rgba(0, 0, 0, 0.25)

            onVisibleChanged: {
                if (visible) {
                    editCatInput.text = root.editCategory
                    editDateInput.text = root.isoToUk(root.editDueDate)
                }
            }

            ColumnLayout {
                id: editCol
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: [
                            { p: 0, label: "—" },
                            { p: 1, label: "L" },
                            { p: 2, label: "M" },
                            { p: 3, label: "H" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            Layout.preferredHeight: 24
                            Layout.preferredWidth: 28
                            radius: 4
                            color: root.editPriority === modelData.p
                                   ? root.priorityColor(modelData.p) === "transparent"
                                     ? Qt.rgba(1, 1, 1, 0.18)
                                     : root.priorityColor(modelData.p)
                                   : Qt.rgba(0, 0, 0, 0.3)
                            border.width: 1
                            border.color: root.editPriority === modelData.p
                                          ? Qt.rgba(1, 1, 1, 0.3) : Qt.rgba(1, 1, 1, 0.05)
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: root.editPriority === modelData.p && modelData.p > 0
                                       ? Theme.bg : Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.editPriority = modelData.p
                            }
                        }
                    }

                    Item { Layout.preferredWidth: 4 }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        radius: 4
                        color: Qt.rgba(0, 0, 0, 0.3)
                        border.width: 1
                        border.color: editCatInput.activeFocus ? Theme.yellow : Qt.rgba(1, 1, 1, 0.08)

                        TextInput {
                            id: editCatInput
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            text: root.editCategory
                            onTextChanged: root.editCategory = text
                            Keys.onReturnPressed: root.saveTodo(todoData.id, editInput.text)
                            Keys.onEscapePressed: root.editingId = ""

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "Category"
                                color: Theme.fgVeryDim
                                font: parent.font
                                visible: !parent.text && !parent.activeFocus
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 100
                        Layout.preferredHeight: 24
                        radius: 4
                        color: Qt.rgba(0, 0, 0, 0.3)
                        border.width: 1
                        border.color: editDateInput.activeFocus ? Theme.yellow : Qt.rgba(1, 1, 1, 0.08)

                        TextInput {
                            id: editDateInput
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            text: root.isoToUk(root.editDueDate)
                            onTextChanged: {
                                if (text.length === 10 && text.indexOf("/") === 2) {
                                    root.editDueDate = root.ukToIso(text)
                                } else if (text.length === 0) {
                                    root.editDueDate = ""
                                }
                            }
                            inputMask: "99/99/9999;_"
                            Keys.onReturnPressed: root.saveTodo(todoData.id, editInput.text)
                            Keys.onEscapePressed: root.editingId = ""

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "dd/mm/yyyy"
                                color: Theme.fgVeryDim
                                font: parent.font
                                visible: !parent.text && !parent.activeFocus
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredHeight: 24
                        Layout.preferredWidth: 64
                        radius: 4
                        color: editCancelMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
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
                            id: editCancelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.editingId = ""
                        }
                    }

                    Rectangle {
                        Layout.preferredHeight: 24
                        Layout.preferredWidth: 64
                        radius: 4
                        color: editSaveMouse.containsMouse ? Theme.brightYellow : Theme.yellow

                        Text {
                            anchors.centerIn: parent
                            text: "Save"
                            color: Theme.bg
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            id: editSaveMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.saveTodo(todoData.id, editInput.text)
                        }
                    }
                }
            }
        }
    }
}
