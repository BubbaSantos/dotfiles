pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string filePath: Quickshell.env("HOME") + "/Dropbox/quickshell/timepieces.json"
    readonly property string soundPath: "/usr/share/sounds/freedesktop/stereo/bell.oga"

    property var todos: []
    property var reminders: []
    property var pomodoroConfig: ({ workMins: 25, shortBreakMins: 5, longBreakMins: 15, sessionsPerLongBreak: 4 })
    property int pomodoroCompleted: 0
    property bool use24hr: false
    property var pinnedTray: []
    property bool todosBarShow: true
    property string todosBarFilter: "highPriority"
    property string todosSort: "manual"
    property bool todosPriorityFirst: false
    property bool remindersBarShow: true

    property bool loaded: false

    // Number of reminders that have fired but not been dismissed
    readonly property int firedCount: reminders.filter(r => r.state === "fired").length

    function load() { loadProc.running = true }
    function save() { saveTimer.restart() }

    function _doSave() {
        const payload = JSON.stringify({
            todos: root.todos,
            reminders: root.reminders,
            pomodoroConfig: root.pomodoroConfig,
            pomodoroCompleted: root.pomodoroCompleted,
            use24hr: root.use24hr,
            pinnedTray: root.pinnedTray,
            todosBarShow: root.todosBarShow,
            todosBarFilter: root.todosBarFilter,
            todosSort: root.todosSort,
            todosPriorityFirst: root.todosPriorityFirst,
            remindersBarShow: root.remindersBarShow
        }, null, 2)

        const sentinel = "TIMEPIECES_EOF_" + Math.floor(Math.random() * 1e9)
        saveProc.command = ["sh", "-c",
            `mkdir -p "$(dirname '${root.filePath}')" && cat > '${root.filePath}' << '${sentinel}'\n${payload}\n${sentinel}`
        ]
        saveProc.running = true
    }

    function isPinned(id) { return pinnedTray.indexOf(id) !== -1 }

    function togglePin(id) {
        const idx = pinnedTray.indexOf(id)
        const next = pinnedTray.slice()
        if (idx === -1) next.push(id)
        else next.splice(idx, 1)
        pinnedTray = next
        save()
    }

    // ---- Reminder engine ----

    function advanceTriggerTime(currentIso, repeat) {
        const d = new Date(currentIso)
        if (repeat === "daily") {
            d.setDate(d.getDate() + 1)
        } else if (repeat === "weekdays") {
            // Skip to next weekday (Mon-Fri)
            do { d.setDate(d.getDate() + 1) } while (d.getDay() === 0 || d.getDay() === 6)
        } else if (repeat === "weekly") {
            d.setDate(d.getDate() + 7)
        } else if (repeat === "monthly") {
            d.setMonth(d.getMonth() + 1)
        }
        return d.toISOString()
    }

    function dismissReminder(id) {
        const next = reminders.map(r => {
            if (r.id !== id) return r
            // For repeating: advance to next occurrence and set back to pending
            if (r.repeat && r.repeat !== "none") {
                return Object.assign({}, r, {
                    state: "pending",
                    triggerAt: advanceTriggerTime(r.triggerAt, r.repeat),
                    firedAt: ""
                })
            }
            return Object.assign({}, r, { state: "dismissed" })
        }).filter(r => r.state !== "dismissed")  // remove dismissed one-offs
        reminders = next
        save()
    }

    function snoozeReminder(id, minutes) {
        const nowMs = Date.now()
        const next = reminders.map(r => {
            if (r.id !== id) return r
            const newTrigger = new Date(nowMs + minutes * 60 * 1000).toISOString()
            return Object.assign({}, r, {
                state: "pending",
                triggerAt: newTrigger,
                firedAt: ""
            })
        })
        reminders = next
        save()
    }

    function deleteReminder(id) {
        reminders = reminders.filter(r => r.id !== id)
        save()
    }

    function checkReminders() {
        const nowMs = Date.now()
        let anyFired = false
        const next = reminders.map(r => {
            if (r.state !== "pending") return r
            const triggerMs = new Date(r.triggerAt).getTime()
            if (triggerMs <= nowMs) {
                anyFired = true
                return Object.assign({}, r, {
                    state: "fired",
                    firedAt: new Date().toISOString()
                })
            }
            return r
        })

        // Only update if anything actually changed
        for (let i = 0; i < next.length; i++) {
            if (next[i] !== reminders[i]) {
                reminders = next
                if (anyFired) reminderSoundProc.running = true
                save()
                break
            }
        }
    }

    property Timer reminderTick: Timer {
        interval: 30 * 1000   // every 30s
        running: root.loaded
        repeat: true
        triggeredOnStart: true
        onTriggered: root.checkReminders()
    }

    property Process reminderSoundProc: Process {
        command: ["paplay", root.soundPath]
    }

    // ---- File I/O ----

    property Timer saveTimer: Timer {
        interval: 250
        onTriggered: root._doSave()
    }

    property Process loadProc: Process {
        command: ["cat", root.filePath]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim().length === 0) {
                    root.loaded = true
                    return
                }
                try {
                    const data = JSON.parse(text)
                    if (data.todos) root.todos = data.todos
                    if (data.reminders) root.reminders = data.reminders
                    if (data.pomodoroConfig) root.pomodoroConfig = data.pomodoroConfig
                    if (typeof data.pomodoroCompleted === "number") root.pomodoroCompleted = data.pomodoroCompleted
                    if (typeof data.use24hr === "boolean") root.use24hr = data.use24hr
                    if (data.pinnedTray) root.pinnedTray = data.pinnedTray
                    if (typeof data.todosBarShow === "boolean") root.todosBarShow = data.todosBarShow
                    if (data.todosBarFilter) root.todosBarFilter = data.todosBarFilter
                    if (data.todosSort) root.todosSort = data.todosSort
                    if (typeof data.todosPriorityFirst === "boolean") root.todosPriorityFirst = data.todosPriorityFirst
                    if (typeof data.remindersBarShow === "boolean") root.remindersBarShow = data.remindersBarShow
                } catch (e) {
                    console.warn("TimepiecesStore: parse failed", e)
                }
                root.loaded = true
            }
        }
        onExited: function(code) {
            if (code !== 0) root.loaded = true
        }
    }

    property Process saveProc: Process {}

    Component.onCompleted: load()
}
