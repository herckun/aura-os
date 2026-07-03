pragma Singleton
import QtQml
import QtQuick
import Quickshell
import "../../core"

Singleton {
  id: svc

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC STATE
  // ═══════════════════════════════════════════════════════════════
  readonly property var areas: [
    { id: "controlcenter", position: "top-right", action: "controlcenter" },
    { id: "launcher", position: "top-left", action: "launcher" },
    { id: "overview", position: "top-center", action: "overview" }
  ]

  property var enabledMap: ({
    "controlcenter": true,
    "launcher": false,
    "overview": false
  })

  readonly property var actionLabels: ({
    "controlcenter": "CONTROL CENTER",
    "launcher": "LAUNCHER",
    "overview": "OVERVIEW"
  })

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════
  function isEnabled(id: string): bool {
    return enabledMap[id] === true
  }

  function setEnabled(id: string, val: bool): void {
    var m = Object.assign({}, enabledMap)
    m[id] = val
    enabledMap = m
    Store.set("hotareas.enabled", enabledMap)
  }

  function triggerAction(action: string): void {
    IpcService.togglePanel(action)
  }

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════
  function _syncFromStore(): void {
    var saved = Store.get("hotareas.enabled", null)
    if (saved && typeof saved === "object") {
      var m = Object.assign({}, enabledMap)
      for (var k in saved)
        if (k in m) m[k] = saved[k]
      enabledMap = m
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════
  Component.onCompleted: {
    svc._syncFromStore()
    Store.watch("hotareas.enabled", function() {
      svc._syncFromStore()
    })
    Store.loadedLater(150, function() {
      svc._syncFromStore()
    })
  }
}
