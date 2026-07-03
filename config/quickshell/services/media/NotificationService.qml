pragma Singleton
pragma ComponentBehavior: Bound
import QtQml
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "../../core"

Singleton {
  id: svc

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC STATE
  // ═══════════════════════════════════════════════════════════════

  property var notifications: ([])
  property int unreadCount: 0

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════

  // ── Sending ──

  function push(summary: string, body: string, icon: string, appName: string, urgency: int, actions: var): void {
    var notification = _createNotification(summary, body, icon, appName, urgency, actions)
    var updated = [notification].concat(svc.notifications)

    if (updated.length > _maxNotifications) {
      updated = updated.slice(0, _maxNotifications)
    }

    svc.notifications = updated
    _recalcUnread()
  }

  function notify(label: string, message: string, icon: string, urgency: int): void {
    svc.push(label, message, Icons.get(icon || "info"), AppInfo.displayName, urgency ?? 1, [])
  }

  function systemNotify(label: string, message: string, urgency: int): void {
    svc.push(label, message, AppInfo.logoPath(), AppInfo.displayName, urgency ?? 1, [])
  }

  // ── Management ──

  function markRead(id: string): void {
    svc.notifications = svc.notifications.map(function(n) {
      return n.id === id ? Object.assign({}, n, { read: true }) : n
    })
    _recalcUnread()
  }

  function dismiss(id: string): void {
    svc.notifications = svc.notifications.filter(function(n) { return n.id !== id })
    _recalcUnread()
  }

  function clearAll(): void {
    svc.notifications = []
    svc.unreadCount = 0
  }

  function markAllRead(): void {
    svc.notifications = svc.notifications.map(function(n) {
      return Object.assign({}, n, { read: true })
    })
    svc.unreadCount = 0
  }

  // ═══════════════════════════════════════════════════════════════
  //  INTERNAL STATE
  // ═══════════════════════════════════════════════════════════════

  readonly property int _maxNotifications: 100

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════

  function _generateId(): string {
    return Date.now().toString(36) + Math.random().toString(36).substr(2)
  }

  function _createNotification(summary: string, body: string, icon: string, appName: string, urgency: int, actions: var): object {
    return {
      id: _generateId(),
      summary: summary || "",
      body: body || "",
      icon: icon || "",
      appName: appName || "",
      urgency: urgency ?? 1,
      actions: actions || [],
      time: new Date(),
      read: false
    }
  }

  function _parseActions(notifActions: var): var {
    if (!notifActions) return []

    var result = []
    for (var i = 0; i < notifActions.length; i++) {
      var a = notifActions[i]
      result.push({ identifier: a.identifier || "", text: a.text || "" })
    }
    return result
  }

  function _recalcUnread(): void {
    svc.unreadCount = svc.notifications.filter(function(n) { return !n.read }).length
  }

  // ═══════════════════════════════════════════════════════════════
  //  SYSTEM INTEGRATION
  // ═══════════════════════════════════════════════════════════════

  NotificationServer {
    id: notifServer
    keepOnReload: true

    onNotification: function(notif) {
      var actions = _parseActions(notif.actions)
      svc.push(notif.summary, notif.body, notif.appIcon, notif.appName, notif.urgency, actions)
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  SIGNAL CONNECTIONS
  // ═══════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════
  //  TIMERS
  // ═══════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════

}