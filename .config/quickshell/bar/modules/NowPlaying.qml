import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import qs
import qs.services
import qs.popups

Rectangle {
    id: root
    Layout.preferredHeight: 22
    Layout.preferredWidth: row.implicitWidth + 12
    color: mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
    radius: 6

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on Layout.preferredWidth { NumberAnimation { duration: Theme.animFast } }

    readonly property var sink:   Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property real vol:      sink   ? sink.audio.volume   : 0
    readonly property bool muted:    sink   ? sink.audio.muted    : false
    readonly property bool micMuted: source ? source.audio.muted  : false

    PwObjectTracker {
        objects: {
            const list = []
            if (root.sink)   list.push(root.sink)
            if (root.source) list.push(root.source)
            return list
        }
    }

    // Guard so we don't flash the OSD on initial load
    property bool _volReady: false
    Component.onCompleted: _volReady = true
    onVolChanged:   if (_volReady) volOsd.show()
    onMutedChanged: if (_volReady) volOsd.show()

    readonly property bool playerMode: ActivePlayer.hasPlayer && (
        ActivePlayer.isPlaying ||
        (ActivePlayer.trackTitle  || "").length > 0 ||
        (ActivePlayer.trackArtist || "").length > 0
    )

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        // ── Player section ────────────────────────────────────────────
        Text {
            visible: root.playerMode
            text: ActivePlayer.isPlaying ? "󰐊" : "󰏤"
            color: ActivePlayer.isPlaying ? Theme.green : Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeIcon
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        Item {
            id: titleClip
            visible: root.playerMode
            readonly property int maxW: 240
            readonly property int overflow: Math.max(0, titleText.implicitWidth - maxW)
            Layout.preferredWidth: Math.min(titleText.implicitWidth, maxW)
            Layout.alignment: Qt.AlignVCenter
            height: titleText.implicitHeight
            clip: true

            Text {
                id: titleText
                text: {
                    const t = ActivePlayer.trackTitle  || ""
                    const a = ActivePlayer.trackArtist || ""
                    if (!t && !a) return "—"
                    if (a) return a + " — " + t
                    return t
                }
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize

                onImplicitWidthChanged: {
                    scrollAnim.stop()
                    x = 0
                    if (titleClip.overflow > 0 && Theme.nowPlayingScroll) scrollAnim.start()
                }

                Connections {
                    target: Theme
                    function onNowPlayingScrollChanged() {
                        scrollAnim.stop()
                        titleText.x = 0
                        if (Theme.nowPlayingScroll && titleClip.overflow > 0) scrollAnim.start()
                    }
                }

                SequentialAnimation {
                    id: scrollAnim
                    loops: Animation.Infinite
                    PauseAnimation  { duration: 2000 }
                    NumberAnimation {
                        target: titleText; property: "x"
                        to: -titleClip.overflow
                        duration: titleClip.overflow * 30
                        easing.type: Easing.Linear
                    }
                    PauseAnimation  { duration: 1500 }
                    NumberAnimation { target: titleText; property: "x"; to: 0; duration: 0 }
                }
            }
        }

        // Divider
        Rectangle {
            visible: root.playerMode
            width: 1; height: 10
            color: Qt.rgba(1, 1, 1, 0.2)
            Layout.alignment: Qt.AlignVCenter
        }

        // ── Volume section ────────────────────────────────────────────
        Text {
            text: root.muted ? "󰝟" : root.vol > 0.6 ? "󰕾" : root.vol > 0.2 ? "󰖀" : "󰕿"
            color: root.muted ? Theme.red : Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeIcon
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }

        Text {
            id: volPctText
            text: root.muted ? "muted" : Math.round(root.vol * 100) + "%"
            color: root.muted ? Theme.red : Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        // ── Mic muted indicator ───────────────────────────────────────
        Text {
            visible: root.micMuted
            text: "·"
            color: Qt.rgba(1, 1, 1, 0.3)
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeIcon
        }

        Text {
            visible: root.micMuted
            text: "󰍭"
            color: Theme.red
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeIcon
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onClicked: function(ev) {
            const p = ActivePlayer.current
            if (ev.button === Qt.LeftButton) {
                if (root.playerMode && p && p.canTogglePlaying)
                    p.isPlaying = !p.isPlaying
                else if (root.sink)
                    root.sink.audio.muted = !root.sink.audio.muted
            } else if (ev.button === Qt.RightButton) {
                mediaPopup.toggle()
            } else if (ev.button === Qt.MiddleButton) {
                if (p && p.canGoNext) p.next()
            }
        }

        onWheel: function(ev) {
            if (!root.sink) return
            const delta = ev.angleDelta.y > 0 ? 0.05 : -0.05
            root.sink.audio.volume = Math.max(0, Math.min(1.5, root.vol + delta))
        }
    }

    MediaPlayer {
        id: mediaPopup
        anchorItem: root
    }

    GlobalShortcut {
        name: "toggleMediaPlayer"
        description: "Toggle the media player popup"
        onPressed: mediaPopup.toggle()
    }

    // ── Volume OSD ────────────────────────────────────────────────────
    PanelWindow {
        id: volOsd
        visible: false
        color: "transparent"

        anchors.top: true
        anchors.left: true
        anchors.right: true
        anchors.bottom: true

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.exclusiveZone: -1

        function show() {
            visible = true
            osdTimer.restart()
        }

        Timer {
            id: osdTimer
            interval: SettingsStore.osdDuration
            onTriggered: volOsd.visible = false
        }

        Rectangle {
            id: osdPill
            width: Math.max(root.width + 16, 180)
            height: 36
            x: {
                if (volOsd.width === 0) return 0
                const p = root.mapToItem(null, 0, 0)
                return Math.max(0, p.x - 8)
            }
            y: SettingsStore.barPosition === "top"
               ? Theme.barHeight + Theme.barMargin + 4
               : volOsd.height - Theme.barHeight - Theme.barMargin - osdPill.height - 4
            radius: Theme.groupRadius
            color: Theme.barBg
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.15)

            opacity: volOsd.visible ? 1 : 0
            scale:   volOsd.visible ? 1 : 0.95
            Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
            Behavior on scale   { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 10

                Text {
                    text: root.muted ? "󰝟" : root.vol > 0.6 ? "󰕾" : root.vol > 0.2 ? "󰖀" : "󰕿"
                    color: root.muted ? Theme.red : Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 4
                    radius: 2
                    color: Qt.rgba(1, 1, 1, 0.12)

                    Rectangle {
                        // Track fills 0–100% of bar; anything above 100% (boost) turns red
                        width: Math.max(0, parent.width * Math.min(1.5, root.vol) / 1.5)
                        height: parent.height
                        radius: parent.radius
                        color: root.vol > 1.0 ? Theme.red
                               : root.muted   ? Qt.rgba(1, 1, 1, 0.2)
                               : Theme.yellow
                        Behavior on width { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                    }
                }

                Text {
                    text: Math.round(root.vol * 100) + "%"
                    color: root.muted ? Theme.fgDim : Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                    Layout.preferredWidth: 36
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
