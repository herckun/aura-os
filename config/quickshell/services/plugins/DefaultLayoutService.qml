pragma Singleton
import QtQml
import QtQuick
import Quickshell
import "../../core"

Singleton {
  id: svc

  property bool _pendingApply: false

  function init(): void {
    if (Store.freshInstall) _applyWhenReady()
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

      for (var j = 0; j < locs.length; j++) {
        var loc = locs[j]
        var spec = dl[loc] || {}
        var on = spec.enabled !== undefined ? spec.enabled === true : declared.indexOf(loc) >= 0
        enabled[p.id + "@" + loc] = on

        if (on) {
          if (!byLocation[loc]) byLocation[loc] = []
          byLocation[loc].push({ id: p.id, order: spec.order !== undefined ? spec.order : 100 })
        }

        if (spec.settings)
          for (var sk in spec.settings)
            settings[p.id + "@" + loc + ":" + sk] = spec.settings[sk]

        if (spec.position && spec.position.x !== undefined && spec.position.y !== undefined)
          widgets[p.id] = { x: spec.position.x, y: spec.position.y }
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
    target: PluginService
    function onPluginsUpdated() {
      if (svc._pendingApply && PluginService.plugins.length > 0) {
        svc._pendingApply = false
        svc.apply()
      }
    }
  }
}
