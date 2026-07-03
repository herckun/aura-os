pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../"

Item {
  id: base
  visible: false

  // ── Manifest (override in subclass) ──────────────────────────────
  // `id:` is a reserved QML handle, so plugins set pluginId; id mirrors it.
  property string pluginId: ""
  readonly property string id: pluginId
  property var manifest: ({ name: "", description: "", author: "", version: "", shellVersion: "", icon: "", locations: [], settings: [] })
  property string primaryLocation: (manifest && manifest.locations && manifest.locations.length) ? manifest.locations[0] : ""

  // ── Public state ─────────────────────────────────────────────────
  readonly property bool enabled: base._enabled

  // ── Internal state ───────────────────────────────────────────────
  property bool _enabled: false
  property bool _ready: false

  // ── Overridable hooks (default no-ops) ───────────────────────────
  function onActivated(): void {}
  function onDeactivated(): void {}
  function onSettingChanged(key, value): void {}
  function stopAllActivity(): void {}

  // ── Helpers ──────────────────────────────────────────────────────
  function setting(key: string): var {
    return PluginService.getPluginSetting(base.id, key, base.primaryLocation)
  }

  function _set(prop, value): bool {
    if (base[prop] === value) return false
    base[prop] = value
    return true
  }

  function _arraysEqual(a, b): bool {
    if (!a || !b) return a === b
    if (a.length !== b.length) return false
    for (var i = 0; i < a.length; i++) { if (a[i] !== b[i]) return false }
    return true
  }

  function _setArray(prop, value): bool {
    if (_arraysEqual(base[prop], value)) return false
    base[prop] = value
    return true
  }

  // ── PluginService signal wiring ──────────────────────────────────
  Connections {
    target: PluginService

    function onPluginEnabledChanged(pluginId, location, en) {
      if (pluginId !== base.id || location !== base.primaryLocation || !base._ready) return
      base._enabled = en
      if (en) base.onActivated()
      else { base.stopAllActivity(); base.onDeactivated() }
    }

    function onPluginSettingChanged(pluginId, key, value, location) {
      if (pluginId !== base.id || !base._ready) return
      base.onSettingChanged(key, value)
    }
  }

  // ── Lifecycle ────────────────────────────────────────────────────
  Component.onCompleted: {
    PluginService.registerPlugin(base)
    if (base.primaryLocation)
      base._enabled = PluginService.isPluginEnabledForLocation(base.id, base.primaryLocation)
    base._ready = true
    if (base._enabled) Qt.callLater(base.onActivated)
  }

  Component.onDestruction: base.stopAllActivity()
}
