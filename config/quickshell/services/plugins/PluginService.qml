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
  property var plugins: []
  property bool loaded: false
  property var pluginIcons: ({})

  property bool debug: Quickshell.env("QS_PLUGIN_DEBUG") === "1"

  signal pluginEnabledChanged(string pluginId, string location, bool enabled)
  signal pluginSettingChanged(string pluginId, string key, var value, string location)
  signal pluginsUpdated()

  // ═══════════════════════════════════════════════════════════════
  //  INTERNAL STATE
  // ═══════════════════════════════════════════════════════════════
  property bool _batching: false
  property bool _batchDirty: false

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════
  function beginBatch(): void {
    _batching = true
    _batchDirty = false
  }

  function endBatch(): void {
    _batching = false
    if (_batchDirty) {
      _batchDirty = false
      svc.pluginsUpdated()
    }
  }

  function registerPlugin(pluginInstance): void {
    for (var i = 0; i < plugins.length; i++) {
      if (plugins[i].id === pluginInstance.id) return
    }
    plugins.push(pluginInstance)

    var icons = pluginInstance.manifest.icons || {}
    var iconKeys = Object.keys(icons)
    if (iconKeys.length > 0) {
      var updated = JSON.parse(JSON.stringify(pluginIcons))
      for (var m = 0; m < iconKeys.length; m++)
        updated[iconKeys[m]] = icons[iconKeys[m]]
      pluginIcons = updated
    }

    plugins = plugins.slice()
    _emitUpdated()
  }

  function canRenderAt(plugin, location: string): bool {
    if (!plugin || !plugin.manifest) return false
    var prop = componentMap[location]
    if (!prop) return (plugin.manifest.locations || []).indexOf(location) >= 0
    return !!plugin[prop]
  }

  function groupSections(location: string): var {
    var g = _groupOf(location)
    return g ? _sectionsInGroup(g) : []
  }

  function movableSections(pluginId: string, location: string): var {
    var p = _findPlugin(pluginId)
    if (!p) return []
    var sections = groupSections(location)
    var r = []
    for (var i = 0; i < sections.length; i++)
      if (canRenderAt(p, sections[i])) r.push(sections[i])
    return r
  }

  function isPluginEnabledForLocation(pluginId: string, location: string): bool {
    var val = Store.plugins.enabled[_ekey(pluginId, location)]
    if (val !== undefined) return val
    for (var i = 0; i < plugins.length; i++) {
      if (plugins[i].id === pluginId)
        return (plugins[i].manifest.locations || []).indexOf(location) >= 0
    }
    return false
  }

  function currentSection(pluginId: string, location: string): string {
    var group = _groupOf(location)
    if (!group) return location
    var sections = _sectionsInGroup(group)
    for (var i = 0; i < sections.length; i++) {
      if (isPluginEnabledForLocation(pluginId, sections[i])) return sections[i]
    }
    var p = _findPlugin(pluginId)
    if (p) {
      var locs = p.manifest.locations || []
      for (var j = 0; j < locs.length; j++)
        if (_groupOf(locs[j]) === group) return locs[j]
    }
    return sections.length ? sections[0] : location
  }

  function getPluginsForLocation(location: string): var {
    var result = []
    for (var i = 0; i < plugins.length; i++) {
      var p = plugins[i]
      if (canRenderAt(p, location)) result.push(p)
    }
    var order = Store.plugins.order[location] || []
    var orderMap = ({})
    for (var j = 0; j < order.length; j++) orderMap[order[j]] = j
    result.sort(function(a, b) {
      var oa = orderMap.hasOwnProperty(a.id) ? orderMap[a.id] : 999
      var ob = orderMap.hasOwnProperty(b.id) ? orderMap[b.id] : 999
      return oa - ob
    })
    return result
  }

  function getPluginsAssignedToSection(location: string): var {
    var group = _groupOf(location)
    if (!group) return getPluginsForLocation(location)
    var all = getPluginsForLocation(location)
    var result = []
    for (var i = 0; i < all.length; i++) {
      if (currentSection(all[i].id, location) === location) result.push(all[i])
    }
    return result
  }

  function setPluginEnabledForLocation(pluginId: string, location: string, enabled: bool): void {
    Store.plugins.enabled = Store.mapSet(Store.plugins.enabled, _ekey(pluginId, location), enabled)
    svc.pluginEnabledChanged(pluginId, location, enabled)
    _emitUpdated()
  }

  function movePluginToLocation(pluginId: string, toLocation: string): void {
    var group = _groupOf(toLocation)
    if (!group) return
    var sections = _sectionsInGroup(group)
    beginBatch()
    var enabledMap = Object.assign({}, Store.plugins.enabled)
    for (var i = 0; i < sections.length; i++) {
      var sec = sections[i]
      var enabled = (sec === toLocation)
      var was = isPluginEnabledForLocation(pluginId, sec)
      enabledMap[_ekey(pluginId, sec)] = enabled
      if (was !== enabled) svc.pluginEnabledChanged(pluginId, sec, enabled)
    }
    Store.plugins.enabled = enabledMap
    var order = Store.toArray(Store.plugins.order[toLocation])
    var idx = order.indexOf(pluginId)
    if (idx >= 0) order.splice(idx, 1)
    order.push(pluginId)
    Store.plugins.order = Store.mapSet(Store.plugins.order, toLocation, order)
    endBatch()
  }

  function setPluginOrder(location: string, orderedIds: var): void {
    Store.plugins.order = Store.mapSet(Store.plugins.order, location, orderedIds)
    _emitUpdated()
  }

  function getPluginSetting(pluginId: string, key: string, location: string): var {
    if (location) {
      var val = Store.plugins.settings[_skey(pluginId, key, location)]
      if (val !== undefined) return val
    }
    var val = Store.plugins.settings[_skey(pluginId, key, "")]
    if (val !== undefined) return val
    var p = _findPlugin(pluginId)
    if (p) {
      var defs = p.manifest.settings || []
      for (var j = 0; j < defs.length; j++)
        if (defs[j].key === key) return defs[j].default
    }
    return null
  }

  function setPluginSetting(pluginId: string, key: string, value: var, location: string): void {
    Store.plugins.settings = Store.mapSet(Store.plugins.settings, _skey(pluginId, key, location), value)
    svc.pluginSettingChanged(pluginId, key, value, location || "")
    _emitUpdated()
  }

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════
  function _emitUpdated(): void {
    if (_batching) {
      _batchDirty = true
      return
    }
    svc.pluginsUpdated()
  }

  function _ekey(pluginId, location): string {
    return pluginId + "@" + location
  }

  function _skey(pluginId, key, location): string {
    return location ? pluginId + "@" + location + ":" + key
                    : pluginId + ":" + key
  }

  // ═══════════════════════════════════════════════════════════════
  //  SYSTEM INTEGRATION
  // ═══════════════════════════════════════════════════════════════
  readonly property var componentMap: ({
    "connectivity": "connectivityComponent",
    "controlcenter_row": "controlCenterComponent",
    "overview": "overviewComponent",
    "audio": "audioComponent",
    "appearance": "appearanceComponent",
    "wallpaper": "wallpaperComponent",
    "desktop": "desktopComponent",
    "about": "aboutComponent",
    "bar_left": "barComponent",
    "bar_center": "barComponent",
    "bar_right": "barComponent",
    "dashboard": "dashboardComponent"
  })

  function _groupOf(location: string): string {
    var i = location.indexOf("_")
    return i > 0 ? location.substring(0, i) : ""
  }

  function _sectionsInGroup(group: string): var {
    var r = []
    for (var k in componentMap) if (_groupOf(k) === group) r.push(k)
    return r
  }

  function _findPlugin(pluginId: string): var {
    for (var i = 0; i < plugins.length; i++)
      if (plugins[i].id === pluginId) return plugins[i]
    return null
  }

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════
  Component.onCompleted: {
    loaded = true
    _emitUpdated()
  }
}
