pragma Singleton
import QtQml
import QtQuick
import Quickshell
import "../../core"
import "../"

// ═══════════════════════════════════════════════════════════════════
//  SearchService — unified, provider-driven search results.
//  SearchService.submit(queryId, providerId, rows) for async results.
// ═══════════════════════════════════════════════════════════════════

Singleton {
  id: svc

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC STATE
  // ═══════════════════════════════════════════════════════════════
  property var results: ([])
  property string query: ""

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════
  function registerProvider(provider): void {
    if (!provider || !provider.id) return
    for (var i = 0; i < svc._providers.length; i++) {
      if (svc._providers[i].id === provider.id) { svc._providers[i] = provider; svc._sortProviders(); return }
    }
    svc._providers.push(provider)
    svc._sortProviders()
  }

  function unregisterProvider(providerId: string): void {
    svc._providers = svc._providers.filter(function(p) { return p.id !== providerId })
  }

  function search(text: string): void {
    svc.query = text
    svc._queryId++
    var qid = svc._queryId
    svc._buffer = ({})
    if (!text || text.length === 0) { svc._rebuild(); return }

    for (var i = 0; i < svc._providers.length; i++) {
      var p = svc._providers[i]
      var out = null
      try { out = p.query ? p.query(text, qid) : null } catch (e) { out = null }
      if (out && out.length !== undefined) svc._buffer[p.id] = out
    }
    svc._rebuild()
  }

  function submit(queryId: int, providerId: string, rows: var): void {
    if (queryId !== svc._queryId) return
    svc._buffer[providerId] = rows || []
    svc._rebuild()
  }

  function activate(index: int): void {
    if (index < 0 || index >= svc.results.length) return
    var r = svc.results[index]
    if (r && typeof r.action === "function") r.action()
  }

  // ═══════════════════════════════════════════════════════════════
  //  INTERNAL STATE
  // ═══════════════════════════════════════════════════════════════
  property var _providers: ([])
  property int _queryId: 0
  property var _buffer: ({})

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════
  function _sortProviders(): void {
    svc._providers.sort(function(a, b) { return (b.priority || 0) - (a.priority || 0) })
  }

  function _rebuild(): void {
    var merged = []
    for (var i = 0; i < svc._providers.length; i++) {
      var rows = svc._buffer[svc._providers[i].id]
      if (rows && rows.length) merged = merged.concat(rows)
    }
    svc.results = merged.slice(0, 40)
  }

  function _mapApps(entries: var): var {
    var out = []
    for (var i = 0; i < entries.length; i++) {
      (function(e) {
        out.push({
          id: "app:" + (e.exec || e.name),
          label: e.name || "",
          sublabel: "",
          icon: e.icon || "",
          iconKind: "app",
          priority: 100,
          source: "apps",
          groupLabel: "Applications",
          action: function() { LauncherService.launch(e) }
        })
      })(entries[i])
    }
    return out
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILT-IN PROVIDERS
  // ═══════════════════════════════════════════════════════════════
  readonly property var _appsProvider: ({
    id: "apps",
    priority: 100,
    query: function(text, qid) {
      LauncherService.search(text)
      return svc._mapApps(LauncherService.filteredEntries)
    }
  })

  readonly property var _calcProvider: ({
    id: "calc",
    priority: 300,
    query: function(text, qid) {
      if (text.indexOf("=") !== 0 || text.length < 2) return []
      var expr = text.substring(1)
      ProcessPool.runTracked("Search calc", ["qalc", "-t", expr], {
        id: "search-calc",
        callback: function(r) {
          var out = r.stdout.trim()
          if (!out || out.indexOf("error") >= 0 || out.length > 40) { svc.submit(qid, "calc", []); return }
          svc.submit(qid, "calc", [{
            id: "calc:result",
            label: out,
            sublabel: expr + " =",
            icon: "calculator",
            iconKind: "symbolic",
            priority: 300,
            source: "calc",
            groupLabel: "Calculator",
            action: function() { ProcessPool.runDetached(["sh", "-c", "printf %s " + JSON.stringify(out) + " | wl-copy"]) }
          }])
        }
      })
      return null
    }
  })

  // ═══════════════════════════════════════════════════════════════
  //  SIGNAL CONNECTIONS
  // ═══════════════════════════════════════════════════════════════
  // Re-emit app results when the async desktop index resolves.
  Connections {
    target: LauncherService
    function onFilteredEntriesChanged() {
      if (svc.query.length === 0) return
      svc.submit(svc._queryId, "apps", svc._mapApps(LauncherService.filteredEntries))
    }
  }

  Connections {
    target: PluginService
    function onPluginsUpdated() { svc._syncPluginProviders() }
  }

  function _syncPluginProviders(): void {
    var plugins = PluginService.plugins || []
    for (var i = 0; i < plugins.length; i++) {
      var p = plugins[i]
      if (p && p.searchProvider && p.searchProvider.id)
        svc.registerProvider(p.searchProvider)
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════
  Component.onCompleted: {
    svc.registerProvider(svc._appsProvider)
    svc.registerProvider(svc._calcProvider)
    svc._syncPluginProviders()
  }
}
