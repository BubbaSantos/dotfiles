pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

QtObject {
    id: root

    readonly property var player: {
        const players = Mpris.players.values
        if (!players || players.length === 0) return null
        const playing = players.find(p => p.playbackState === MprisPlaybackState.Playing)
        return playing || players[0]
    }

    readonly property bool hasPlayer: player !== null
    readonly property bool isPlaying: hasPlayer && player.playbackState === MprisPlaybackState.Playing
}
