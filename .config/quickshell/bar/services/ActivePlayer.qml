pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Io

QtObject {
    id: root

    readonly property var players: Mpris.players.values

    property int selectedIndex: -1
    property var _selectedPlayer: null  // reference so index shifts don't lose the selection

    function autoSelect() {
        if (players.length === 0) {
            selectedIndex = -1
            _selectedPlayer = null
            return
        }
        if (selectedIndex >= 0 && selectedIndex < players.length) return

        let idx = players.findIndex(p => p.isPlaying)
        if (idx === -1) idx = players.findIndex(p => p.trackTitle && p.trackTitle.length > 0)
        if (idx === -1) idx = 0
        selectedIndex = idx
        _selectedPlayer = players[idx]
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
        if (i >= 0 && i < players.length) {
            selectedIndex = i
            _selectedPlayer = players[i]
        }
    }

    function cycleNext() {
        if (players.length === 0) return
        selectedIndex = (selectedIndex + 1) % players.length
        _selectedPlayer = players[selectedIndex]
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
                if (idx >= 0) {
                    root.selectedIndex = idx
                    root._selectedPlayer = ytm
                }
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
            if (idx >= 0) {
                selectedIndex = idx
                _selectedPlayer = existing
            }
            return
        }
        pendingYTMAutoPlay = true
        ytmusicProc.running = true
        ytmHideProc.running = true
    }

    // Reactive count — QML tracks each pl.isPlaying access, so this re-evaluates
    // automatically whenever any player starts or stops.
    readonly property int _playingCount: {
        let n = 0
        for (const pl of players) if (pl.isPlaying) n++
        return n
    }

    // Previous snapshot used to identify which player newly started
    property var _prevPlaying: []

    on_PlayingCountChanged: {
        const nowPlaying = players.filter(p => p.isPlaying)
        const prevSet = new Set(root._prevPlaying)
        const newStarters = nowPlaying.filter(p => !prevSet.has(p))

        // Update snapshot before making changes (avoids stale reads on re-entry)
        root._prevPlaying = nowPlaying

        if (newStarters.length === 0) return

        // Pause everything that was already playing before this change
        for (const pl of nowPlaying) {
            if (!newStarters.includes(pl) && pl.canPause)
                pl.isPlaying = false
        }

        // Auto-select the newly playing player
        if (newStarters.length === 1) {
            const idx = players.indexOf(newStarters[0])
            if (idx >= 0) { root.selectedIndex = idx; root._selectedPlayer = newStarters[0] }
        }
    }

    property Connections playersConn: Connections {
        target: Mpris.players
        function onValuesChanged() {
            if (root._selectedPlayer !== null) {
                const newIdx = root.players.indexOf(root._selectedPlayer)
                if (newIdx !== -1) {
                    root.selectedIndex = newIdx
                } else {
                    root.selectedIndex = -1
                    root._selectedPlayer = null
                }
            }
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

    Component.onCompleted: {
        autoSelect()
        _prevPlaying = players.filter(p => p.isPlaying)
    }
}
