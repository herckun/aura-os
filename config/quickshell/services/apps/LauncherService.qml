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

  property var desktopEntries: ([])
  property var filteredEntries: ([])
  property string searchQuery: ""
  property bool loaded: false

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════

  function search(query: string): void {
    svc.searchQuery = query.toLowerCase()

    if (!svc.loaded) {
      svc._pendingQuery = query
      svc.index()
      return
    }

    if (svc.searchQuery === "") {
      svc.filteredEntries = svc.desktopEntries
      return
    }
    var results = []
    for (var i = 0; i < svc.desktopEntries.length; i++) {
      var e = svc.desktopEntries[i]
      var name = (e.name || "").toLowerCase()
      var kw = (e.keywords || "").toLowerCase()
      var cat = (e.category || "").toLowerCase()
      if (name.indexOf(svc.searchQuery) >= 0 ||
          kw.indexOf(svc.searchQuery) >= 0 ||
          cat.indexOf(svc.searchQuery) >= 0) {
        results.push(e)
      }
      if (results.length > 20) break
    }
    svc.filteredEntries = results
  }

  function launch(entry: var): void {
    var raw = (entry.exec || "").trim()
    if (raw === "") return
    var cleaned = raw.replace(/%[fFuUdDnNiIcCkKvVmM%]/g, "").trim()
    if (cleaned === "") return
    var tokens = cleaned.match(/(?:[^\s"']+|"[^"]*"|'[^']*')+/g)
    if (!tokens || tokens.length === 0) return
    tokens = tokens.map(function(t) {
      if (t.length >= 2 &&
          ((t[0] === '"' && t[t.length - 1] === '"') ||
           (t[0] === "'" && t[t.length - 1] === "'"))) return t.slice(1, -1)
      return t
    })
    ProcessPool.runDetached(tokens)
  }

  function index(): void {
    if (svc._indexing) return
    svc._indexing = true
    ProcessPool.runTracked("Index desktops", [AppInfo.configHome + "/features/system/index-desktops.sh"], {
      id: "index-desktops",
      callback: function(r) {
        if (r.exitCode !== 0) {
          svc._indexing = false
          return
        }
        var entries = []
        var lines = r.stdout.trim().split("\n")
        for (var i = 0; i < lines.length; i++) {
          var parts = lines[i].split("||")
          if (parts.length >= 2 && parts[0] && parts[1]) {
            entries.push({
              name: parts[0], exec: parts[1], icon: parts[2] || "",
              keywords: parts[3] || "", category: parts[4] || ""
            })
          }
        }
        svc.desktopEntries = entries
        svc.loaded = true
        svc._indexing = false
        if (svc._pendingQuery !== null) {
          svc.search(svc._pendingQuery)
          svc._pendingQuery = null
        } else if (svc.searchQuery !== "") {
          // A re-scan finished while a query was active — recompute against the
          // fresh entries so a just-installed app shows without another keystroke.
          svc.search(svc.searchQuery)
        }
      }
    })
  }

  // ═══════════════════════════════════════════════════════════════
  //  INTERNAL STATE
  // ═══════════════════════════════════════════════════════════════

  property bool _indexing: false
  property var _pendingQuery: null

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
