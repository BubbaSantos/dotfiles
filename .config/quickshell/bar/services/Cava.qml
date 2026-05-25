pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int barCount: 32
    property var bars: new Array(32).fill(0)

    // Run cava with raw stdout, 32 bars 0-255
    Process {
        id: cavaProc
        running: true
        command: ["sh", "-c",
            "cat > /tmp/qs-cava.conf <<'EOF'\n" +
            "[general]\nbars = 32\nframerate = 60\n" +
            "[output]\nmethod = raw\nraw_target = /dev/stdout\n" +
            "data_format = ascii\nascii_max_range = 100\n" +
            "channels = mono\n" +
            "EOF\n" +
            "exec cava -p /tmp/qs-cava.conf"
        ]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                const parts = line.split(";").filter(s => s.length > 0)
                if (parts.length === root.barCount) {
                    root.bars = parts.map(p => parseInt(p) / 100.0)
                }
            }
        }
    }
}
