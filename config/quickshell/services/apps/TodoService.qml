pragma Singleton
import QtQml
import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"

Singleton {
  id: svc

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC STATE
  // ═══════════════════════════════════════════════════════════════

  property var tasks: ([])
  property int activeCount: svc.tasks.filter(function(t) { return !t.done }).length

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════

  function add(text: string): void {
    var next = svc.tasks.slice()
    next.push({ id: Date.now().toString(36), text: text, done: false })
    svc.tasks = next
    svc._save()
  }

  function toggle(id: string): void {
    var next = svc.tasks.map(function(t) {
      return t.id === id ? { id: t.id, text: t.text, done: !t.done } : t
    })
    svc.tasks = next
    svc._save()
  }

  function remove(id: string): void {
    svc.tasks = svc.tasks.filter(function(t) { return t.id !== id })
    svc._save()
  }

  function clearDone(): void {
    svc.tasks = svc.tasks.filter(function(t) { return !t.done })
    svc._save()
  }

  // ═══════════════════════════════════════════════════════════════
  //  INTERNAL STATE
  // ═══════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════

  function _load(): void {
    ProcessPool.runQueued("Todo load", "cat " + AppInfo.cacheHome + "/todos.json 2>/dev/null || echo '[]'", {
      id: "todo-load",
      shell: true,
      silent: true,
      callback: function(r) {
        try {
          svc.tasks = JSON.parse(r.stdout.trim()) || []
        } catch (e) {
          svc.tasks = []
        }
      }
    })
  }

  function _save(): void {
    var json = JSON.stringify(svc.tasks)
    ProcessPool.runDetached(["sh", "-c", "mkdir -p \"$1\" && printf '%s' \"$2\" > \"$1/todos.json\"", "--", AppInfo.cacheHome, json])
  }

  // ═══════════════════════════════════════════════════════════════
  //  SYSTEM INTEGRATION
  // ═══════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════
  //  SIGNAL CONNECTIONS
  // ═══════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════
  //  TIMERS
  // ═══════════════════════════════════════════════════════════════

  Timer {
    interval: 2000
    running: true
    repeat: false
    onTriggered: svc._load()
  }

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════

}
