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
    visible: TimepiecesStore.todosBarShow && count > 0
    color: mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
    radius: 6

    // Filtered count based on store setting
    readonly property var activeTodos: TimepiecesStore.todos.filter(t => !t.done)

    function isUrgent(t) {
        if (!t.dueDate) return false
        const due = new Date(t.dueDate + "T00:00:00")
        const today = new Date()
        today.setHours(0,0,0,0)
        return due <= today
    }

    readonly property int count: {
        const filter = TimepiecesStore.todosBarFilter
        if (filter === "urgent") return activeTodos.filter(isUrgent).length
        if (filter === "highPriority") return activeTodos.filter(t => (t.priority || 0) >= 2).length
        return activeTodos.length
    }

    function badgeColor() {
        const filter = TimepiecesStore.todosBarFilter
        if (filter === "urgent") return Theme.red
        if (filter === "highPriority") return Theme.brightYellow
        return Theme.yellow
    }

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on Layout.preferredWidth { NumberAnimation { duration: Theme.animFast } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 5

        Text {
            text: "󰄬"   // checkbox icon
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeIcon
        }

        Rectangle {
            Layout.preferredHeight: 14
            Layout.preferredWidth: countText.implicitWidth + 8
            radius: 7
            color: root.badgeColor()
            Behavior on color { ColorAnimation { duration: 200 } }

            Text {
                id: countText
                anchors.centerIn: parent
                text: root.count
                color: Theme.bg
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.bold: true
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: todosPopup.toggle()
    }

    Todos {
        id: todosPopup
        anchorItem: root
    }

    GlobalShortcut {
        name: "toggleTodos"
        description: "Toggle the Todos popup"
        onPressed: todosPopup.toggle()
    }
}
