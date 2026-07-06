pragma Singleton
import QtQml
import QtQuick
import Quickshell
import "../../core"

Singleton {
  id: svc

  property bool _pendingApply: false

  function init(): void {
    if (Store.freshInstall || Store.plugins.resetPending === true)
      _applyWhenReady()
  }

  function apply(): void {
    var enabled = ({})
    var settings = ({})
    var widgets = ({})
    var byLocation = ({})

    var plugins = PluginService.plugins
    for (var i = 0; i < plugins.length; i++) {
      var p = plugins[i]
      var m = p.manifest || {}
      var declared = m.locations || []
      var dl = m.defaultLayout || {}

      var locs = declared.slice()
      for (var key in dl)
        if (locs.indexOf(key) < 0) locs.push(key)

      var entries = []
      var anyOn = false
      for (var j = 0; j < locs.length; j++) {
        var loc = locs[j]
        var spec = dl[loc] || {}
        var on = spec.enabled !== undefined ? spec.enabled === true : declared.indexOf(loc) >= 0
        if (on) anyOn = true
        entries.push({ loc: loc, spec: spec, on: on })
      }

      if (!anyOn)
        for (var e = 0; e < entries.length; e++)
          if (declared.indexOf(entries[e].loc) >= 0) entries[e].on = true

      for (var n = 0; n < entries.length; n++) {
        var entry = entries[n]
        enabled[p.id + "@" + entry.loc] = entry.on

        if (entry.on) {
          if (!byLocation[entry.loc]) byLocation[entry.loc] = []
          byLocation[entry.loc].push({ id: p.id, order: entry.spec.order !== undefined ? entry.spec.order : 100 })
        }

        if (entry.on && entry.loc === "desktop")
          settings[p.id + "@desktop:autoPosition"] = true

        if (entry.spec.settings)
          for (var sk in entry.spec.settings)
            settings[p.id + "@" + entry.loc + ":" + sk] = entry.spec.settings[sk]

        if (entry.spec.position && entry.spec.position.x !== undefined && entry.spec.position.y !== undefined)
          widgets[p.id] = { x: entry.spec.position.x, y: entry.spec.position.y }
      }
    }

    var order = ({})
    for (var location in byLocation) {
      byLocation[location].sort(function(a, b) {
        if (a.order !== b.order) return a.order - b.order
        return a.id < b.id ? -1 : 1
      })
      order[location] = byLocation[location].map(function(e) { return e.id })
    }

    Store.plugins.enabled = enabled
    Store.plugins.order = order

    var s = Object.assign({}, Store.toObject(Store.plugins.settings))
    for (var k in settings) s[k] = settings[k]
    Store.plugins.settings = s

    var w = Object.assign({}, Store.toObject(Store.desktop.widgets))
    for (var id in widgets) w[id] = Object.assign({}, w[id] || {}, widgets[id])
    Store.desktop.widgets = w

    Store.plugins.resetPending = false
  }

  function _applyWhenReady(): void {
    if (PluginService.plugins.length > 0) {
      apply()
      return
    }
    _pendingApply = true
  }

  Connections {
    target: Store
    function onFreshInstallChanged() {
      if (Store.freshInstall) svc._applyWhenReady()
    }
  }

  Connections {
    target: Store.plugins
    function onResetPendingChanged() {
      if (Store.plugins.resetPending) svc._applyWhenReady()
    }
  }

  Connections {
    target: PluginService
    function onPluginsUpdated() {
      if (svc._pendingApply && PluginService.plugins.length > 0) {
        svc._pendingApply = false
        svc.apply()
      }
    }
  }
}
