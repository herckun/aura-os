pragma Singleton
pragma ComponentBehavior: Bound
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

  property bool active: false
  property string clipboardText: ""
  property list<string> clipboardHistory: []

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════

  function setClipboard(text: string): void {
    ProcessPool.runDetached('printf \'%s\' ' + JSON.stringify(text) + ' | wl-copy', {
      shell: true
    })
    _record(text)
  }

  function clearHistory(): void {
    svc.clipboardHistory = []
  }

  // ═══════════════════════════════════════════════════════════════
  //  INTERNAL STATE
  // ═══════════════════════════════════════════════════════════════

  readonly property int _maxHistory: 50

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════

  function _record(text: string): void {
    if (svc.clipboardText === text) return

    svc.clipboardText = text

    var h = svc.clipboardHistory.filter(function(x) { return x !== text })
    h.unshift(text)

    if (h.length > svc._maxHistory) {
      h.pop()
    }

    svc.clipboardHistory = h
  }

  function _startWatching(): void {
    ProcessPool.runTracked("Clipboard seed",
      "wl-paste -n -t text/plain 2>/dev/null | tr '\\n\\r' '  '",
      { id: "clipboard-seed", shell: true, callback: function(r) {
        var t = (r.stdout || "").trim()
        if (t) svc._record(t)
      }
    })

    WatchService.register("clipboard-watch",
      "wl-paste --watch sh -c \"wl-paste -n -t text/plain 2>/dev/null | tr '\\n\\r' '  '; echo\"",
      function(text) {
        text = text.trim()
        if (!text) return
        svc._record(text)
      }
    )
  }

  function _stopWatching(): void {
    WatchService.unregister("clipboard-watch")
  }

  // ═══════════════════════════════════════════════════════════════
  //  SYSTEM INTEGRATION
  // ═══════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════
  //  SIGNAL CONNECTIONS
  // ═══════════════════════════════════════════════════════════════

  onActiveChanged: {
    if (svc.active) {
      _startWatching()
    } else {
      _stopWatching()
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  TIMERS
  // ═══════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════

}