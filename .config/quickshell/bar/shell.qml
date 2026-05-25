//@ pragma UseQApplication
import QtQuick
import Quickshell
import "modules"

ShellRoot {
    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            screen: modelData
        }
    }
}
