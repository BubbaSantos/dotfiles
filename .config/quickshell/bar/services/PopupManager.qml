pragma Singleton
import QtQuick
import Quickshell

QtObject {
    id: root
    property var _current: null

    function open(popup) {
        if (_current !== null && _current !== popup)
            _current.close()
        _current = popup
    }
}
