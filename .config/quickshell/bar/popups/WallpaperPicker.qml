import "."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.services

PanelWindow {
    id: root
    visible: false
    color: "transparent"

    anchors.top:    true
    anchors.left:   true
    anchors.right:  true
    anchors.bottom: true

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    GlobalShortcut {
        name: "toggleWallpaperPicker"
        onPressed: root.toggle()
    }

    function toggle() { if (visible) close(); else open_() }
    function open_() {
        wallpapers = []
        focusIndex = 0
        currentProc.running = true
        scanProc.running = true
        visible = true
    }
    function close() { visible = false }

    onVisibleChanged: if (visible) PopupManager.open(root)

    property var    wallpapers:       []
    property string currentWallpaper: ""
    property bool   applying:         false
    property int    focusIndex:       0

    // Jump to current wallpaper once scan completes
    onWallpapersChanged: {
        if (wallpapers.length === 0) return
        const idx = wallpapers.indexOf(currentWallpaper)
        focusIndex = idx >= 0 ? idx : 0
        Qt.callLater(function() {
            thumbGrid.positionViewAtIndex(focusIndex, GridView.Center)
        })
    }

    readonly property string home: Quickshell.env("HOME")

    // ── Resolve current wallpaper ─────────────────────────────────────────
    Process {
        id: currentProc
        command: ["readlink", "-f", root.home + "/.config/omarchy/current/background"]
        stdout: StdioCollector {
            onStreamFinished: root.currentWallpaper = text.trim()
        }
    }

    // ── Scan wallpaper directories ────────────────────────────────────────
    Process {
        id: scanProc
        command: [
            "sh", "-c",
            "find -L " +
            root.home + "/.config/omarchy/current/theme/backgrounds " +
            root.home + "/.config/omarchy/backgrounds " +
            root.home + "/Pictures/Wallpapers " +
            "-maxdepth 2 -type f " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) " +
            "2>/dev/null | sort -u"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.length > 0)
                root.wallpapers = lines
            }
        }
    }

    // ── Apply wallpaper ───────────────────────────────────────────────────
    Process {
        id: applyProc
        onExited: function(code) { root.applying = false }
    }
    Process {
        id: colorProc
        onExited: function(code) {
            if (code === 0) colorReadProc.running = true
        }
    }
    Process {
        id: colorReadProc
        command: ["cat", root.home + "/.config/noctalia/colors.json"]
        stdout: StdioCollector {
            onStreamFinished: SettingsStore._parseWallpaperColors(text)
        }
    }

    function applyWallpaper(path) {
        root.applying = true
        root.currentWallpaper = path
        applyProc.command = [
            "sh", "-c",
            "ln -nsf '" + path + "' " + root.home + "/.config/omarchy/current/background && " +
            "pkill -x swaybg 2>/dev/null; " +
            "awww img '" + path + "' --transition-type center --transition-duration 1.5 --transition-fps 60 2>/dev/null || " +
            "(setsid uwsm-app -- swaybg -i '" + path + "' -m fill >/dev/null 2>&1 &)"
        ]
        applyProc.running = true
        colorProc.command = [
            "sh", "-c",
            "python3 /etc/xdg/quickshell/noctalia-shell/Scripts/python/src/theming/template-processor.py " +
            "'" + path + "' --dark 2>/dev/null | " +
            "jq '.dark | {mSurface:.surface,mSurfaceVariant:.surface_variant,mHover:.surface_container_high," +
            "mOnSurface:.on_surface,mOnSurfaceVariant:.on_surface_variant,mOutline:.outline," +
            "mPrimary:.primary,mOnPrimary:.on_primary,mSecondary:.secondary,mOnSecondary:.on_secondary," +
            "mTertiary:.tertiary,mOnTertiary:.on_tertiary,mError:.error,mOnError:.on_error,mShadow:.shadow}' " +
            "> " + root.home + "/.config/noctalia/colors.json"
        ]
        colorProc.running = true
        root.close()
    }

    // ── Backdrop ──────────────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    // ── Card ──────────────────────────────────────────────────────────────
    Rectangle {
        id: card
        anchors.centerIn: parent
        width:  Math.min(parent.width  - 80, 720)
        height: Math.min(parent.height - 80, 540)
        radius: 12
        color:  Theme.popupBg
        border.color: Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        MouseArea { anchors.fill: parent; onClicked: {} }

        // ── Keyboard navigation ───────────────────────────────────────────
        Item {
            anchors.fill: parent
            focus: root.visible

            Keys.onPressed: function(ev) {
                const total = root.wallpapers.length
                const cols  = thumbGrid.cols
                if (total === 0) {
                    if (ev.key === Qt.Key_Escape) { root.close(); ev.accepted = true }
                    return
                }
                if (ev.key === Qt.Key_Escape) {
                    root.close(); ev.accepted = true
                } else if (ev.key === Qt.Key_Left || ev.key === Qt.Key_H) {
                    root.focusIndex = Math.max(0, root.focusIndex - 1)
                    thumbGrid.positionViewAtIndex(root.focusIndex, GridView.Visible)
                    ev.accepted = true
                } else if (ev.key === Qt.Key_Right || ev.key === Qt.Key_L) {
                    root.focusIndex = Math.min(total - 1, root.focusIndex + 1)
                    thumbGrid.positionViewAtIndex(root.focusIndex, GridView.Visible)
                    ev.accepted = true
                } else if (ev.key === Qt.Key_Up || ev.key === Qt.Key_K) {
                    root.focusIndex = Math.max(0, root.focusIndex - cols)
                    thumbGrid.positionViewAtIndex(root.focusIndex, GridView.Visible)
                    ev.accepted = true
                } else if (ev.key === Qt.Key_Down || ev.key === Qt.Key_J) {
                    root.focusIndex = Math.min(total - 1, root.focusIndex + cols)
                    thumbGrid.positionViewAtIndex(root.focusIndex, GridView.Visible)
                    ev.accepted = true
                } else if (ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter || ev.key === Qt.Key_Space) {
                    if (root.focusIndex >= 0 && root.focusIndex < total)
                        root.applyWallpaper(root.wallpapers[root.focusIndex])
                    ev.accepted = true
                }
            }
        }

        ColumnLayout {
            anchors.fill:    parent
            anchors.margins: 16
            spacing:         12

            // ── Header ────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text:           "  Wallpaper"
                    color:          Theme.fg
                    font.family:    Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 2
                    font.bold:      true
                }
                Text {
                    visible:        root.wallpapers.length > 0
                    text:           root.wallpapers.length + " found"
                    color:          Theme.fgVeryDim
                    font.family:    Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                }
                Item { Layout.fillWidth: true }
                Text {
                    text:           "↑↓←→ navigate · ↵ apply"
                    color:          Theme.fgVeryDim
                    font.family:    Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    visible:        root.wallpapers.length > 0
                }
                Text {
                    text:           "✕"
                    color:          Theme.fgDim
                    font.family:    Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 2
                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    root.close()
                    }
                }
            }

            // ── Loading state ─────────────────────────────────────────────
            Item {
                visible:              root.wallpapers.length === 0
                Layout.fillWidth:     true
                Layout.fillHeight:    true

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text:             "Scanning…"
                        color:            Theme.fgDim
                        font.family:      Theme.fontFamily
                        font.pixelSize:   Theme.fontSize
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text:             "This may take a moment for large collections"
                        color:            Theme.fgVeryDim
                        font.family:      Theme.fontFamily
                        font.pixelSize:   Theme.fontSizeSmall
                    }
                }
            }

            // ── Thumbnail grid (GridView = virtual — only renders visible cells) ──
            GridView {
                id: thumbGrid
                visible:          root.wallpapers.length > 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip:             true
                model:            root.wallpapers
                cacheBuffer:      cellHeight * 2   // pre-load 2 rows outside viewport

                readonly property int cols:    4
                readonly property int spacing: 8

                cellWidth:  Math.floor(width / cols)
                cellHeight: Math.round((cellWidth - spacing) * 9 / 16) + spacing

                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                delegate: Item {
                    required property string modelData
                    required property int    index

                    readonly property string wPath:     modelData
                    readonly property bool   isCurrent: root.currentWallpaper === wPath
                    readonly property bool   isFocused: root.focusIndex === index

                    width:  thumbGrid.cellWidth  - thumbGrid.spacing
                    height: thumbGrid.cellHeight - thumbGrid.spacing

                    Rectangle {
                        id:           thumb
                        anchors.fill: parent
                        radius:       7
                        color:        Theme.bg1
                        clip:         true

                        // Current wallpaper: yellow border; keyboard focus: aqua border; default: subtle
                        border.color: isCurrent ? Theme.yellow
                                                : (isFocused ? Theme.aqua : Qt.rgba(1, 1, 1, 0.05))
                        border.width: (isCurrent || isFocused) ? 2 : 1

                        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
                        Behavior on scale        { NumberAnimation { duration: Theme.animFast } }

                        Image {
                            anchors.fill:      parent
                            anchors.margins:   (isCurrent || isFocused) ? 2 : 1
                            source:            "file://" + wPath
                            fillMode:          Image.PreserveAspectCrop
                            smooth:            true
                            asynchronous:      true
                            sourceSize.width:  240
                            sourceSize.height: 135

                            // Loading placeholder
                            Rectangle {
                                anchors.fill: parent
                                visible:      parent.status === Image.Loading
                                color:        Theme.bg1
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 24; height: 24; radius: 12
                                    color: Qt.rgba(1, 1, 1, 0.07)
                                }
                            }
                        }

                        // Current indicator
                        Rectangle {
                            visible:         isCurrent
                            anchors.top:     parent.top
                            anchors.right:   parent.right
                            anchors.margins: 4
                            width: 16; height: 16; radius: 8
                            color: Theme.yellow
                            Text {
                                anchors.centerIn: parent
                                text:             "✓"
                                color:            Theme.bg
                                font.pixelSize:   9
                                font.bold:        true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape:  Qt.PointingHandCursor
                            hoverEnabled: true
                            onEntered:    { thumb.scale = 1.04; root.focusIndex = index }
                            onExited:     thumb.scale = 1.0
                            onClicked:    root.applyWallpaper(wPath)
                        }
                    }
                }
            }
        }
    }
}
