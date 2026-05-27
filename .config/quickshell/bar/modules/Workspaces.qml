import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.popups
import qs.services

RowLayout {
    spacing: SettingsStore.workspaceStyle === "dots" ? 5 : 2

    property string activeSpecialName: ""

    function _formatSpecial(raw) {
        if (!raw) return ""
        const map = {
            "whatsapp": "WhatsApp",
            "ytmusic":  "YT Music",
            "ytm":      "YT Music",
            "fotmob":   "FotMob",
            "reddit":   "Reddit",
            "todo":     "To Do",
            "remmina":  "Remmina",
            "x":        "X",
        }
        if (map[raw]) return map[raw]
        // "special N" → "Special N"
        const m = raw.match(/^special\s+(\d+)$/)
        if (m) return "Special " + m[1]
        return raw.charAt(0).toUpperCase() + raw.slice(1)
    }

    // Listen for activespecial IPC events
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "activespecial") return
            // data format: "workspaceName,monitorName" — empty name means dismissed
            const comma = event.data.indexOf(",")
            let name = comma >= 0 ? event.data.slice(0, comma) : event.data
            if (name.startsWith("special:")) name = name.slice(8)
            activeSpecialName = name
        }
    }

    // Pick up any already-open special workspace when bar loads
    Component.onCompleted: {
        const mon = Hyprland.focusedMonitor
        if (!mon || !mon.lastIpcObject) return
        const sw = mon.lastIpcObject.specialWorkspace
        if (!sw || !sw.id || sw.id === 0) return
        let n = sw.name || ""
        if (n.startsWith("special:")) n = n.slice(8)
        activeSpecialName = n
    }

    // ── Regular workspace indicators ──────────────────────────────────

    Repeater {
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

            readonly property bool isNumbers: SettingsStore.workspaceStyle === "numbers"
            readonly property bool isDots:    SettingsStore.workspaceStyle === "dots"
            readonly property bool animSize:  SettingsStore.workspaceAnim !== "none"
                                           && SettingsStore.workspaceAnim !== "fade"

            Layout.preferredHeight: isDots ? (active ? 12 : 8) : 22
            Layout.preferredWidth: {
                if (isDots)    return active ? 12 : 8
                if (isNumbers) return active ? 36 : 24
                return 8
            }

            radius: isDots ? Layout.preferredHeight / 2
                           : (isNumbers ? (active ? 10 : 8) : 2)

            color: {
                if (active) return Qt.rgba(Theme.yellow.r, Theme.yellow.g, Theme.yellow.b, SettingsStore.workspaceActiveOpacity)
                if (mouse.containsMouse) return Qt.rgba(0.376, 0.353, 0.329, 0.3)
                if (isNumbers) return "transparent"
                return Qt.rgba(1, 1, 1, empty ? 0.08 : 0.18)
            }

            border.width: active && isNumbers ? 2 : 0
            border.color: "#141414"
            opacity: empty && !active && isNumbers ? 0.5 : 1.0

            Behavior on Layout.preferredWidth {
                enabled: animSize
                NumberAnimation {
                    duration: Theme.animFast
                    easing.type: SettingsStore.workspaceAnim === "bounce" ? Easing.OutBack : Easing.OutCubic
                    easing.overshoot: 1.3
                }
            }
            Behavior on Layout.preferredHeight {
                enabled: animSize
                NumberAnimation {
                    duration: Theme.animFast
                    easing.type: SettingsStore.workspaceAnim === "bounce" ? Easing.OutBack : Easing.OutCubic
                    easing.overshoot: 1.3
                }
            }
            Behavior on color   { ColorAnimation  { duration: SettingsStore.workspaceAnim !== "none" ? Theme.animFast : 0 } }
            Behavior on opacity { NumberAnimation { duration: SettingsStore.workspaceAnim !== "none" ? Theme.animFast : 0 } }

            Text {
                anchors.centerIn: parent
                visible: isNumbers
                text: modelData
                color: active ? Theme.bg : (empty ? Theme.fgVeryDim : Theme.fg)
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

    // ── Special workspace pill ────────────────────────────────────────

    Rectangle {
        id: specialPill
        readonly property string label: _formatSpecial(activeSpecialName)
        readonly property bool    shown: activeSpecialName !== ""

        Layout.preferredHeight: SettingsStore.workspaceStyle === "dots" ? 12 : 22
        Layout.preferredWidth: shown ? specialLabel.implicitWidth + 14 : 0
        clip: true
        radius: SettingsStore.workspaceStyle === "dots" ? 6 : 8

        color:        Qt.rgba(Theme.aqua.r, Theme.aqua.g, Theme.aqua.b, shown ? 0.18 : 0)
        border.width: 1
        border.color: Qt.rgba(Theme.aqua.r, Theme.aqua.g, Theme.aqua.b, shown ? 1.0 : 0)

        Behavior on Layout.preferredWidth {
            NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic }
        }
        Behavior on color        { ColorAnimation { duration: Theme.animFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

        Text {
            id: specialLabel
            anchors.centerIn: parent
            text: specialPill.label
            color: Theme.aqua
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            opacity: specialPill.shown ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        }

        MouseArea {
            anchors.fill: parent
            enabled: specialPill.shown
            cursorShape: Qt.PointingHandCursor
            onClicked: Hyprland.dispatch("togglespecialworkspace " + activeSpecialName)
        }
    }

    ControlCenter { id: controlCenter }

    GlobalShortcut {
        name: "toggleControlCenter"
        onPressed: controlCenter.toggle()
    }
}
