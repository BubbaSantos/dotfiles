import "."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.services

PanelWindow {
    id: root

    property var trayItem: null   // The SystemTrayItem this menu represents
    property Item anchorItem: null
    property int menuWidth: 240

    visible: false
    color: "transparent"

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    function openFor(item, anchor) {
        root.trayItem = item
        root.anchorItem = anchor
        root.visible = true
    }

    onVisibleChanged: if (visible) PopupManager.open(root)
    function close() {
        root.visible = false
        root.trayItem = null
    }

    // Click-outside-to-close
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    // The QsMenuOpener gives us iterable menu children
    QsMenuOpener {
        id: opener
        menu: root.trayItem ? root.trayItem.menu : null
    }

    Rectangle {
        id: card
        width: root.menuWidth
        height: menuColumn.implicitHeight + 12

        // Position under the anchor item
        x: {
            if (!root.anchorItem) return 20
            const p = root.anchorItem.mapToItem(null, 0, 0)
            const margin = 8
            // Preferred: align menu's LEFT edge with icon's left edge (drops down-right)
            const preferLeft = p.x
            // Fallback: align menu's RIGHT edge with icon's right edge (drops down-left)
            const preferRight = p.x + root.anchorItem.width - width

            // If left-aligned would overflow the right edge of screen, use right-aligned
            if (preferLeft + width + margin > root.width) {
                // Still clamp in case right-aligned also overflows on the left
                return Math.max(margin, preferRight)
            }
            return preferLeft
        }
        y: 0
        Component.onCompleted: console.log("MENU Y DEBUG: barHeight=", Theme.barHeight, "card.y=", y)

        color: Theme.barBg
        radius: 10
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.06)

        opacity: root.visible ? 1 : 0
        scale: root.visible ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }

        // Eat clicks
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        HoverHandler {
            onHoveredChanged: {
                if (!hovered) autoCloseTimer.restart()
                else autoCloseTimer.stop()
            }
        }
        Timer { id: autoCloseTimer; interval: 2000; onTriggered: root.close() }

        ColumnLayout {
            id: menuColumn
            anchors.fill: parent
            anchors.margins: 6
            spacing: 1

            Repeater {
                model: opener.children

                delegate: Loader {
                    Layout.fillWidth: true
                    required property var modelData
                    sourceComponent: modelData.isSeparator ? separatorComponent : entryComponent

                    Component {
                        id: separatorComponent
                        Rectangle {
                            Layout.fillWidth: true
                            height: 6
                            color: "transparent"
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 6
                                anchors.rightMargin: 6
                                height: 1
                                color: Qt.rgba(1, 1, 1, 0.08)
                            }
                        }
                    }

                    Component {
                        id: entryComponent
                        Rectangle {
                            id: entry
                            Layout.fillWidth: true
                            height: 28
                            radius: 6
                            color: entryMouse.containsMouse && modelData.enabled
                                   ? Qt.rgba(1, 1, 1, 0.08)
                                   : "transparent"
                            opacity: modelData.enabled ? 1.0 : 0.4

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                // Optional icon
                                Image {
                                    visible: modelData.icon !== ""
                                    source: modelData.icon
                                    Layout.preferredWidth: 14
                                    Layout.preferredHeight: 14
                                    sourceSize.width: 14
                                    sourceSize.height: 14
                                    smooth: true
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.text || ""
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                    elide: Text.ElideRight
                                }

                                // Submenu chevron
                                Text {
                                    visible: modelData.hasChildren
                                    text: "›"
                                    color: Theme.fgDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                }
                            }

                            MouseArea {
                                id: entryMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: modelData.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                enabled: modelData.enabled
                                onClicked: {
                                    if (modelData.hasChildren) {
                                        // Submenu — for now, just trigger which expands inline.
                                        // We could nest a child TrayMenu here later.
                                        modelData.triggered()
                                    } else {
                                        modelData.triggered()
                                        root.close()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
