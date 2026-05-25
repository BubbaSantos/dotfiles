import "."
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

PopupWindow {
    popupWidth: 320
    popupHeight: 220
    function open_() { visible = true }

    ColumnLayout {
        anchors.fill: parent
        Text {
            text: "Stopwatch — coming next"
            color: Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: 12
            Layout.alignment: Qt.AlignCenter
        }
    }
}
