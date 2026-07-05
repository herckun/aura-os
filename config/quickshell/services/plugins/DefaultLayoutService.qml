pragma Singleton
import QtQml
import QtQuick
import Quickshell
import "../../core"

Singleton {
  id: svc

  readonly property var enabled: ({
    "bar-workspaces@bar_left": true,
    "smartIsland@bar_center": true,
    "bar-status@bar_right": true,
    "notifications@bar_right": true,
    "system@bar_right": false,
    "weather@bar_right": false,
    "media@controlcenter_row": true,
    "weather@controlcenter_row": true,
    "system@controlcenter_row": true,
    "nightlight@controlcenter_row": true,
    "timer@controlcenter_row": true,
    "screenshot@controlcenter_row": true,
    "launchgroups@controlcenter_row": true,
    "disk@controlcenter_row": false,
    "notifications@controlcenter_row": false,
    "powerprofile@controlcenter_row": false,
    "docker@controlcenter_row": false,
    "workspaces@overview": true,
    "todo@overview": true,
    "notes@overview": true,
    "clipboard@overview": true,
    "timer@overview": false,
    "desktopclock@desktop": true,
    "audioviz@desktop": false,
    "lyrics@desktop": false,
    "resourcemonitor@desktop": false,
    "system@dashboard": true
  })

  readonly property var order: ({
    "bar_left": ["bar-workspaces"],
    "bar_center": ["smartIsland"],
    "bar_right": ["bar-status", "notifications"],
    "controlcenter_row": ["media", "weather", "system", "nightlight", "timer", "screenshot", "launchgroups"],
    "overview": ["workspaces", "todo", "notes", "clipboard"],
    "dashboard": ["system"]
  })

  readonly property var settings: ({
    "audioviz@desktop:showBackground": true,
    "lyrics@desktop:showBackground": true,
    "resourcemonitor@desktop:showBackground": true,
    "desktopclock@desktop:showBackground": false
  })

  readonly property var widgets: ({
    "desktopclock": { x: 0.72, y: 0.07 }
  })

  function init(): void {
    if (Store.freshInstall) apply()
  }

  Connections {
    target: Store
    function onFreshInstallChanged() {
      if (Store.freshInstall) svc.apply()
    }
  }

  function apply(): void {
    Store.plugins.enabled = Object.assign({}, enabled)
    Store.plugins.order = Object.assign({}, order)

    var s = Object.assign({}, Store.plugins.settings)
    for (var k in settings) s[k] = settings[k]
    Store.plugins.settings = s

    var w = Object.assign({}, Store.desktop.widgets)
    for (var id in widgets) w[id] = Object.assign({}, w[id] || {}, widgets[id])
    Store.desktop.widgets = w
  }
}
