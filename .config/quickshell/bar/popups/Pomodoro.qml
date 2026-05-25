import "."
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

PopupWindow {
    popupWidth: 360
    popupHeight: 380
    function open_() { visible = true }

    ColumnLayout {
        anchors.fill: parent
        Text {
            text: "Pomodoro — coming next"
            color: Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: 12
            Layout.alignment: Qt.AlignCenter
        }
    }
}
