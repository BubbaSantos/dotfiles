import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs
import qs.services
import qs.popups

Item {
    id: root
    Layout.preferredHeight: 22
    Layout.preferredWidth: layoutRow.implicitWidth

    property bool locked: false
    property bool menuFromUnpinned: false
    // Stay open while a menu from an unpinned item is visible; ignore pinned-item menus
    readonly property bool open: locked || chevronHover.hovered || drawerHover.hovered || menuFromUnpinned

    TrayMenu { id: sharedMenu }

    Connections {
        target: sharedMenu
        function onVisibleChanged() { if (!sharedMenu.visible) root.menuFromUnpinned = false }
    }

    readonly property var allItems: SystemTray.items.values
    readonly property var pinnedItems: allItems.filter(i => TimepiecesStore.isPinned(i.id))
    readonly property var unpinnedItems: allItems.filter(i => !TimepiecesStore.isPinned(i.id))

    RowLayout {
        id: layoutRow
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0   // no inter-zone spacing; rely on zone padding

        // Unpinned drawer
        Item {
            id: clip
            Layout.preferredHeight: 22
            Layout.preferredWidth: root.open && root.unpinnedItems.length > 0
                                   ? unpinnedRow.implicitWidth + 12  // pad inside the drawer
                                   : 0
            clip: true
            visible: root.unpinnedItems.length > 0

            HoverHandler { id: drawerHover }

            Behavior on Layout.preferredWidth {
                NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
            }

            RowLayout {
                id: unpinnedRow
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                x: 0
                opacity: 0   // initial; controlled by animations below

                states: [
                    State { name: "open"; when: root.open },
                    State { name: "closed"; when: !root.open }
                ]

                transitions: [
                    Transition {
                        from: "closed"; to: "open"
                        SequentialAnimation {
                            PauseAnimation { duration: 260 }
                            NumberAnimation {
                                target: unpinnedRow
                                property: "opacity"
                                to: 1
                                duration: 180
                                easing.type: Easing.OutCubic
                            }
                        }
                    },
                    Transition {
                        from: "open"; to: "closed"
                        NumberAnimation {
                            target: unpinnedRow
                            property: "opacity"
                            to: 0
                            duration: 80
                            easing.type: Easing.OutCubic
                        }
                    }
                ]

                Repeater {
                    model: root.unpinnedItems

                    delegate: Item {
                        id: udelegate
                        required property var modelData
                        Layout.preferredHeight: 14
                        Layout.preferredWidth: 14

                        QsMenuOpener {
                            id: uOpener
                            menu: udelegate.modelData.menu
                        }

                        Image {
                            anchors.fill: parent
                            source: udelegate.modelData.icon
                            sourceSize.width: 14
                            sourceSize.height: 14
                            smooth: true
                            asynchronous: true

                            onStatusChanged: {
                                if (status === Image.Error) {
                                    const match = udelegate.modelData.icon.match(/image:\/\/icon\/([^?]+)/)
                                    if (match) {
                                        const name = match[1].split("/").pop()
                                        const resolved = Quickshell.iconPath(name, true)
                                        if (resolved) source = resolved
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            cursorShape: Qt.PointingHandCursor

                            onClicked: function(ev) {
                                const item = udelegate.modelData
                                if (ev.button === Qt.LeftButton) {
                                    if (item.hasMenu) { root.menuFromUnpinned = true; sharedMenu.openFor(item, udelegate) }
                                    else item.activate()
                                } else if (ev.button === Qt.RightButton) {
                                    TimepiecesStore.togglePin(item.id)
                                } else if (ev.button === Qt.MiddleButton) {
                                    item.secondaryActivate()
                                }
                            }

                            onDoubleClicked: function(ev) {
                                if (ev.button !== Qt.LeftButton) return
                                sharedMenu.close()
                                udelegate.modelData.activate()
                                const entries = uOpener.children.values
                                for (let i = 0; i < entries.length; i++) {
                                    const e = entries[i]
                                    if (!e.isSeparator && e.enabled) {
                                        e.triggered()
                                        break
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Chevron
        Rectangle {
            id: chevron
            Layout.preferredHeight: 22
            Layout.preferredWidth: 22
            radius: 6
            color: chevronMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
            visible: root.unpinnedItems.length > 0

            HoverHandler { id: chevronHover }
            Behavior on color { ColorAnimation { duration: Theme.animFast } }

            Text {
                anchors.centerIn: parent
                text: "󰮫"
                color: root.locked ? Theme.red : Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeIcon
                rotation: root.open ? 180 : 0

                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Behavior on rotation { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                id: chevronMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.locked = !root.locked
            }
        }

        // Pinned zone — left padding so it doesn't kiss the chevron
        RowLayout {
            spacing: 8
            Layout.leftMargin: root.pinnedItems.length > 0 ? 8 : 0
            visible: root.pinnedItems.length > 0

            Repeater {
                model: root.pinnedItems

                delegate: Item {
                    id: pdelegate
                    required property var modelData
                    Layout.preferredHeight: 14
                    Layout.preferredWidth: 14

                    QsMenuOpener {
                        id: pOpener
                        menu: pdelegate.modelData.menu
                    }

                    Image {
                        anchors.fill: parent
                        source: pdelegate.modelData.icon
                        sourceSize.width: 14
                        sourceSize.height: 14
                        smooth: true
                        asynchronous: true

                        onStatusChanged: {
                            if (status === Image.Error) {
                                const match = pdelegate.modelData.icon.match(/image:\/\/icon\/([^?]+)/)
                                if (match) {
                                    const name = match[1].split("/").pop()
                                    const resolved = Quickshell.iconPath(name, true)
                                    if (resolved) source = resolved
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        cursorShape: Qt.PointingHandCursor

                        onClicked: function(ev) {
                            const item = pdelegate.modelData
                            if (ev.button === Qt.LeftButton) {
                                if (item.hasMenu) sharedMenu.openFor(item, pdelegate)
                                else item.activate()
                            } else if (ev.button === Qt.RightButton) {
                                TimepiecesStore.togglePin(item.id)
                            } else if (ev.button === Qt.MiddleButton) {
                                item.secondaryActivate()
                            }
                        }

                        onDoubleClicked: function(ev) {
                            if (ev.button !== Qt.LeftButton) return
                            sharedMenu.close()
                            pdelegate.modelData.activate()
                            const entries = pOpener.children.values
                            for (let i = 0; i < entries.length; i++) {
                                const e = entries[i]
                                if (!e.isSeparator && e.enabled) {
                                    e.triggered()
                                    break
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
