import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
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

    function toggle() { visible = !visible }
    function close()  { visible = false    }

    Keys.onEscapePressed: close()

    GlobalShortcut {
        name: "toggleSettings"
        onPressed: root.toggle()
    }

    // ── Reusable components ────────────────────────────────────────────

    component SectionHeader: Item {
        property string text: ""
        Layout.fillWidth: true
        height: 32
        Text {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            text: parent.text
            color: Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            font.bold: true
            font.letterSpacing: 1.2
        }
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Qt.rgba(1,1,1,0.07)
        }
    }

    // Labelled row: label on left, control slot on right
    component SettingRow: RowLayout {
        property string label: ""
        property int labelWidth: 130
        Layout.fillWidth: true
        height: 36
        spacing: 12
        Text {
            text: parent.label
            color: Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            Layout.preferredWidth: parent.labelWidth
        }
    }

    // Pill/segment button
    component Pill: Rectangle {
        property string label: ""
        property bool   active: false
        property bool   enabled: true
        signal clicked()
        width: pillText.implicitWidth + 20
        height: 24
        radius: 5
        color: active ? Qt.rgba(Theme._s.fgR, Theme._s.fgG, Theme._s.fgB, 0.15)
                      : Qt.rgba(1,1,1,0.04)
        border.width: active ? 1 : 0
        border.color: Theme.yellow
        opacity: enabled ? 1.0 : 0.4
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Text {
            id: pillText
            anchors.centerIn: parent
            text: parent.label
            color: parent.active ? Theme.fg : Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: if (parent.enabled) parent.clicked()
        }
    }

    // Toggle switch
    component Toggle: Item {
        property bool checked: false
        signal toggled()
        width: 36; height: 20
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: parent.checked ? Theme.yellow : Qt.rgba(1,1,1,0.12)
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
            Rectangle {
                width: 14; height: 14
                radius: 7
                anchors.verticalCenter: parent.verticalCenter
                x: parent.checked ? parent.width - width - 3 : 3
                color: parent.checked ? Theme._s.bg : Qt.rgba(1,1,1,0.5)
                Behavior on x { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.toggled()
        }
    }

    // [−] value [+] stepper
    component Stepper: RowLayout {
        property int value: 0
        property int minVal: 0
        property int maxVal: 100
        property int step: 1
        property string unit: ""
        signal changed(int v)
        spacing: 4
        height: 24
        Text {
            text: "−"
            color: parent.value <= parent.minVal ? Theme.fgVeryDim : Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 2
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: if (parent.parent.value > parent.parent.minVal)
                    parent.parent.changed(parent.parent.value - parent.parent.step)
            }
        }
        Text {
            text: parent.value + parent.unit
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            Layout.preferredWidth: 36
            horizontalAlignment: Text.AlignHCenter
        }
        Text {
            text: "+"
            color: parent.value >= parent.maxVal ? Theme.fgVeryDim : Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 2
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: if (parent.parent.value < parent.parent.maxVal)
                    parent.parent.changed(parent.parent.value + parent.parent.step)
            }
        }
    }

    // Module toggle row (label + toggle)
    component ModuleRow: RowLayout {
        property string label: ""
        property bool   checked: false
        signal toggled()
        Layout.fillWidth: true
        height: 30
        spacing: 8
        Text {
            text: parent.label
            color: Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            Layout.fillWidth: true
        }
        Toggle {
            checked: parent.checked
            onToggled: parent.toggled()
        }
    }

    // ── Backdrop ───────────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    // ── Card ───────────────────────────────────────────────────────────
    Rectangle {
        id: card
        readonly property int cardW: 500
        width: cardW
        x: (root.width - cardW) / 2
        y: Theme.barHeight + Theme.barMargin + 8
        height: Math.min(cardHeader.height + scrollContent.contentHeight + 24,
                         root.height - y - 16)
        radius: 12
        color: Theme.popupBg
        border.width: 1
        border.color: Qt.rgba(1,1,1,0.1)

        layer.enabled: true
        layer.effect: null

        MouseArea { anchors.fill: parent; onClicked: {} }

        // Header
        Item {
            id: cardHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 44

            Text {
                anchors.centerIn: parent
                text: "Bar Settings"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 1
                font.bold: true
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "✕"
                color: Theme.fgDim
                font.pixelSize: Theme.fontSize
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.close()
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Qt.rgba(1,1,1,0.07)
            }
        }

        // Scrollable body
        Flickable {
            id: scrollContent
            anchors.top: cardHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 4
            clip: true
            contentWidth: width
            contentHeight: bodyCol.implicitHeight + 16
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            ColumnLayout {
                id: bodyCol
                width: scrollContent.width - 16
                x: 8
                y: 8
                spacing: 2

                // ── APPEARANCE ─────────────────────────────────────────────
                SectionHeader { text: "APPEARANCE" }

                // Color scheme
                Flow {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: [
                            { key:"gruvbox-dark",     label:"Gruvbox",     colors:["#282828","#d79921","#8ec07c","#fb4934"], avail: true },
                            { key:"catppuccin-mocha", label:"Catppuccin",  colors:["#1e1e2e","#cba4f7","#a6e3a1","#f38ba8"], avail: true },
                            { key:"nord",             label:"Nord",        colors:["#2e3440","#88c0d0","#a3be8c","#bf616a"], avail: true },
                            { key:"tokyo-night",      label:"Tokyo Night", colors:["#1a1b26","#7aa2f7","#9ece6a","#f7768e"], avail: true },
                            { key:"dracula",          label:"Dracula",     colors:["#282a36","#bd93f9","#50fa7b","#ff5555"], avail: true },
                            { key:"wallpaper",        label:"Wallpaper",   colors:[], avail: SettingsStore.wallpaperColors !== null }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool active: SettingsStore.colorScheme === modelData.key
                            readonly property bool avail: modelData.avail
                            width: (bodyCol.width - 30) / 3
                            height: 64
                            radius: 8
                            opacity: avail ? 1.0 : 0.4
                            color: Qt.rgba(1,1,1, active ? 0.08 : 0.03)
                            border.width: active ? 1 : 0
                            border.color: Theme.yellow
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 5

                                // Wallpaper card: show gradient from wallpaper colors
                                // Fixed cards: show color swatches
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 3
                                    visible: modelData.colors.length > 0
                                    Repeater {
                                        model: parent.parent.parent.modelData.colors
                                        delegate: Rectangle {
                                            required property string modelData
                                            Layout.fillWidth: true
                                            height: 10; radius: 3
                                            color: modelData
                                        }
                                    }
                                }

                                // Wallpaper swatches (live from loaded colors)
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 3
                                    visible: modelData.colors.length === 0 && SettingsStore.wallpaperColors !== null
                                    Repeater {
                                        model: SettingsStore.wallpaperColors ? [
                                            SettingsStore.wallpaperColors.bg,
                                            SettingsStore.wallpaperColors.yellow,
                                            SettingsStore.wallpaperColors.blue,
                                            SettingsStore.wallpaperColors.red
                                        ] : []
                                        delegate: Rectangle {
                                            required property string modelData
                                            Layout.fillWidth: true
                                            height: 10; radius: 3
                                            color: modelData
                                        }
                                    }
                                }

                                // "No wallpaper" placeholder
                                Text {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignHCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    visible: modelData.colors.length === 0 && SettingsStore.wallpaperColors === null
                                    text: "not loaded"
                                    color: Theme.fgVeryDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: parent.parent.modelData.label
                                    color: parent.parent.active ? Theme.fg : Theme.fgDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: avail ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: if (avail) { SettingsStore.colorScheme = modelData.key; SettingsStore.save() }
                            }
                        }
                    }
                }

                Item { height: 4 }

                // ── Opacity sliders ────────────────────────────────────────
                component OpacityRow: SettingRow {
                    property alias sliderValue: sl.value
                    property alias sliderLabel: pct.text
                    signal sliderMoved(real v)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Slider {
                            id: sl
                            Layout.fillWidth: true
                            from: 0.5; to: 1.0; stepSize: 0.01
                            height: 20
                            handle: Rectangle {
                                x: sl.leftPadding + sl.visualPosition * (sl.availableWidth - width)
                                y: sl.topPadding + sl.availableHeight / 2 - height / 2
                                width: 14; height: 14; radius: 7
                                color: Theme.yellow
                            }
                            background: Rectangle {
                                x: sl.leftPadding
                                y: sl.topPadding + sl.availableHeight / 2 - height / 2
                                width: sl.availableWidth; height: 4; radius: 2
                                color: Qt.rgba(1,1,1,0.12)
                                Rectangle {
                                    width: sl.visualPosition * parent.width
                                    height: parent.height; radius: parent.radius
                                    color: Theme.yellow
                                }
                            }
                            onMoved: sliderMoved(value)
                        }
                        Text {
                            id: pct
                            color: Theme.fgDim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            Layout.preferredWidth: 32
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                OpacityRow {
                    label: "Bar opacity"
                    sliderValue: SettingsStore.barOpacity
                    sliderLabel: Math.round(SettingsStore.barOpacity * 100) + "%"
                    onSliderMoved: function(v) { SettingsStore.barOpacity = v; SettingsStore.save() }
                }

                OpacityRow {
                    label: "Widget opacity"
                    sliderValue: SettingsStore.widgetOpacity
                    sliderLabel: Math.round(SettingsStore.widgetOpacity * 100) + "%"
                    onSliderMoved: function(v) { SettingsStore.widgetOpacity = v; SettingsStore.save() }
                }

                Item { height: 8 }

                // ── LAYOUT ─────────────────────────────────────────────────
                SectionHeader { text: "LAYOUT" }

                SettingRow {
                    label: "Bar style"
                    RowLayout {
                        spacing: 6
                        Pill { label: "Floating"; active: SettingsStore.barStyle === "floating"
                            onClicked: { SettingsStore.barStyle = "floating"; SettingsStore.save() } }
                        Pill { label: "Unified";  active: SettingsStore.barStyle === "unified"
                            onClicked: { SettingsStore.barStyle = "unified";  SettingsStore.save() } }
                    }
                }

                SettingRow {
                    label: "Position"
                    RowLayout {
                        spacing: 6
                        Pill { label: "Top";    active: SettingsStore.barPosition === "top"
                            onClicked: { SettingsStore.barPosition = "top";    SettingsStore.save() } }
                        Pill { label: "Bottom"; active: SettingsStore.barPosition === "bottom"
                            onClicked: { SettingsStore.barPosition = "bottom"; SettingsStore.save() } }
                    }
                }

                SettingRow {
                    label: "Height"
                    Stepper {
                        value: SettingsStore.barHeight; minVal: 20; maxVal: 44; step: 1; unit: "px"
                        onChanged: function(v) { SettingsStore.barHeight = v; SettingsStore.save() }
                    }
                }

                SettingRow {
                    label: "Margin"
                    Stepper {
                        value: SettingsStore.barMargin; minVal: 0; maxVal: 20; step: 1; unit: "px"
                        onChanged: function(v) { SettingsStore.barMargin = v; SettingsStore.save() }
                    }
                }

                SettingRow {
                    label: "Radius"
                    Stepper {
                        value: SettingsStore.groupRadius; minVal: 0; maxVal: 20; step: 1; unit: "px"
                        onChanged: function(v) { SettingsStore.groupRadius = v; SettingsStore.save() }
                    }
                }

                Item { height: 8 }

                // ── MODULES ────────────────────────────────────────────────
                SectionHeader { text: "MODULES" }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 16
                    rowSpacing: 0

                    ModuleRow { label: "Now Playing";    checked: SettingsStore.showNowPlaying
                        onToggled: { SettingsStore.showNowPlaying    = !SettingsStore.showNowPlaying;    SettingsStore.save() } }
                    ModuleRow { label: "Tray";           checked: SettingsStore.showTray
                        onToggled: { SettingsStore.showTray          = !SettingsStore.showTray;          SettingsStore.save() } }
                    ModuleRow { label: "Network";        checked: SettingsStore.showNetwork
                        onToggled: { SettingsStore.showNetwork       = !SettingsStore.showNetwork;       SettingsStore.save() } }
                    ModuleRow { label: "Bluetooth";      checked: SettingsStore.showBluetooth
                        onToggled: { SettingsStore.showBluetooth     = !SettingsStore.showBluetooth;     SettingsStore.save() } }
                    ModuleRow { label: "Reminders";      checked: SettingsStore.showReminders
                        onToggled: { SettingsStore.showReminders     = !SettingsStore.showReminders;     SettingsStore.save() } }
                    ModuleRow { label: "Todos";          checked: SettingsStore.showTodos
                        onToggled: { SettingsStore.showTodos         = !SettingsStore.showTodos;         SettingsStore.save() } }
                    ModuleRow { label: "Notifications";  checked: SettingsStore.showNotifications
                        onToggled: { SettingsStore.showNotifications = !SettingsStore.showNotifications; SettingsStore.save() } }
                    ModuleRow { label: "Clock";          checked: SettingsStore.showClock
                        onToggled: { SettingsStore.showClock         = !SettingsStore.showClock;         SettingsStore.save() } }
                    ModuleRow { label: "Battery";        checked: SettingsStore.showBattery
                        onToggled: { SettingsStore.showBattery       = !SettingsStore.showBattery;       SettingsStore.save() } }
                }

                Item { height: 8 }

                // ── FONT ───────────────────────────────────────────────────
                SectionHeader { text: "FONT" }

                SettingRow {
                    label: "Size"
                    Stepper {
                        value: SettingsStore.fontSize; minVal: 10; maxVal: 18; step: 1; unit: "px"
                        onChanged: function(v) { SettingsStore.fontSize = v; SettingsStore.save() }
                    }
                }

                SettingRow {
                    label: "Family"
                    RowLayout {
                        spacing: 6
                        Repeater {
                            model: [
                                { label:"JetBrains", value:"JetBrainsMonoNL Nerd Font" },
                                { label:"JetBrains (NL)", value:"JetBrainsMonoNL Nerd Font Mono" },
                                { label:"Cascadia", value:"CaskaydiaMono Nerd Font" }
                            ]
                            delegate: Pill {
                                required property var modelData
                                label: modelData.label
                                active: SettingsStore.fontFamily === modelData.value
                                onClicked: { SettingsStore.fontFamily = modelData.value; SettingsStore.save() }
                            }
                        }
                    }
                }

                Item { height: 8 }

                // ── BEHAVIOUR ──────────────────────────────────────────────
                SectionHeader { text: "BEHAVIOUR" }

                SettingRow {
                    label: "24-hour clock"
                    Toggle {
                        checked: TimepiecesStore.use24hr
                        onToggled: { TimepiecesStore.use24hr = !TimepiecesStore.use24hr; TimepiecesStore.save() }
                    }
                }

                SettingRow {
                    label: "Scroll now playing"
                    Toggle {
                        checked: SettingsStore.nowPlayingScroll
                        onToggled: { SettingsStore.nowPlayingScroll = !SettingsStore.nowPlayingScroll; SettingsStore.save() }
                    }
                }

                SettingRow {
                    label: "Animation speed"
                    RowLayout {
                        spacing: 6
                        Repeater {
                            model: [{label:"Off",k:"off"},{label:"Fast",k:"fast"},{label:"Normal",k:"normal"},{label:"Slow",k:"slow"}]
                            delegate: Pill {
                                required property var modelData
                                label: modelData.label
                                active: SettingsStore.animSpeed === modelData.k
                                onClicked: { SettingsStore.animSpeed = modelData.k; SettingsStore.save() }
                            }
                        }
                    }
                }

                SettingRow {
                    label: "OSD duration"
                    RowLayout {
                        spacing: 6
                        Repeater {
                            model: [{label:"0.5s",v:500},{label:"1s",v:1000},{label:"1.5s",v:1500},{label:"2s",v:2000},{label:"3s",v:3000}]
                            delegate: Pill {
                                required property var modelData
                                label: modelData.label
                                active: SettingsStore.osdDuration === modelData.v
                                onClicked: { SettingsStore.osdDuration = modelData.v; SettingsStore.save() }
                            }
                        }
                    }
                }

                Item { height: 8 }
            }
        }
    }
}
