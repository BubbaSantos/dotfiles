pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property string interfaceName: "wlan0"

    // Current connection state
    property bool connected: false
    property string ssid: ""
    property int signal_: 0
    property string security: ""
    property bool scanning: false
    property bool powered: true

    // Available networks
    property var networks: []
    property var knownNetworks: []

    // Refresh status periodically
    property Timer statusTimer: Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshStatus()
    }

    function refreshStatus() {
        statusProc.running = true
    }

    function refreshNetworks() {
        networkScanProc.running = true
    }

    function refreshKnown() {
        knownProc.running = true
    }

    function connectToNetwork(ssid, password) {
        if (password && password.length > 0) {
            connectProc.command = ["sh", "-c",
                `echo '${password.replace(/'/g, "'\\''")}' | iwctl --passphrase-stdin station ${root.interfaceName} connect '${ssid.replace(/'/g, "'\\''")}'`
            ]
        } else {
            connectProc.command = ["iwctl", "station", root.interfaceName, "connect", ssid]
        }
        connectProc.running = true
    }

    function disconnect() {
        disconnectProc.running = true
    }

    function forgetNetwork(ssid) {
        forgetProc.command = ["iwctl", "known-networks", ssid, "forget"]
        forgetProc.running = true
    }

    function setPowered(on) {
        rfkillProc.command = ["rfkill", on ? "unblock" : "block", "wifi"]
        rfkillProc.running = true
    }

    function scan() {
        scanProc.running = true
    }

    // dBm → signal percentage
    function rssiToPercent(rssi) {
        if (rssi >= -50) return 100
        if (rssi <= -100) return 0
        return Math.round(2 * (rssi + 100))
    }

    // --- Processes ---

    property Process statusProc: Process {
        command: ["iwctl", "station", root.interfaceName, "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n")
                let connected = false
                let ssid = ""
                let rssi = -100
                let security = ""
                let scanning = false

                for (const line of lines) {
                    if (line.includes("State")) {
                        connected = line.includes("connected") && !line.includes("disconnected")
                    } else if (line.includes("Connected network")) {
                        const m = line.match(/Connected network\s+(.+?)\s*$/)
                        if (m) ssid = m[1].trim()
                    } else if (line.match(/^\s*RSSI/) && !line.includes("Average")) {
                        const m = line.match(/(-?\d+)\s*dBm/)
                        if (m) rssi = parseInt(m[1])
                    } else if (line.includes("Security")) {
                        const m = line.match(/Security\s+(.+?)\s*$/)
                        if (m) security = m[1].trim()
                    } else if (line.includes("Scanning")) {
                        scanning = line.includes("yes")
                    }
                }

                root.connected = connected
                root.ssid = ssid
                root.signal_ = root.rssiToPercent(rssi)
                root.security = security
                root.scanning = scanning
            }
        }
    }

    property Process networkScanProc: Process {
        command: ["iwctl", "station", root.interfaceName, "get-networks"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n")
                const nets = []

                for (const line of lines) {
                    // Match: optional ">" marker, network name (column-padded), security, signal
                    // Format: "  >   <name padded>  <sec padded>  <signal>"
                    // Names can contain spaces — use trailing "****" as anchor
                    const m = line.match(/^(\s*>?\s*)(\S.*?)\s{2,}(psk|open|8021x|wep)\s+(\**)\s*$/)
                    if (!m) continue
                    const isCurrent = m[1].includes(">")
                    const name = m[2].trim()
                    const sec = m[3]
                    const stars = m[4].length
                    nets.push({
                        ssid: name,
                        security: sec,
                        signal: stars,
                        current: isCurrent
                    })
                }
                root.networks = nets
            }
        }
    }

    property Process knownProc: Process {
        command: ["iwctl", "known-networks", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n")
                const known = []
                for (const line of lines) {
                    // Format: "  <name>  <security>  <last-connected>  <auto-connect>"
                    const m = line.match(/^\s+(\S.*?)\s{2,}(psk|open|8021x|wep)\s+/)
                    if (!m) continue
                    known.push({ ssid: m[1].trim(), security: m[2] })
                }
                root.knownNetworks = known
            }
        }
    }

    property Process connectProc: Process {
        onExited: function(code) {
            root.refreshStatus()
            root.refreshNetworks()
        }
    }

    property Process disconnectProc: Process {
        command: ["iwctl", "station", root.interfaceName, "disconnect"]
        onExited: root.refreshStatus()
    }

    property Process forgetProc: Process {
        onExited: root.refreshKnown()
    }

    property Process rfkillProc: Process {
        onExited: function(code) {
            root.refreshStatus()
            powerCheckProc.running = true
        }
    }

    property Process scanProc: Process {
        command: ["iwctl", "station", root.interfaceName, "scan"]
        onExited: {
            scanRefreshTimer.start()
        }
    }

    property Timer scanRefreshTimer: Timer {
        interval: 2000
        onTriggered: {
            root.refreshNetworks()
            root.refreshStatus()
        }
    }

    property Process powerCheckProc: Process {
        command: ["sh", "-c", "rfkill list wifi | grep -q 'Soft blocked: yes' && echo off || echo on"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.powered = text.trim() === "on"
            }
        }
    }

    Component.onCompleted: {
        powerCheckProc.running = true
        refreshKnown()
        refreshNetworks()
    }
}
