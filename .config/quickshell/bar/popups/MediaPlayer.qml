import "."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Hyprland
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

    function toggle() { if (visible) close(); else open_() }
    function open_() { ActivePlayer.autoSelect(); pendingTrackChange = false; visible = true }
    function close() { visible = false }

    onVisibleChanged: if (visible) PopupManager.open(root)

    readonly property var p: ActivePlayer.current
    readonly property bool hasContent: p && (p.trackTitle && p.trackTitle.length > 0) && !pendingTrackChange

    property bool pendingTrackChange: false
    property string lastTrackTitle: ""

    Connections {
        target: ActivePlayer
        function onTrackTitleChanged() {
            if (ActivePlayer.trackTitle !== root.lastTrackTitle) {
                root.lastTrackTitle = ActivePlayer.trackTitle
                root.pendingTrackChange = false
            }
        }
    }

    function fmtTime(s) {
        if (!s || s < 0) return "0:00"
        const m = Math.floor(s / 60)
        const sec = Math.floor(s % 60)
        return m + ":" + ("0" + sec).slice(-2)
    }

    function urlForPlayer(pl) {
        if (!pl || !pl.metadata) return ""
        return pl.metadata["xesam:url"] || ""
    }

    function classToLabel(klass) {
        if (!klass) return ""
        const k = klass.toLowerCase()
        if (k.indexOf("music.youtube.com") !== -1) return "YouTube Music"
        if (k.indexOf("www.youtube.com") !== -1 || k.indexOf("youtube.com") !== -1) return "YouTube"
        if (k.indexOf("soundcloud") !== -1) return "SoundCloud"
        if (k.indexOf("spotify") !== -1) return "Spotify"
        if (k.indexOf("twitch") !== -1) return "Twitch"
        if (k.indexOf("netflix") !== -1) return "Netflix"
        if (k.indexOf("bbc") !== -1) return "BBC"
        if (k === "firefox") return "Firefox"
        if (k === "vivaldi-stable" || k === "vivaldi") return "Vivaldi"
        if (k === "chromium") return "Chromium"
        if (k === "vlc") return "VLC"
        if (k === "mpv") return "mpv"
        // For other chrome-* PWAs, extract the domain
        const m = k.match(/^chrome-([^_-]+)/)
        if (m) {
            const domain = m[1]
            // Capitalize first letter
            return domain.charAt(0).toUpperCase() + domain.slice(1)
        }
        return klass
    }

    

    function playerDisplayName(pl) {
        if (!pl) return "Player"

        // Try MPRIS xesam:url first (most reliable when present)
        const url = urlForPlayer(pl)
        if (url) {
            if (url.indexOf("music.youtube.com") !== -1) return "YouTube Music"
            if (url.indexOf("youtube.com") !== -1) return "YouTube"
            if (url.indexOf("soundcloud.com") !== -1) return "SoundCloud"
            if (url.indexOf("spotify.com") !== -1) return "Spotify"
            if (url.indexOf("twitch.tv") !== -1) return "Twitch"
            if (url.indexOf("netflix.com") !== -1) return "Netflix"
            if (url.indexOf("bbc.co.uk") !== -1) return "BBC"
        }

        // If identity is Chromium and we have track info, look at all chrome- windows
        // to find which one has audio. Prefer the most-recently-focused chrome- class.
        const id = (pl.identity || "").toLowerCase()
        if (id === "chromium") {
            const toplevels = Hyprland.toplevels.values || []
            // Sort by focusHistoryID ascending (lower = more recent)
            // Use wayland.appId (always populated for native Wayland) as the class source;
            // lastIpcObject["class"] is only updated on IPC events so may be stale/empty.
            const chromes = toplevels
                .filter(t => { const c = (t.wayland && t.wayland.appId) || (t.lastIpcObject && t.lastIpcObject["class"]) || ""; return c.toLowerCase().startsWith("chrome-") })
                .sort((a, b) => ((a.lastIpcObject && a.lastIpcObject["focusHistoryID"]) || 0) - ((b.lastIpcObject && b.lastIpcObject["focusHistoryID"]) || 0))

            // Try matching by track title first (works for music players where title = song)
            const title = pl.trackTitle || ""
            if (title) {
                for (const t of chromes) {
                    if (t.title && t.title.indexOf(title) !== -1) {
                        const cls = (t.wayland && t.wayland.appId) || (t.lastIpcObject && t.lastIpcObject["class"]) || ""
                        return classToLabel(cls)
                    }
                }
            }

            // No title match (or empty title) — pick the most specific known streaming service
            // across all chrome windows (priority order, not focus order, so YTMusic beats YouTube)
            const serviceOrder = ["YouTube Music", "YouTube", "SoundCloud", "Spotify", "Twitch", "Netflix", "BBC"]
            let bestIdx = serviceOrder.length
            for (const t of chromes) {
                const cls = (t.wayland && t.wayland.appId) || (t.lastIpcObject && t.lastIpcObject["class"]) || ""
                const lbl = classToLabel(cls)
                const idx = serviceOrder.indexOf(lbl)
                if (idx !== -1 && idx < bestIdx) bestIdx = idx
            }
            if (bestIdx < serviceOrder.length) return serviceOrder[bestIdx]
            // Fallback: desktop entry hint or generic
            if (pl.desktopEntry) {
                const lbl = classToLabel(pl.desktopEntry)
                if (lbl) return lbl
            }
            return "Browser"
        }

        return pl.identity || "Player"
    }

    function playerIcon(pl) {
        if (!pl) return "󰝚"
        const label = playerDisplayName(pl)
        if (label === "YouTube Music" || label === "YouTube") return "󰗃"
        if (label === "Spotify") return "󰓇"
        if (label === "SoundCloud") return "󰓀"
        if (label === "Twitch") return "󰕃"
        if (label === "Netflix") return "󰚺"
        const id = (pl.identity || "").toLowerCase()
        if (id.includes("firefox")) return "󰈹"
        if (id.includes("vlc")) return "󰕼"
        if (id.includes("mpv")) return "󰐹"
        return "󰝚"
    }

    

    // Returns the HyprlandToplevel that matches the given player, or null.
    function playerWindow(pl) {
        if (!pl) return null
        const toplevels = Hyprland.toplevels.values || []
        const id = (pl.identity || "").toLowerCase()
        if (id === "chromium") {
            const chromes = toplevels
                .filter(t => { const c = (t.wayland && t.wayland.appId) || (t.lastIpcObject && t.lastIpcObject["class"]) || ""; return c.toLowerCase().startsWith("chrome-") })
                .sort((a, b) => ((a.lastIpcObject && a.lastIpcObject["focusHistoryID"]) || 0) - ((b.lastIpcObject && b.lastIpcObject["focusHistoryID"]) || 0))
            const title = pl.trackTitle || ""
            if (title) {
                for (const t of chromes) { if (t.title && t.title.indexOf(title) !== -1) return t }
            }
            const serviceOrder = ["YouTube Music", "YouTube", "SoundCloud", "Spotify", "Twitch", "Netflix", "BBC"]
            let bestIdx = serviceOrder.length, bestT = null
            for (const t of chromes) {
                const cls = (t.wayland && t.wayland.appId) || (t.lastIpcObject && t.lastIpcObject["class"]) || ""
                const idx = serviceOrder.indexOf(classToLabel(cls))
                if (idx !== -1 && idx < bestIdx) { bestIdx = idx; bestT = t }
            }
            return bestT
        }
        for (const t of toplevels) {
            const cls = ((t.wayland && t.wayland.appId) || (t.lastIpcObject && t.lastIpcObject["class"]) || "").toLowerCase()
            if (cls === id || cls.indexOf(id) !== -1) return t
        }
        return null
    }

    function seekBy(seconds) {
        if (!p || !p.canSeek) return
        const newPos = Math.max(0, Math.min(p.length || 0, (p.position || 0) + seconds))
        p.position = newPos
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: card
        width: 360
        height: cardCol.implicitHeight + 16

        x: {
            if (!root.anchorItem) return 20
            const pp = root.anchorItem.mapToItem(null, 0, 0)
            const desired = pp.x + (root.anchorItem.width / 2) - (width / 2)
            return Math.max(8, Math.min(root.width - width - 8, desired))
        }
        y: 0

        color: Theme.popupBg
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

        // Auto-close when mouse leaves the card and doesn't return within 5 s
        HoverHandler {
            onHoveredChanged: {
                if (!hovered) autoCloseTimer.restart()
                else autoCloseTimer.stop()
            }
        }
        Timer {
            id: autoCloseTimer
            interval: 2000
            onTriggered: root.close()
        }

        Item {
            anchors.fill: parent
            focus: root.visible
            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) { root.close(); event.accepted = true }
                else if (event.key === Qt.Key_Space) {
                    if (root.hasContent && root.p && root.p.canTogglePlaying) root.p.isPlaying = !root.p.isPlaying
                    else if (!root.hasContent) { ActivePlayer.launchYTMusic(); root.close() }
                    event.accepted = true
                }
                else if (event.key === Qt.Key_Return) {
                    if (!root.hasContent) { ActivePlayer.launchYTMusic(); root.close() }
                    event.accepted = true
                }
                else if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
                    if (root.p && root.p.canGoNext) {
                        root.pendingTrackChange = true
                        root.p.next()
                    }
                    event.accepted = true
                }
                else if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
                    if (root.p && root.p.canGoPrevious) {
                        root.pendingTrackChange = true
                        root.p.previous()
                    }
                    event.accepted = true
                }
                else if (event.key === Qt.Key_H || event.key === Qt.Key_Left) {
                    const delta = (event.modifiers & Qt.ShiftModifier) ? -30 : -5
                    root.seekBy(delta)
                    event.accepted = true
                }
                else if (event.key === Qt.Key_L || event.key === Qt.Key_Right) {
                    const delta = (event.modifiers & Qt.ShiftModifier) ? 30 : 5
                    root.seekBy(delta)
                    event.accepted = true
                }
                else if (event.key === Qt.Key_Tab) {
                    ActivePlayer.cycleNext()
                    event.accepted = true
                }
                else if (event.key === Qt.Key_P) {
                    const win = root.playerWindow(root.p)
                    if (win && win.wayland) { win.wayland.activate(); root.close() }
                    event.accepted = true
                }
                else if (event.key === Qt.Key_S) {
                    SettingsStore.nowPlayingScroll = !SettingsStore.nowPlayingScroll
                    SettingsStore.save()
                    event.accepted = true
                }
                else if (event.key === Qt.Key_X) {
                    const win = root.playerWindow(root.p)
                    if (win && win.wayland) win.wayland.close()
                    event.accepted = true
                }
            }
        }

        // X close — tucked in tight to top-right
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 4
            anchors.rightMargin: 4
            width: 20; height: 20; radius: 10
            color: closeMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
            z: 10
            Behavior on color { ColorAnimation { duration: Theme.animFast } }

            Text {
                anchors.centerIn: parent
                text: "✕"
                color: closeMouse.containsMouse ? Theme.fg : Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.close()
            }
        }

        // Scroll toggle
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 4
            anchors.rightMargin: 28
            width: 40; height: 20; radius: 10
            color: scrollToggleMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
            z: 10
            Behavior on color { ColorAnimation { duration: Theme.animFast } }

            Row {
                anchors.centerIn: parent
                spacing: 3

                Text {
                    text: "↔"
                    color: Theme.nowPlayingScroll
                           ? (scrollToggleMouse.containsMouse ? Theme.fg : Theme.yellow)
                           : Theme.fgVeryDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }
                Text {
                    text: "s"
                    color: Theme.nowPlayingScroll
                           ? (scrollToggleMouse.containsMouse ? Theme.fg : Theme.yellow)
                           : Theme.fgVeryDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 8
                    anchors.baseline: undefined
                    topPadding: 4
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }
            }
            MouseArea {
                id: scrollToggleMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { SettingsStore.nowPlayingScroll = !SettingsStore.nowPlayingScroll; SettingsStore.save() }
            }
        }

        ColumnLayout {
            id: cardCol
            anchors.fill: parent
            anchors.margins: 10
            anchors.topMargin: 8
            spacing: 8

            // Player tabs (compact)
            RowLayout {
                Layout.fillWidth: true
                Layout.rightMargin: 72
                spacing: 4
                visible: ActivePlayer.players.length > 0

                Repeater {
                    model: ActivePlayer.players

                    delegate: Item {
                        id: tabDelegate
                        required property var modelData
                        required property int index
                        Layout.preferredHeight: 22
                        Layout.preferredWidth: tabContent.implicitWidth + 14

                        Rectangle {
                            id: tabContent
                            anchors.fill: parent
                            radius: 11
                            color: ActivePlayer.selectedIndex === tabDelegate.index
                                   ? Theme.yellow
                                   : (tabMouse.containsMouse ? Qt.rgba(1,1,1,0.12) : Qt.rgba(0,0,0,0.25))
                            border.width: 1
                            border.color: ActivePlayer.selectedIndex === tabDelegate.index ? Theme.yellow : Qt.rgba(1,1,1,0.08)
                            Behavior on color { ColorAnimation { duration: 150 } }

                            implicitWidth: tabRow.implicitWidth

                            RowLayout {
                                id: tabRow
                                anchors.centerIn: parent
                                spacing: 5

                                Text {
                                    text: root.playerIcon(tabDelegate.modelData)
                                    color: ActivePlayer.selectedIndex === tabDelegate.index ? Theme.bg : Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                }
                                Text {
                                    text: root.playerDisplayName(tabDelegate.modelData)
                                    color: ActivePlayer.selectedIndex === tabDelegate.index ? Theme.bg : Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: ActivePlayer.selectedIndex === tabDelegate.index
                                    elide: Text.ElideRight
                                }
                                Text {
                                    visible: tabDelegate.modelData.isPlaying || dotMouse.containsMouse
                                    text: dotMouse.containsMouse ? "✕" : "●"
                                    color: dotMouse.containsMouse
                                           ? (ActivePlayer.selectedIndex === tabDelegate.index ? Theme.bg : Theme.red)
                                           : (ActivePlayer.selectedIndex === tabDelegate.index ? Theme.bg : Theme.green)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: dotMouse.containsMouse ? 7 : 5
                                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                }
                            }
                        }

                        MouseArea {
                            id: tabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            z: 5
                            onClicked: {
                                ActivePlayer.selectPlayer(tabDelegate.index)
                                root.pendingTrackChange = false
                            }
                        }

                        Item {
                            anchors.right: tabContent.right
                            anchors.rightMargin: 7
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14
                            height: parent.height
                            z: 10

                            MouseArea {
                                id: dotMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: function(ev) {
                                    ev.accepted = true
                                    const win = root.playerWindow(tabDelegate.modelData)
                                    if (win && win.wayland) win.wayland.close()
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }

            // Empty state
            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                spacing: 10
                visible: !root.hasContent

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "󰝚"
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 40
                }

                Text {
                    Layout.fillWidth: true
                    text: root.pendingTrackChange ? "Loading…" :
                          (ActivePlayer.players.length === 0 ? "Nothing playing" : "Player is idle")
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                }

                Rectangle {
                    visible: !root.pendingTrackChange
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: ytLaunchRow.implicitWidth + 20
                    radius: 15
                    color: ytLaunchMouse.containsMouse ? Theme.red : Qt.rgba(251/255, 73/255, 52/255, 0.85)
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        id: ytLaunchRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "󰐊"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }
                        Text {
                            text: "Play YouTube Music"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    MouseArea {
                        id: ytLaunchMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { ActivePlayer.launchYTMusic(); root.close() }
                    }
                }
            }

            // Active: bigger art + info
            RowLayout {
                Layout.fillWidth: true
                visible: root.hasContent
                spacing: 12

                Item {
                    Layout.preferredWidth: 110
                    Layout.preferredHeight: 110

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: Qt.rgba(0, 0, 0, 0.4)
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: root.p ? root.p.trackArtUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            asynchronous: true
                            visible: status === Image.Ready
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰝚"
                            color: Theme.fgDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 40
                            visible: !root.p || !root.p.trackArtUrl
                        }
                    }

                    // Click art to focus the player window
                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: "transparent"
                        border.width: artMouse.containsMouse ? 1 : 0
                        border.color: "#f38c6f"
                        Behavior on border.width { NumberAnimation { duration: Theme.animFast } }

                        MouseArea {
                            id: artMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const win = root.playerWindow(root.p)
                                if (win && win.wayland) { win.wayland.activate(); root.close() }
                            }
                        }
                    }

                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 3

                    Text {
                        Layout.fillWidth: true
                        text: root.p ? (root.p.trackTitle || "Unknown title") : ""
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.bold: true
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.p ? (root.p.trackArtist || "") : ""
                        color: Theme.fgDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        visible: text.length > 0
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.p ? (root.p.trackAlbum || "") : ""
                        color: Theme.fgVeryDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        visible: text.length > 0
                    }
                }
            }

            // Scrubber
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.hasContent && root.p && root.p.length > 0
                spacing: 1

                Timer {
                    interval: 500
                    running: root.visible && root.p && root.p.isPlaying
                    repeat: true
                    onTriggered: if (root.p) root.p.positionChanged()
                }

                Rectangle {
                    id: scrubTrack
                    Layout.fillWidth: true
                    Layout.preferredHeight: 5
                    radius: 2.5
                    color: Qt.rgba(0, 0, 0, 0.3)

                    readonly property real pct: {
                        if (!root.p || !root.p.length || root.p.length <= 0) return 0
                        return Math.max(0, Math.min(1, root.p.position / root.p.length))
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * scrubTrack.pct
                        radius: 2.5
                        color: Theme.yellow
                    }

                    Rectangle {
                        width: 10; height: 10; radius: 5
                        color: Theme.fg
                        border.width: 2
                        border.color: Theme.yellow
                        anchors.verticalCenter: parent.verticalCenter
                        x: parent.width * scrubTrack.pct - 5
                        visible: scrubMouse.containsMouse || scrubMouse.pressed
                    }

                    MouseArea {
                        id: scrubMouse
                        anchors.fill: parent
                        anchors.topMargin: -6
                        anchors.bottomMargin: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: root.p && root.p.canSeek
                        onClicked: function(ev) {
                            if (!root.p || !root.p.length) return
                            const ratio = ev.x / width
                            root.p.position = ratio * root.p.length
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: root.fmtTime(root.p ? root.p.position : 0)
                        color: Theme.fgDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: root.fmtTime(root.p ? root.p.length : 0)
                        color: Theme.fgDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                    }
                }
            }

            // Transport
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                visible: root.hasContent
                spacing: 10

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: 30
                    radius: 15
                    color: prevMouse.containsMouse ? Qt.rgba(1,1,1,0.12) : "transparent"
                    opacity: root.p && root.p.canGoPrevious ? 1 : 0.3
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰒮"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                    }

                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: root.p && root.p.canGoPrevious
                        onClicked: {
                            root.pendingTrackChange = true
                            root.p.previous()
                        }
                    }
                }

                Rectangle {
                    Layout.preferredHeight: 40
                    Layout.preferredWidth: 40
                    radius: 20
                    color: playMouse.containsMouse ? Theme.brightYellow : Theme.yellow
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: root.p && root.p.isPlaying ? "󰏤" : "󰐊"
                        color: Theme.bg
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                    }

                    MouseArea {
                        id: playMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: root.p && root.p.canTogglePlaying
                        onClicked: root.p.isPlaying = !root.p.isPlaying
                    }
                }

                Rectangle {
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: 30
                    radius: 15
                    color: nextMouse.containsMouse ? Qt.rgba(1,1,1,0.12) : "transparent"
                    opacity: root.p && root.p.canGoNext ? 1 : 0.3
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰒭"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                    }

                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: root.p && root.p.canGoNext
                        onClicked: {
                            root.pendingTrackChange = true
                            root.p.next()
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }

            // Cava
            Row {
                Layout.fillWidth: true
                Layout.preferredHeight: 26
                spacing: 2
                visible: root.hasContent && root.p && root.p.isPlaying

                Repeater {
                    model: Cava.bars ? Cava.bars.length : 24

                    delegate: Rectangle {
                        required property int index
                        readonly property real value: {
                            if (!Cava.bars || !Cava.bars[index]) return 0
                            return Math.max(0, Math.min(1, Cava.bars[index]))
                        }
                        width: (parent.width - (parent.children.length - 1) * 2) / (parent.children.length || 1)
                        height: Math.max(2, parent.height * value)
                        anchors.bottom: parent.bottom
                        radius: 1
                        color: Theme.yellow
                        opacity: 0.7 + 0.3 * value

                        Behavior on height { NumberAnimation { duration: 60 } }
                    }
                }
            }
        }
    }
}
