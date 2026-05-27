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

    property string activeTab: "appearance"

    function toggle() { visible = !visible }
    function close()  { visible = false    }

    GlobalShortcut {
        name: "toggleSettings"
        onPressed: root.toggle()
    }

    // ── Reusable components ────────────────────────────────────────────

    component SectionHeader: Item {
        property string text: ""
        Layout.fillWidth: true
        height: 30
        Text {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 5
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

    component SettingRow: RowLayout {
        property string label: ""
        property int labelWidth: 130
        Layout.fillWidth: true
        height: 34
        spacing: 12
        Text {
            text: parent.label
            color: Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            Layout.preferredWidth: parent.labelWidth
        }
    }

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
                width: 14; height: 14; radius: 7
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

    component Stepper: RowLayout {
        property int value: 0
        property int minVal: 0
        property int maxVal: 100
        property int step: 1
        property string unit: ""
        signal changed(int v)
        spacing: 4; height: 24
        Text {
            text: "−"
            color: parent.value <= parent.minVal ? Theme.fgVeryDim : Theme.fgDim
            font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize + 2
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: if (parent.parent.value > parent.parent.minVal)
                    parent.parent.changed(parent.parent.value - parent.parent.step)
            }
        }
        Text {
            text: parent.value + parent.unit
            color: Theme.fg
            font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize
            Layout.preferredWidth: 36; horizontalAlignment: Text.AlignHCenter
        }
        Text {
            text: "+"
            color: parent.value >= parent.maxVal ? Theme.fgVeryDim : Theme.fgDim
            font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize + 2
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: if (parent.parent.value < parent.parent.maxVal)
                    parent.parent.changed(parent.parent.value + parent.parent.step)
            }
        }
    }

    component OpacitySlider: RowLayout {
        property string label: ""
        property real   sliderValue: 1.0
        signal sliderMoved(real v)
        Layout.fillWidth: true; height: 34; spacing: 12
        Text {
            text: parent.label; color: Theme.fgDim
            font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize
            Layout.preferredWidth: 130
        }
        Slider {
            id: osl
            Layout.fillWidth: true; from: 0.3; to: 1.0; stepSize: 0.01
            value: parent.sliderValue
            height: 20
            handle: Rectangle {
                x: osl.leftPadding + osl.visualPosition * (osl.availableWidth - width)
                y: osl.topPadding + osl.availableHeight / 2 - height / 2
                width: 14; height: 14; radius: 7; color: Theme.yellow
            }
            background: Rectangle {
                x: osl.leftPadding
                y: osl.topPadding + osl.availableHeight / 2 - height / 2
                width: osl.availableWidth; height: 4; radius: 2
                color: Qt.rgba(1,1,1,0.18)
                Rectangle {
                    width: osl.visualPosition * parent.width
                    height: parent.height; radius: parent.radius; color: Theme.yellow
                }
            }
            onMoved: parent.sliderMoved(value)
        }
        Text {
            text: Math.round(parent.sliderValue * 100) + "%"
            color: Theme.fgDim; font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            Layout.preferredWidth: 32; horizontalAlignment: Text.AlignRight
        }
    }

    // ── Module helpers ─────────────────────────────────────────────────

    function moduleDisplayName(key) {
        const n = {"Tray":"Tray","Network":"Network","Bluetooth":"Bluetooth",
                   "Reminders":"Reminders","Todos":"Todos","Notifications":"Notifications",
                   "Clock":"Clock","Battery":"Battery"}
        return n[key] || key
    }

    function moduleChecked(key) {
        switch(key) {
            case "Tray":          return SettingsStore.showTray
            case "Network":       return SettingsStore.showNetwork
            case "Bluetooth":     return SettingsStore.showBluetooth
            case "Reminders":     return SettingsStore.showReminders
            case "Todos":         return SettingsStore.showTodos
            case "Notifications": return SettingsStore.showNotifications
            case "Clock":         return SettingsStore.showClock
            case "Battery":       return SettingsStore.showBattery
            default: return true
        }
    }

    function toggleModule(key) {
        switch(key) {
            case "Tray":          SettingsStore.showTray          = !SettingsStore.showTray;          break
            case "Network":       SettingsStore.showNetwork       = !SettingsStore.showNetwork;       break
            case "Bluetooth":     SettingsStore.showBluetooth     = !SettingsStore.showBluetooth;     break
            case "Reminders":     SettingsStore.showReminders     = !SettingsStore.showReminders;     break
            case "Todos":         SettingsStore.showTodos         = !SettingsStore.showTodos;         break
            case "Notifications": SettingsStore.showNotifications = !SettingsStore.showNotifications; break
            case "Clock":         SettingsStore.showClock         = !SettingsStore.showClock;         break
            case "Battery":       SettingsStore.showBattery       = !SettingsStore.showBattery;       break
        }
        SettingsStore.save()
    }

    // ── Backdrop ───────────────────────────────────────────────────────
    MouseArea { anchors.fill: parent; onClicked: root.close() }

    // ── Card ───────────────────────────────────────────────────────────
    Rectangle {
        id: card
        readonly property int cardW: 520
        width: cardW
        x: (root.width - cardW) / 2
        y: Theme.barHeight + Theme.barMargin + 8
        height: Math.min(cardHeader.height + tabBar.height + scrollArea.contentHeight + 24,
                         root.height - y - 16)
        radius: 12
        color: Theme.popupBg
        border.width: 1
        border.color: Qt.rgba(1,1,1,0.1)

        MouseArea { anchors.fill: parent; onClicked: {} }

        Item {
            anchors.fill: parent
            focus: root.visible
            Keys.onPressed: function(ev) {
                if (ev.key === Qt.Key_Escape) { root.close(); ev.accepted = true }
            }
        }

        // ── Header ────────────────────────────────────────────────────
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
                text: "✕"; color: Theme.fgDim; font.pixelSize: Theme.fontSize
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: root.close()
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left; anchors.right: parent.right
                height: 1; color: Qt.rgba(1,1,1,0.07)
            }
        }

        // ── Tab bar ───────────────────────────────────────────────────
        Item {
            id: tabBar
            anchors.top: cardHeader.bottom
            anchors.left: parent.left; anchors.right: parent.right
            height: 40

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12; anchors.rightMargin: 12
                spacing: 6

                Repeater {
                    model: [
                        { key: "appearance", label: "Appearance" },
                        { key: "layout",     label: "Layout"     },
                        { key: "modules",    label: "Modules"    },
                        { key: "behaviour",  label: "Behaviour"  },
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool active: root.activeTab === modelData.key
                        height: 28; radius: 6
                        Layout.preferredWidth: tabLabel.implicitWidth + 20
                        color: active ? Qt.rgba(Theme._s.fgR, Theme._s.fgG, Theme._s.fgB, 0.12)
                                      : Qt.rgba(1,1,1,0.04)
                        border.width: active ? 1 : 0
                        border.color: Theme.yellow
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        Text {
                            id: tabLabel
                            anchors.centerIn: parent
                            text: parent.modelData.label
                            color: parent.active ? Theme.fg : Theme.fgDim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeTab = parent.modelData.key
                        }
                    }
                }
                Item { Layout.fillWidth: true }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left; anchors.right: parent.right
                height: 1; color: Qt.rgba(1,1,1,0.07)
            }
        }

        // ── Scrollable body ───────────────────────────────────────────
        Flickable {
            id: scrollArea
            anchors.top: tabBar.bottom
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            anchors.margins: 4
            clip: true
            contentWidth: width
            contentHeight: bodyCol.implicitHeight + 16
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            ColumnLayout {
                id: bodyCol
                width: scrollArea.width - 16
                x: 8; y: 8
                spacing: 2

                // ════════════════════════════════════════════════════
                // APPEARANCE TAB
                // ════════════════════════════════════════════════════
                Item {
                    Layout.fillWidth: true
                    visible: root.activeTab === "appearance"
                    implicitHeight: visible ? appearanceCol.implicitHeight : 0

                    ColumnLayout {
                        id: appearanceCol
                        width: parent.width
                        spacing: 2

                        SectionHeader { text: "COLOR SCHEME" }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: [
                                    { key:"gruvbox-dark",     label:"Gruvbox",     colors:["#282828","#d79921","#8ec07c","#fb4934"], avail:true },
                                    { key:"catppuccin-mocha", label:"Catppuccin",  colors:["#1e1e2e","#cba4f7","#a6e3a1","#f38ba8"], avail:true },
                                    { key:"nord",             label:"Nord",        colors:["#2e3440","#88c0d0","#a3be8c","#bf616a"], avail:true },
                                    { key:"tokyo-night",      label:"Tokyo Night", colors:["#1a1b26","#7aa2f7","#9ece6a","#f7768e"], avail:true },
                                    { key:"dracula",          label:"Dracula",     colors:["#282a36","#bd93f9","#50fa7b","#ff5555"], avail:true },
                                    { key:"wallpaper",        label:"Wallpaper",   colors:[], avail: SettingsStore.wallpaperColors !== null }
                                ]

                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool active: SettingsStore.colorScheme === modelData.key
                                    readonly property bool avail: modelData.avail
                                    width: (appearanceCol.width - 30) / 3
                                    height: 60; radius: 8
                                    opacity: avail ? 1.0 : 0.4
                                    color: Qt.rgba(1,1,1, active ? 0.08 : 0.03)
                                    border.width: active ? 1 : 0; border.color: Theme.yellow
                                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                    ColumnLayout {
                                        anchors.fill: parent; anchors.margins: 6; spacing: 5
                                        RowLayout {
                                            Layout.fillWidth: true; spacing: 3
                                            visible: modelData.colors.length > 0
                                            Repeater {
                                                model: parent.parent.parent.modelData.colors
                                                delegate: Rectangle {
                                                    required property string modelData
                                                    Layout.fillWidth: true; height: 10; radius: 3; color: modelData
                                                }
                                            }
                                        }
                                        RowLayout {
                                            Layout.fillWidth: true; spacing: 3
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
                                                    Layout.fillWidth: true; height: 10; radius: 3; color: modelData
                                                }
                                            }
                                        }
                                        Text {
                                            Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                                            visible: modelData.colors.length === 0 && SettingsStore.wallpaperColors === null
                                            text: "not loaded"; color: Theme.fgVeryDim
                                            font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall - 1
                                        }
                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: parent.parent.modelData.label
                                            color: parent.parent.active ? Theme.fg : Theme.fgDim
                                            font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall - 1
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

                        Item { height: 6 }
                        SectionHeader { text: "OPACITY" }

                        OpacitySlider {
                            label: "Bar background"
                            sliderValue: SettingsStore.barOpacity
                            onSliderMoved: function(v) { SettingsStore.barOpacity = v; SettingsStore.save() }
                        }
                        OpacitySlider {
                            label: "Popups & widgets"
                            sliderValue: SettingsStore.widgetOpacity
                            onSliderMoved: function(v) { SettingsStore.widgetOpacity = v; SettingsStore.save() }
                        }

                        Item { height: 6 }
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
                                        { label:"JetBrains",      value:"JetBrainsMonoNL Nerd Font"      },
                                        { label:"JetBrains Mono", value:"JetBrainsMonoNL Nerd Font Mono" },
                                        { label:"Cascadia",       value:"CaskaydiaMono Nerd Font"        }
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
                    }
                }

                // ════════════════════════════════════════════════════
                // LAYOUT TAB
                // ════════════════════════════════════════════════════
                Item {
                    Layout.fillWidth: true
                    visible: root.activeTab === "layout"
                    implicitHeight: visible ? layoutCol.implicitHeight : 0

                    ColumnLayout {
                        id: layoutCol
                        width: parent.width
                        spacing: 2

                        SectionHeader { text: "BAR" }

                        SettingRow {
                            label: "Style"
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
                            Stepper { value: SettingsStore.barHeight; minVal: 20; maxVal: 44; step: 1; unit: "px"
                                onChanged: function(v) { SettingsStore.barHeight = v; SettingsStore.save() } }
                        }
                        SettingRow {
                            label: "Margin"
                            Stepper { value: SettingsStore.barMargin; minVal: 0; maxVal: 20; step: 1; unit: "px"
                                onChanged: function(v) { SettingsStore.barMargin = v; SettingsStore.save() } }
                        }
                        SettingRow {
                            label: "Corner radius"
                            Stepper { value: SettingsStore.groupRadius; minVal: 0; maxVal: 20; step: 1; unit: "px"
                                onChanged: function(v) { SettingsStore.groupRadius = v; SettingsStore.save() } }
                        }

                        Item { height: 8 }
                    }
                }

                // ════════════════════════════════════════════════════
                // MODULES TAB
                // ════════════════════════════════════════════════════
                Item {
                    Layout.fillWidth: true
                    visible: root.activeTab === "modules"
                    implicitHeight: visible ? modulesCol.implicitHeight : 0

                    ColumnLayout {
                        id: modulesCol
                        width: parent.width
                        spacing: 2

                        SectionHeader { text: "WORKSPACES" }

                        SettingRow {
                            label: "Style"
                            RowLayout {
                                spacing: 6
                                Pill { label: "Numbers"; active: SettingsStore.workspaceStyle === "numbers"
                                    onClicked: { SettingsStore.workspaceStyle = "numbers"; SettingsStore.save() } }
                                Pill { label: "Dots";    active: SettingsStore.workspaceStyle === "dots"
                                    onClicked: { SettingsStore.workspaceStyle = "dots";    SettingsStore.save() } }
                                Pill { label: "Minimal"; active: SettingsStore.workspaceStyle === "minimal"
                                    onClicked: { SettingsStore.workspaceStyle = "minimal"; SettingsStore.save() } }
                            }
                        }
                        SettingRow {
                            label: "Animation"
                            RowLayout {
                                spacing: 6
                                Pill { label: "Slide";  active: SettingsStore.workspaceAnim === "slide"
                                    onClicked: { SettingsStore.workspaceAnim = "slide";  SettingsStore.save() } }
                                Pill { label: "Bounce"; active: SettingsStore.workspaceAnim === "bounce"
                                    onClicked: { SettingsStore.workspaceAnim = "bounce"; SettingsStore.save() } }
                                Pill { label: "Fade";   active: SettingsStore.workspaceAnim === "fade"
                                    onClicked: { SettingsStore.workspaceAnim = "fade";   SettingsStore.save() } }
                                Pill { label: "None";   active: SettingsStore.workspaceAnim === "none"
                                    onClicked: { SettingsStore.workspaceAnim = "none";   SettingsStore.save() } }
                            }
                        }

                        OpacitySlider {
                            label: "Active pill opacity"
                            sliderValue: SettingsStore.workspaceActiveOpacity
                            onSliderMoved: function(v) { SettingsStore.workspaceActiveOpacity = v; SettingsStore.save() }
                        }

                        Item { height: 6 }
                        SectionHeader { text: "LEFT GROUP" }

                        RowLayout {
                            Layout.fillWidth: true; height: 34; spacing: 12
                            Text { text: "Now Playing"; color: Theme.fgDim; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize; Layout.fillWidth: true }
                            Toggle {
                                checked: SettingsStore.showNowPlaying
                                onToggled: { SettingsStore.showNowPlaying = !SettingsStore.showNowPlaying; SettingsStore.save() }
                            }
                        }

                        Item { height: 6 }
                        SectionHeader { text: "RIGHT GROUP — drag to reorder" }

                        // Column headers
                        RowLayout {
                            Layout.fillWidth: true; height: 20
                            Text { text: "Module"; color: Theme.fgVeryDim; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; Layout.fillWidth: true }
                            Text { text: "Show"; color: Theme.fgVeryDim; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignHCenter }
                            Item { Layout.preferredWidth: 52 }
                        }

                        Repeater {
                            model: SettingsStore.rightModuleOrder
                            delegate: Rectangle {
                                required property string modelData
                                required property int index
                                Layout.fillWidth: true; height: 36; radius: 6
                                color: modHover.containsMouse ? Qt.rgba(1,1,1,0.04) : "transparent"
                                Behavior on color { ColorAnimation { duration: 80 } }

                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 8

                                    // Drag handle hint
                                    Text { text: "≡"; color: Theme.fgVeryDim; font.family: Theme.fontFamily; font.pixelSize: 14 }

                                    Text {
                                        text: root.moduleDisplayName(modelData)
                                        color: root.moduleChecked(modelData) ? Theme.fg : Theme.fgDim
                                        font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize
                                        Layout.fillWidth: true
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                    }

                                    Toggle {
                                        checked: root.moduleChecked(modelData)
                                        onToggled: root.toggleModule(modelData)
                                    }

                                    // Up/down buttons
                                    RowLayout {
                                        spacing: 2
                                        Rectangle {
                                            width: 22; height: 22; radius: 4
                                            color: upM.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.04)
                                            Behavior on color { ColorAnimation { duration: 80 } }
                                            opacity: index > 0 ? 1.0 : 0.25
                                            Text {
                                                anchors.centerIn: parent; text: "↑"
                                                color: Theme.fg; font.family: Theme.fontFamily; font.pixelSize: 12
                                            }
                                            MouseArea {
                                                id: upM; anchors.fill: parent; hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: SettingsStore.moveModuleUp(index)
                                            }
                                        }
                                        Rectangle {
                                            width: 22; height: 22; radius: 4
                                            color: downM.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.04)
                                            Behavior on color { ColorAnimation { duration: 80 } }
                                            opacity: index < SettingsStore.rightModuleOrder.length - 1 ? 1.0 : 0.25
                                            Text {
                                                anchors.centerIn: parent; text: "↓"
                                                color: Theme.fg; font.family: Theme.fontFamily; font.pixelSize: 12
                                            }
                                            MouseArea {
                                                id: downM; anchors.fill: parent; hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: SettingsStore.moveModuleDown(index)
                                            }
                                        }
                                    }
                                }

                                HoverHandler { id: modHover }
                            }
                        }

                        Item { height: 8 }
                    }
                }

                // ════════════════════════════════════════════════════
                // BEHAVIOUR TAB
                // ════════════════════════════════════════════════════
                Item {
                    Layout.fillWidth: true
                    visible: root.activeTab === "behaviour"
                    implicitHeight: visible ? behaviourCol.implicitHeight : 0

                    ColumnLayout {
                        id: behaviourCol
                        width: parent.width
                        spacing: 2

                        SectionHeader { text: "CLOCK" }

                        SettingRow {
                            label: "24-hour clock"
                            Toggle {
                                checked: TimepiecesStore.use24hr
                                onToggled: { TimepiecesStore.use24hr = !TimepiecesStore.use24hr; TimepiecesStore.save() }
                            }
                        }

                        Item { height: 6 }
                        SectionHeader { text: "NOW PLAYING" }

                        SettingRow {
                            label: "Scroll text"
                            Toggle {
                                checked: SettingsStore.nowPlayingScroll
                                onToggled: { SettingsStore.nowPlayingScroll = !SettingsStore.nowPlayingScroll; SettingsStore.save() }
                            }
                        }

                        Item { height: 6 }
                        SectionHeader { text: "ANIMATIONS" }

                        SettingRow {
                            label: "Speed"
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

                        Item { height: 6 }
                        SectionHeader { text: "OSD" }

                        SettingRow {
                            label: "Display duration"
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

                        Item { height: 6 }
                        SectionHeader { text: "AUTO-CLOSE (0 = never)" }

                        Repeater {
                            model: [
                                { label: "Calendar",       key: "autoCloseCalendar"   },
                                { label: "Notifications",  key: "autoCloseNotif"      },
                                { label: "Media player",   key: "autoCloseMedia"      },
                                { label: "Control centre", key: "autoCloseControl"    },
                                { label: "Wi-Fi",          key: "autoCloseWifi"       },
                                { label: "Bluetooth",      key: "autoCloseBluetooth"  },
                                { label: "Reminders",      key: "autoCloseReminders"  },
                                { label: "To-do list",     key: "autoCloseTodos"      },
                                { label: "Timepieces",     key: "autoCloseTimepieces" },
                            ]
                            delegate: SettingRow {
                                required property var modelData
                                label: modelData.label
                                Stepper {
                                    value: SettingsStore[modelData.key]
                                    minVal: 0; maxVal: 30; step: 1; unit: "s"
                                    onChanged: function(v) { SettingsStore[modelData.key] = v; SettingsStore.save() }
                                }
                            }
                        }

                        Item { height: 8 }
                    }
                }
            }
        }
    }
}
