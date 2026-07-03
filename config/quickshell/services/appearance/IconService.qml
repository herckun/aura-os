pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"

Singleton {
  id: svc

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC STATE
  // ═══════════════════════════════════════════════════════════════

  property var iconCache: ({})
  property var pendingClasses: []
  property bool resolving: false

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════

  function iconPath(appClass: string): string {
    if (!appClass) return ""
    _cacheGeneration
    return iconCache[appClass.toLowerCase()] || ""
  }

  function resolve(classes: var): void {
    var unknown = []
    for (var i = 0; i < classes.length; i++) {
      var c = classes[i].toLowerCase()
      if (c && !iconCache[c] && pendingClasses.indexOf(c) < 0) unknown.push(c)
    }
    if (unknown.length === 0) return

    pendingClasses = unknown
    resolving = true
    var script = ["python3", resolveScript].concat(unknown)
    ProcessPool.runTracked("Resolve icons", script, {
      id: "resolve-icons",
      callback: function(r) {
        if (r.exitCode !== 0) {
          svc.pendingClasses = []
          svc.resolving = false
          return
        }
        try {
          var parsed = JSON.parse(r.stdout)
          var cache = {}
          var old = svc.iconCache
          for (var k in old) {
            if (old.hasOwnProperty(k)) cache[k] = old[k]
          }
          for (var key in parsed) {
            if (parsed.hasOwnProperty(key)) cache[key.toLowerCase()] = parsed[key]
          }
          svc.iconCache = cache
          svc._cacheGeneration++
        } catch (e) {
        }
        svc.pendingClasses = []
        svc.resolving = false
      }
    })
  }

  // ═══════════════════════════════════════════════════════════════
  //  INTERNAL STATE
  // ═══════════════════════════════════════════════════════════════

  property int _cacheGeneration: 0
  property string resolveScript: AppInfo.configHome + "/features/system/resolve-icon.py"

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════
  //  SYSTEM INTEGRATION
  // ═══════════════════════════════════════════════════════════════

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
