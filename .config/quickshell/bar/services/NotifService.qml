pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

QtObject {
    id: root

    property var notifications: []
    property int unreadCount: 0
    readonly property bool hasUnread: unreadCount > 0

    signal newNotification(var item)

    function _pwaName(notif) {
        const text = ((notif.body || "") + " " + (notif.summary || "")).toLowerCase()
        if (text.includes("outlook.office.com") || text.includes("outlook.live.com")) return "Outlook"
        if (text.includes("teams.microsoft.com")) return "Microsoft Teams"
        if (text.includes("mail.google.com")) return "Gmail"
        if (text.includes("discord.com")) return "Discord"
        return null
    }

    function displayName(notif) {
        if (!notif) return "Unknown"
        const name = (notif.appName || "").toLowerCase()
        if (name === "chromium" || name === "chrome" || name === "google-chrome")
            return _pwaName(notif) || notif.appName || "Unknown"
        return notif.appName || "Unknown"
    }

    function iconSource(notif) {
        if (!notif) return ""
        const appName = (notif.appName || "").toLowerCase()
        const iconMap = {
            "outlook":          "Outlook",
            "outlook calendar": "Outlook Calendar",
            "microsoft teams":  "Microsoft Teams",
            "teams":            "Microsoft Teams",
            "reddit":           "Reddit",
            "whatsapp":         "WhatsApp",
            "youtube":          "YouTube",
            "youtube music":    "YouTube",
            "jellyfin":         "Jellyfin",
            "fotmob":           "Fotmob",
            "chatgpt":          "ChatGPT",
            "claude":           "Claude",
            "discord":          "Discord",
            "github":           "GitHub",
            "gmail":            "Gmail",
            "hotmail":          "Hotmail",
            "notion":           "Outlook",
        }

        if (appName === "chromium" || appName === "chrome" || appName === "google-chrome") {
            const pwa = _pwaName(notif)
            if (pwa && iconMap[pwa.toLowerCase()])
                return "file:///home/bubba/.local/share/applications/icons/" + iconMap[pwa.toLowerCase()] + ".png"
        }

        const icon = notif.appIcon || ""
        if (icon.startsWith("/")) return "file://" + icon
        if (icon.length > 0) return "image://icon/" + icon
        const mapped = iconMap[appName]
        return mapped ? "file:///home/bubba/.local/share/applications/icons/" + mapped + ".png" : ""
    }

    function dismiss(item) {
        const ts = item.arrivedAt
        notifications = notifications.filter(n => n.arrivedAt !== ts)
        try { item.notif.tracked = false } catch(e) {}
        if (unreadCount > 0) unreadCount--
    }

    function dismissAll() {
        for (const item of notifications)
            try { item.notif.tracked = false } catch(e) {}
        notifications = []
        unreadCount = 0
    }

    function markAllRead() { unreadCount = 0 }

    function snooze(item, minutes) {
        const triggerAt = Date.now() + minutes * 60000
        notifications = notifications.map(n =>
            n.arrivedAt === item.arrivedAt
                ? { notif: n.notif, arrivedAt: n.arrivedAt, snoozedUntil: triggerAt }
                : n
        )
    }

    function cancelSnooze(item) {
        notifications = notifications.map(n =>
            n.arrivedAt === item.arrivedAt
                ? { notif: n.notif, arrivedAt: n.arrivedAt, snoozedUntil: null }
                : n
        )
    }

    function cleanBody(notif) {
        let body = notif.body || ""
        const name = (notif.appName || "").toLowerCase()
        if (name === "chromium" || name === "chrome" || name === "google-chrome") {
            const parts = body.split(" ")
            if (parts.length > 1 && parts[0].includes("."))
                body = parts.slice(1).join(" ")
        }
        return body
    }

    function snoozeCountdown(ms) {
        const remaining = Math.max(0, ms - Date.now())
        const mins = Math.floor(remaining / 60000)
        const secs = Math.floor((remaining % 60000) / 1000)
        if (remaining <= 0) return "0:00"
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    function relativeTime(ms) {
        if (!ms) return ""
        const diff = Date.now() - ms
        if (diff < 60000)    return "now"
        if (diff < 3600000)  return Math.floor(diff / 60000) + "m"
        if (diff < 86400000) return Math.floor(diff / 3600000) + "h"
        return Math.floor(diff / 86400000) + "d"
    }

    property Timer snoozeChecker: Timer {
        interval: 1000
        running: {
            for (var i = 0; i < root.notifications.length; i++)
                if (root.notifications[i].snoozedUntil) return true
            return false
        }
        repeat: true
        onTriggered: {
            const now = Date.now()
            let anyExpired = false
            const updated = root.notifications.map(item => {
                if (!item.snoozedUntil || item.snoozedUntil > now) return item
                anyExpired = true
                const unsnooze = { notif: item.notif, arrivedAt: Date.now(), snoozedUntil: null }
                root.unreadCount++
                root.newNotification(unsnooze)
                return unsnooze
            })
            if (anyExpired) root.notifications = updated
        }
    }

    property NotificationServer server: NotificationServer {
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true

        onNotification: function(notif) {
            notif.tracked = true
            const item = { notif: notif, arrivedAt: Date.now(), snoozedUntil: null }
            root.notifications = [item].concat(root.notifications).slice(0, 50)
            root.unreadCount++
            root.newNotification(item)
        }
    }
}
