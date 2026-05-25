pragma Singleton
import QtQuick
import Quickshell

Singleton {
    // Gruvbox palette (matches your Waybar)
    readonly property color bg:         "#282828"  // bg0
    readonly property color bg1:        "#3c3836"
    readonly property color bg2:        "#504945"
    readonly property color fg:         "#ebdbb2"
    readonly property color fgDim:      Qt.rgba(0.92, 0.86, 0.70, 0.6)
    readonly property color fgVeryDim:  Qt.rgba(0.92, 0.86, 0.70, 0.25)

    readonly property color yellow:     "#d79921"
    readonly property color brightYellow:"#fabd2f"
    readonly property color red:        "#fb4934"
    readonly property color green:      "#8ec07c"
    readonly property color aqua:       "#689d6a"
    readonly property color brightAqua: "#8ec07c"
    readonly property color blue:       "#83a598"
    readonly property color purple:     "#b16286"
    readonly property color gray:       "#928374"

    // Transparency for the bar background (matches 0.98 in your CSS)
    readonly property color barBg:      Qt.rgba(0.157, 0.157, 0.157, 0.98)

    // Layout
    readonly property int barHeight:    28
    readonly property int barMargin:    6
    readonly property int groupRadius:  10
    readonly property int modulePadding: 8

    // Fonts
    readonly property string fontFamily: "JetBrainsMonoNL Nerd Font"
    readonly property int fontSize:     12
    readonly property int fontSizeSmall: 10
    readonly property int fontSizeIcon: 14

    // Animation
    readonly property int animFast:     150
    readonly property int animNormal:   250
    readonly property int animSlow:     350
}
