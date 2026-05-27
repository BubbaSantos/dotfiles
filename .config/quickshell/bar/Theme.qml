pragma Singleton
import QtQuick
import Quickshell
import qs.services

Singleton {

    function _scheme(name) {
        if (name === "wallpaper" && SettingsStore.wallpaperColors)
            return SettingsStore.wallpaperColors
        const s = ({
            "gruvbox-dark": {
                bg:"#282828", bg1:"#3c3836", bg2:"#504945",
                fg:"#ebdbb2", fgR:0.922, fgG:0.859, fgB:0.698,
                bgR:0.157, bgG:0.157, bgB:0.157,
                yellow:"#d79921", brightYellow:"#fabd2f",
                red:"#fb4934", green:"#8ec07c",
                aqua:"#689d6a", brightAqua:"#8ec07c",
                blue:"#83a598", purple:"#b16286", gray:"#928374"
            },
            "catppuccin-mocha": {
                bg:"#1e1e2e", bg1:"#313244", bg2:"#45475a",
                fg:"#cdd6f4", fgR:0.804, fgG:0.839, fgB:0.957,
                bgR:0.118, bgG:0.118, bgB:0.180,
                yellow:"#f9e2af", brightYellow:"#f9e2af",
                red:"#f38ba8", green:"#a6e3a1",
                aqua:"#94e2d5", brightAqua:"#94e2d5",
                blue:"#89b4fa", purple:"#cba4f7", gray:"#9399b2"
            },
            "nord": {
                bg:"#2e3440", bg1:"#3b4252", bg2:"#434c5e",
                fg:"#eceff4", fgR:0.925, fgG:0.937, fgB:0.957,
                bgR:0.180, bgG:0.204, bgB:0.251,
                yellow:"#ebcb8b", brightYellow:"#ebcb8b",
                red:"#bf616a", green:"#a3be8c",
                aqua:"#8fbcbb", brightAqua:"#8fbcbb",
                blue:"#88c0d0", purple:"#b48ead", gray:"#636e85"
            },
            "tokyo-night": {
                bg:"#1a1b26", bg1:"#24283b", bg2:"#292e42",
                fg:"#c0caf5", fgR:0.753, fgG:0.792, fgB:0.961,
                bgR:0.102, bgG:0.106, bgB:0.149,
                yellow:"#e0af68", brightYellow:"#e0af68",
                red:"#f7768e", green:"#9ece6a",
                aqua:"#7dcfff", brightAqua:"#7dcfff",
                blue:"#7aa2f7", purple:"#bb9af7", gray:"#565f89"
            },
            "dracula": {
                bg:"#282a36", bg1:"#44475a", bg2:"#6272a4",
                fg:"#f8f8f2", fgR:0.973, fgG:0.973, fgB:0.949,
                bgR:0.157, bgG:0.165, bgB:0.212,
                yellow:"#f1fa8c", brightYellow:"#f1fa8c",
                red:"#ff5555", green:"#50fa7b",
                aqua:"#8be9fd", brightAqua:"#8be9fd",
                blue:"#8be9fd", purple:"#bd93f9", gray:"#6272a4"
            }
        })
        return s[name] || s["gruvbox-dark"]
    }

    readonly property var _s: {
        const _wc = SettingsStore.wallpaperColors  // always track as dependency
        return _scheme(SettingsStore.colorScheme)
    }

    // Colors
    readonly property color bg:           _s.bg
    readonly property color bg1:          _s.bg1
    readonly property color bg2:          _s.bg2
    readonly property color fg:           _s.fg
    readonly property color fgDim:        Qt.rgba(_s.fgR, _s.fgG, _s.fgB, 0.6)
    readonly property color fgVeryDim:    Qt.rgba(_s.fgR, _s.fgG, _s.fgB, 0.25)
    readonly property color yellow:       _s.yellow
    readonly property color brightYellow: _s.brightYellow
    readonly property color red:          _s.red
    readonly property color green:        _s.green
    readonly property color aqua:         _s.aqua
    readonly property color brightAqua:   _s.brightAqua
    readonly property color blue:         _s.blue
    readonly property color purple:       _s.purple
    readonly property color gray:         _s.gray

    // Bar background (uses barOpacity — for bar pill groups and the OSD)
    readonly property color barBg:    Qt.rgba(_s.bgR, _s.bgG, _s.bgB, SettingsStore.barOpacity)
    // Widget/popup background (uses widgetOpacity — for all popup cards)
    readonly property color popupBg:  Qt.rgba(_s.bgR, _s.bgG, _s.bgB, SettingsStore.widgetOpacity)

    // Layout
    readonly property int barHeight:     SettingsStore.barHeight
    readonly property int barMargin:     SettingsStore.barMargin
    readonly property int groupRadius:   SettingsStore.groupRadius
    readonly property int modulePadding: 8

    // Fonts
    readonly property string fontFamily: SettingsStore.fontFamily
    readonly property int fontSize:      SettingsStore.fontSize
    readonly property int fontSizeSmall: Math.max(8, SettingsStore.fontSize - 2)
    readonly property int fontSizeIcon:  SettingsStore.fontSize + 2

    // Animation
    readonly property int _baseAnim: {
        switch (SettingsStore.animSpeed) {
            case "off":  return 0
            case "fast": return 80
            case "slow": return 300
            default:     return 150
        }
    }
    readonly property int animFast:   _baseAnim
    readonly property int animNormal: Math.round(_baseAnim * 1.7)
    readonly property int animSlow:   Math.round(_baseAnim * 2.3)

    readonly property bool nowPlayingScroll: SettingsStore.nowPlayingScroll
}
