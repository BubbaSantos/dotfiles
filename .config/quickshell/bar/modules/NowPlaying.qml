import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.popups

Rectangle {
    id: root
    Layout.preferredHeight: 22
    Layout.preferredWidth: ActivePlayer.hasPlayer ? row.implicitWidth + 16 : 0
    visible: ActivePlayer.hasPlayer
    color: mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
    radius: 6

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on Layout.preferredWidth { NumberAnimation { duration: Theme.animNormal } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: ActivePlayer.isPlaying ? "" : ""
            color: ActivePlayer.isPlaying ? Theme.fg : Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
        Text {
            text: {
                if (!ActivePlayer.hasPlayer) return ""
                const p = ActivePlayer.player
                const title = p.trackTitle || "Unknown"
                const artist = p.trackArtist || ""
                return artist ? `${artist} — ${title}` : title
            }
            color: ActivePlayer.isPlaying ? Theme.fg : Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            elide: Text.ElideRight
            Layout.maximumWidth: 280
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: (ev) => {
            if (!ActivePlayer.hasPlayer) return
            if (ev.button === Qt.LeftButton) mediaPopup.toggle()
            else if (ev.button === Qt.RightButton) ActivePlayer.player.next()
            else if (ev.button === Qt.MiddleButton) ActivePlayer.player.playPause()
        }
    }

    MediaPlayer { id: mediaPopup; anchorItem: root }
}
