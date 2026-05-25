import "."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs
import qs.services

PopupWindow {
    id: root
    popupWidth: 420
    popupHeight: 280

    readonly property var p: ActivePlayer.player

    function formatTime(s) {
        if (!s || s < 0) return "0:00"
        const m = Math.floor(s / 60)
        const sec = Math.floor(s % 60).toString().padStart(2, "0")
        return `${m}:${sec}`
    }

    FrameAnimation {
        running: root.visible && root.p && root.p.playbackState === MprisPlaybackState.Playing
        onTriggered: if (root.p) root.p.positionChanged()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        // --- TOP: art + title block ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Rectangle {
                Layout.preferredWidth: 90
                Layout.preferredHeight: 90
                radius: 10
                color: Theme.bg1
                clip: true

                Image {
                    anchors.fill: parent
                    source: root.p ? (root.p.trackArtUrl || "") : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                    visible: status === Image.Ready
                }
                Text {
                    anchors.centerIn: parent
                    text: ""
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 32
                    visible: !root.p || !root.p.trackArtUrl
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    Layout.fillWidth: true
                    text: root.p ? (root.p.trackTitle || "Unknown") : ""
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    font.bold: true
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: root.p ? (root.p.trackArtist || "") : ""
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: root.p ? (root.p.trackAlbum || "") : ""
                    color: Theme.gray
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    visible: text.length > 0
                }
                Item { Layout.fillHeight: true }
                Text {
                    text: root.p ? (root.p.identity || "") : ""
                    color: Theme.gray
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
            }
        }

        // --- SCRUBBER ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            visible: root.p && root.p.lengthSupported

            Rectangle {
                id: scrubBar
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                color: Theme.bg2
                radius: 2

                Rectangle {
                    height: parent.height
                    width: parent.width * (root.p && root.p.length > 0
                                           ? (root.p.position / root.p.length) : 0)
                    color: Theme.yellow
                    radius: 2
                    Behavior on width { NumberAnimation { duration: 200 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (ev) => {
                        if (!root.p || !root.p.canSeek) return
                        const ratio = ev.x / width
                        root.p.position = root.p.length * ratio
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: root.p ? root.formatTime(root.p.position) : "0:00"
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.p ? root.formatTime(root.p.length) : "0:00"
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
            }
        }

        // --- CONTROLS ---
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 18

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 16
                color: prevMouse.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Text {
                    anchors.centerIn: parent
                    text: "󰒮"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 20
                }
                MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.p) root.p.previous()
                }
            }

            Rectangle {
                Layout.preferredWidth: 44
                Layout.preferredHeight: 44
                radius: 22
                color: ppMouse.containsMouse ? Theme.brightYellow : Theme.yellow
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Text {
                    anchors.centerIn: parent
                    text: ActivePlayer.isPlaying ? "󰏤" : "󰐊"
                    color: Theme.bg
                    font.family: Theme.fontFamily
                    font.pixelSize: 22
                }
                MouseArea {
                    id: ppMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.p) root.p.playPause()
                }
            }

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 16
                color: nextMouse.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Text {
                    anchors.centerIn: parent
                    text: "󰒭"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 20
                }
                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.p) root.p.next()
                }
            }

            Item { Layout.fillWidth: true }
        }

        // --- CAVA VISUALISER ---
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 40

            Row {
                anchors.fill: parent
                spacing: 2

                Repeater {
                    model: Cava.barCount
                    delegate: Rectangle {
                        required property int index
                        width: (parent.width - (Cava.barCount - 1) * 2) / Cava.barCount
                        height: parent.height * (Cava.bars[index] || 0)
                        anchors.bottom: parent.bottom
                        radius: 2
                        color: Theme.purple
                        opacity: ActivePlayer.isPlaying ? 0.9 : 0.3
                        Behavior on height { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                    }
                }
            }
        }
    }
}
