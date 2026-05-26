pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string filePath: Quickshell.env("HOME") + "/Dropbox/quickshell/bar-settings.json"
    readonly property string wallpaperColorsPath: Quickshell.env("HOME") + "/.config/noctalia/colors.json"

    // Appearance
    property string colorScheme:   "gruvbox-dark"
    property real   barOpacity:    0.98   // bar pill backgrounds only
    property real   widgetOpacity: 0.97   // popup/widget card backgrounds

    // Wallpaper-derived colors (loaded from noctalia/colors.json)
    property var wallpaperColors: null

    // Layout
    property string barStyle:    "floating"  // "floating" | "unified"
    property string barPosition: "top"        // "top" | "bottom"
    property int    barHeight:   28
    property int    barMargin:   6
    property int    groupRadius: 10

    // Font
    property int    fontSize:   12
    property string fontFamily: "JetBrainsMonoNL Nerd Font"

    // Behaviour
    property string animSpeed:        "normal"
    property bool   nowPlayingScroll: true
    property int    osdDuration:      1500

    // Module visibility
    property bool showNowPlaying:    true
    property bool showTray:          true
    property bool showNetwork:       true
    property bool showBluetooth:     true
    property bool showReminders:     true
    property bool showTodos:         true
    property bool showNotifications: true
    property bool showClock:         true
    property bool showBattery:       true

    property bool loaded: false

    function save() { saveTimer.restart() }

    function _doSave() {
        const payload = JSON.stringify({
            colorScheme:   root.colorScheme,
            barOpacity:    root.barOpacity,
            widgetOpacity: root.widgetOpacity,
            barStyle:      root.barStyle,
            barPosition:   root.barPosition,
            barHeight:     root.barHeight,
            barMargin:     root.barMargin,
            groupRadius:   root.groupRadius,
            fontSize:      root.fontSize,
            fontFamily:    root.fontFamily,
            animSpeed:     root.animSpeed,
            nowPlayingScroll: root.nowPlayingScroll,
            osdDuration:   root.osdDuration,
            showNowPlaying:    root.showNowPlaying,
            showTray:          root.showTray,
            showNetwork:       root.showNetwork,
            showBluetooth:     root.showBluetooth,
            showReminders:     root.showReminders,
            showTodos:         root.showTodos,
            showNotifications: root.showNotifications,
            showClock:         root.showClock,
            showBattery:       root.showBattery
        }, null, 2)

        const s = "SETTINGS_EOF_" + Math.floor(Math.random() * 1e9)
        saveProc.command = ["sh", "-c",
            `mkdir -p "$(dirname '${root.filePath}')" && cat > '${root.filePath}' << '${s}'\n${payload}\n${s}`
        ]
        saveProc.running = true
    }

    property Timer saveTimer: Timer {
        interval: 250
        onTriggered: root._doSave()
    }

    property Process saveProc: Process {}

    property Process loadProc: Process {
        command: ["cat", root.filePath]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim().length === 0) { root.loaded = true; return }
                try {
                    const d = JSON.parse(text)
                    if (d.colorScheme)   root.colorScheme   = d.colorScheme
                    if (typeof d.barOpacity    === "number") root.barOpacity    = d.barOpacity
                    if (typeof d.widgetOpacity === "number") root.widgetOpacity = d.widgetOpacity
                    if (d.barStyle)      root.barStyle      = d.barStyle
                    if (d.barPosition)   root.barPosition   = d.barPosition
                    if (typeof d.barHeight     === "number") root.barHeight     = d.barHeight
                    if (typeof d.barMargin     === "number") root.barMargin     = d.barMargin
                    if (typeof d.groupRadius   === "number") root.groupRadius   = d.groupRadius
                    if (typeof d.fontSize      === "number") root.fontSize      = d.fontSize
                    if (d.fontFamily)    root.fontFamily    = d.fontFamily
                    if (d.animSpeed)     root.animSpeed     = d.animSpeed
                    if (typeof d.nowPlayingScroll === "boolean") root.nowPlayingScroll = d.nowPlayingScroll
                    if (typeof d.osdDuration   === "number") root.osdDuration   = d.osdDuration
                    if (typeof d.showNowPlaying    === "boolean") root.showNowPlaying    = d.showNowPlaying
                    if (typeof d.showTray          === "boolean") root.showTray          = d.showTray
                    if (typeof d.showNetwork       === "boolean") root.showNetwork       = d.showNetwork
                    if (typeof d.showBluetooth     === "boolean") root.showBluetooth     = d.showBluetooth
                    if (typeof d.showReminders     === "boolean") root.showReminders     = d.showReminders
                    if (typeof d.showTodos         === "boolean") root.showTodos         = d.showTodos
                    if (typeof d.showNotifications === "boolean") root.showNotifications = d.showNotifications
                    if (typeof d.showClock         === "boolean") root.showClock         = d.showClock
                    if (typeof d.showBattery       === "boolean") root.showBattery       = d.showBattery
                } catch(e) { console.warn("SettingsStore: parse error", e) }
                root.loaded = true
            }
        }
        onExited: function(code) { if (code !== 0) root.loaded = true }
    }

    function _parseWallpaperColors(rawText) {
        const text = typeof rawText === "string" ? rawText : (typeof rawText === "function" ? rawText() : "")
        if (!text || text.trim().length === 0) return
        try {
            const d = JSON.parse(text)
            function h(hex) {
                if (!hex || hex.length < 7) return { r: 0.5, g: 0.5, b: 0.5 }
                return {
                    r: parseInt(hex.slice(1,3), 16) / 255,
                    g: parseInt(hex.slice(3,5), 16) / 255,
                    b: parseInt(hex.slice(5,7), 16) / 255
                }
            }
            const bg  = d.mSurface        || "#1a1a1a"
            const bg1 = d.mSurfaceVariant || "#2a2a2a"
            const bg2 = d.mHover          || "#3a3a3a"
            const fg  = d.mOnSurface      || "#e0e0e0"
            const bgC = h(bg), fgC = h(fg)
            root.wallpaperColors = {
                bg: bg, bg1: bg1, bg2: bg2,
                fg: fg,
                fgR: fgC.r, fgG: fgC.g, fgB: fgC.b,
                bgR: bgC.r, bgG: bgC.g, bgB: bgC.b,
                yellow:      d.mPrimary   || "#d79921",
                brightYellow:d.mPrimary   || "#fabd2f",
                red:         d.mError     || "#fb4934",
                green:       d.mTertiary  || "#8ec07c",
                aqua:        d.mSecondary || "#689d6a",
                brightAqua:  d.mSecondary || "#8ec07c",
                blue:        d.mSecondary || "#83a598",
                purple:      d.mTertiary  || "#b16286",
                gray:        d.mOutline   || "#928374"
            }
        } catch(e) { console.warn("SettingsStore: wallpaper colors parse error", e) }
    }

    // Reads colors.json once at startup
    property Process wallpaperLoadProc: Process {
        command: ["cat", root.wallpaperColorsPath]
        stdout: StdioCollector {
            onStreamFinished: root._parseWallpaperColors(text)
        }
    }

    // Watches noctalia/colors.json with inotify — re-parses automatically on wallpaper change
    property FileView wallpaperFileView: FileView {
        path: root.wallpaperColorsPath
        watchChanges: true
        onTextChanged: root._parseWallpaperColors(text)
    }

    Component.onCompleted: {
        loadProc.running = true
        wallpaperLoadProc.running = true
    }
}
