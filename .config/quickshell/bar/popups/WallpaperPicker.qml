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
        currentProc.running = true
        scanProc.running = true
        visible = true
    }
    function close() { visible = false }

    onVisibleChanged: if (visible) PopupManager.open(root)

    property var    wallpapers:       []
    property string currentWallpaper: ""
    property bool   applying:         false

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

    // ── Apply wallpaper (awww transition + swaybg fallback) ───────────────
    Process {
        id: applyProc
        onExited: function(code) { root.applying = false }
    }
    Process { id: colorProc  }

    function applyWallpaper(path) {
        root.applying = true
        root.currentWallpaper = path

        // Update symlink then use awww for the transition; fall back to swaybg
        applyProc.command = [
            "sh", "-c",
            "ln -nsf '" + path + "' " + root.home + "/.config/omarchy/current/background && " +
            "pkill -x swaybg 2>/dev/null; " +
            "awww img '" + path + "' --transition-type center --transition-duration 1.5 --transition-fps 60 2>/dev/null || " +
            "(setsid uwsm-app -- swaybg -i '" + path + "' -m fill >/dev/null 2>&1 &)"
        ]
        applyProc.running = true

        // Re-generate colors.json from the new wallpaper (remap to mXxx keys)
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

        ColumnLayout {
            anchors.fill:    parent
            anchors.margins: 16
            spacing:         12

            // ── Header ────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text:            "  Wallpaper"
                    color:           Theme.fg
                    font.family:     Theme.fontFamily
                    font.pixelSize:  Theme.fontSize + 2
                    font.bold:       true
                }
                Item { Layout.fillWidth: true }
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

            // ── Empty / loading state ─────────────────────────────────────
            Text {
                visible:        root.wallpapers.length === 0
                Layout.alignment: Qt.AlignHCenter
                text:           "Scanning…"
                color:          Theme.fgDim
                font.family:    Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }

            // ── Thumbnail grid ────────────────────────────────────────────
            Flickable {
                Layout.fillWidth:  true
                Layout.fillHeight: true
                contentHeight:     thumbGrid.implicitHeight + 4
                clip:              true

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                Grid {
                    id:      thumbGrid
                    width:   parent.width - 12
                    columns: 4
                    spacing: 8

                    Repeater {
                        model: root.wallpapers
                        delegate: Item {
                            required property string modelData
                            required property int    index

                            property string wPath:     modelData
                            property bool   isCurrent: root.currentWallpaper === wPath

                            width:  (thumbGrid.width - thumbGrid.spacing * (thumbGrid.columns - 1)) / thumbGrid.columns
                            height: Math.round(width * 9 / 16)

                            Rectangle {
                                id:           thumb
                                anchors.fill: parent
                                radius:       7
                                color:        Theme.bg1
                                clip:         true
                                border.color: isCurrent ? Theme.yellow : Qt.rgba(1, 1, 1, 0.05)
                                border.width: isCurrent ? 2 : 1

                                Image {
                                    anchors.fill:         parent
                                    anchors.margins:      isCurrent ? 2 : 1
                                    source:               "file://" + wPath
                                    fillMode:             Image.PreserveAspectCrop
                                    smooth:               true
                                    asynchronous:         true
                                    sourceSize.width:     240
                                    sourceSize.height:    135

                                    Rectangle {
                                        anchors.fill: parent
                                        color:        "transparent"
                                        visible:      parent.status === Image.Loading
                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 20; height: 20; radius: 10
                                            color: Qt.rgba(1,1,1,0.1)
                                        }
                                    }
                                }

                                // Current indicator checkmark
                                Rectangle {
                                    visible:           isCurrent
                                    anchors.top:       parent.top
                                    anchors.right:     parent.right
                                    anchors.margins:   4
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

                                Behavior on scale { NumberAnimation { duration: Theme.animFast } }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape:  Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onEntered:    thumb.scale = 1.04
                                    onExited:     thumb.scale = 1.0
                                    onClicked:    root.applyWallpaper(wPath)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
