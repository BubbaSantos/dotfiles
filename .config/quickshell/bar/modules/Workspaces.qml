import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.popups

RowLayout {
    spacing: 2

    Repeater {
        // Show workspaces 1-5 always, plus any active ones beyond that
        model: {
            const wsList = Hyprland.workspaces.values
            const ids = new Set([1, 2, 3, 4, 5])
            wsList.forEach(w => { if (w.id > 0) ids.add(w.id) })
            return Array.from(ids).sort((a, b) => a - b)
        }

        delegate: Rectangle {
            required property int modelData
            readonly property var ws: Hyprland.workspaces.values.find(w => w.id === modelData) || null
            readonly property bool active: Hyprland.focusedWorkspace
                                           && Hyprland.focusedWorkspace.id === modelData
            readonly property bool empty: !ws

            Layout.preferredHeight: 22
            Layout.preferredWidth: active ? 36 : 24
            radius: active ? 10 : 8
            color: active ? Theme.yellow
                          : (mouse.containsMouse ? Qt.rgba(0.376, 0.353, 0.329, 0.3)
                                                 : "transparent")
            border.width: active ? 2 : 0
            border.color: "#141414"
            opacity: empty && !active ? 0.5 : 1.0

            Behavior on Layout.preferredWidth { NumberAnimation { duration: Theme.animFast } }
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

            Text {
                anchors.centerIn: parent
                text: modelData
                color: active ? Theme.bg
                              : (empty ? Theme.fgVeryDim : Theme.fgDim)
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: active
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: function(ev) {
                    if (ev.button === Qt.LeftButton)
                        Hyprland.dispatch("workspace " + modelData)
                    else if (ev.button === Qt.RightButton)
                        controlCenter.toggle()
                }
            }
        }
    }

    ControlCenter { id: controlCenter }
}
