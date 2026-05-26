pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Io

QtObject {
    id: root

    readonly property var players: Mpris.players.values

    property int selectedIndex: -1

    function autoSelect() {
        if (players.length === 0) {
            selectedIndex = -1
            return
        }
        if (selectedIndex >= 0 && selectedIndex < players.length) return

        let idx = players.findIndex(p => p.isPlaying)
        if (idx === -1) idx = players.findIndex(p => p.trackTitle && p.trackTitle.length > 0)
        if (idx === -1) idx = 0
        selectedIndex = idx
    }

    readonly property var current: {
        if (selectedIndex < 0 || selectedIndex >= players.length) return null
        return players[selectedIndex]
    }

    readonly property bool hasPlayer: current !== null
    readonly property bool isPlaying: current ? current.isPlaying : false
    readonly property string trackTitle: current ? current.trackTitle : ""
    readonly property string trackArtist: current ? current.trackArtist : ""
    readonly property string trackAlbum: current ? current.trackAlbum : ""
    readonly property string trackArtUrl: current ? current.trackArtUrl : ""

    function selectPlayer(i) {
        if (i >= 0 && i < players.length) selectedIndex = i
    }

    function cycleNext() {
        if (players.length === 0) return
        selectedIndex = (selectedIndex + 1) % players.length
    }

    property bool pendingYTMAutoPlay: false

    property Process ytmusicProc: Process {
        command: ["sh", "-c", "uwsm app -- chromium --app=https://music.youtube.com"]
    }

    // Moves the YTM window to special:ytm shortly after launch so it doesn't steal focus
    property Process ytmHideProc: Process {
        command: ["sh", "-c",
            "sleep 1 && addr=$(hyprctl clients -j | jq -r '.[] | select(.class | test(\"chrome-music.youtube\")) | .address' | head -1) && [ -n \"$addr\" ] && hyprctl dispatch movetoworkspacesilent \"special:ytm,address:$addr\" || true"
        ]
    }

    // Fires 1s after the YTM MPRIS player first appears, giving it time to fully initialise
    property Timer ytmStabilizeTimer: Timer {
        interval: 1000
        onTriggered: {
            if (!root.pendingYTMAutoPlay) return
            const ytm = root.players.find(p => {
                const url = p.metadata ? p.metadata["xesam:url"] || "" : ""
                return url.indexOf("music.youtube.com") !== -1
            })
            if (ytm) {
                ytm.isPlaying = true
                const idx = root.players.indexOf(ytm)
                if (idx >= 0) root.selectedIndex = idx
            }
            root.pendingYTMAutoPlay = false
        }
    }

    function launchYTMusic() {
        const existing = players.find(p => {
            const url = p.metadata ? p.metadata["xesam:url"] || "" : ""
            return url.indexOf("music.youtube.com") !== -1
        })
        if (existing) {
            existing.isPlaying = true
            const idx = players.indexOf(existing)
            if (idx >= 0) selectedIndex = idx
            return
        }
        pendingYTMAutoPlay = true
        ytmusicProc.running = true
        ytmHideProc.running = true
    }

    property Connections playersConn: Connections {
        target: Mpris.players
        function onValuesChanged() {
            root.autoSelect()
            if (root.pendingYTMAutoPlay && !root.ytmStabilizeTimer.running) {
                const ytm = root.players.find(p => {
                    const url = p.metadata ? p.metadata["xesam:url"] || "" : ""
                    return url.indexOf("music.youtube.com") !== -1
                })
                if (ytm) root.ytmStabilizeTimer.start()
            }
        }
    }

    Component.onCompleted: autoSelect()
}
