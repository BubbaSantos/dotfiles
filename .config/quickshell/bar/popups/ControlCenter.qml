import "."
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

PopupWindow {
    popupWidth: 320
    popupHeight: 200

    ColumnLayout {
        anchors.fill: parent
        spacing: 8
        Text {
            text: "Calendar"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 16
            font.bold: true
        }
        Text {
            text: "(stub — to be built)"
            color: Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }
    }
}
