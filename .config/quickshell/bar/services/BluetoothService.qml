pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth

QtObject {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool ready: adapter !== null
    readonly property bool powered: ready && adapter.enabled
    readonly property bool scanning: ready && adapter.discovering
    readonly property bool discoverable: ready && adapter.discoverable

    readonly property var devices: ready ? adapter.devices.values : []

    readonly property var connectedDevices: {
        if (!ready) return []
        return adapter.devices.values.filter(d => d.connected)
    }

    readonly property var pairedDevices: {
        if (!ready) return []
        return adapter.devices.values.filter(d => d.paired || d.bonded)
    }

    readonly property var availableDevices: {
        if (!ready) return []
        return adapter.devices.values.filter(d => !d.paired && !d.bonded)
    }

    function setPowered(on) {
        if (ready) adapter.enabled = on
    }
    function startScan() {
        if (ready) adapter.discovering = true
    }
    function stopScan() {
        if (ready) adapter.discovering = false
    }
    function setDiscoverable(on) {
        if (ready) adapter.discoverable = on
    }
}
