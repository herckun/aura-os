pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"

Singleton {
  id: svc

  // ═══════════════════════════════════════════════════════════════
  //  PANEL REGISTRY
  // ═══════════════════════════════════════════════════════════════

  property var _panels: ({})

  function registerPanel(name: string, toggleFn: var): void {
    var copy = Object.assign({}, _panels)
    copy[name] = toggleFn
    _panels = copy
  }

  function unregisterPanel(name: string): void {
    var copy = Object.assign({}, _panels)
    delete copy[name]
    _panels = copy
  }

  function togglePanel(name: string): void {
    var fn = _panels[name]
    if (fn) {
      fn()
    } else {
      Logger.warn("ipc", "No panel registered: " + name)
    }
  }

  property var _navHandlers: ({})

  function registerNav(name: string, fn: var): void {
    var copy = Object.assign({}, _navHandlers)
    copy[name] = fn
    _navHandlers = copy
  }

  function navigatePanel(name: string, pane: string): void {
    var fn = _navHandlers[name]
    if (fn) {
      fn(pane)
    } else {
      togglePanel(name)
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  SIGNALS (for non-panel IPC)
  // ═══════════════════════════════════════════════════════════════

  signal brightnessBrighter()
  signal brightnessDimmer()
  signal performanceSetProfile(int profile)
  signal screenshotRegion()
  signal screenshotScreen()
  signal screenshotOutput()
  signal screenshotWindow()

  // ═══════════════════════════════════════════════════════════════
  //  IPC HANDLERS
  // ═══════════════════════════════════════════════════════════════

  IpcHandler {
    target: "settings"
    function toggle(): void { svc.togglePanel("settings") }
    function navigate(pane: string): void { svc.navigatePanel("settings", pane) }
  }

  IpcHandler {
    target: "controlcenter"
    function toggle(): void { svc.togglePanel("controlcenter") }
  }

  IpcHandler {
    target: "notifications"
    function toggle(): void { svc.togglePanel("notifications") }
  }

  IpcHandler {
    target: "overview"
    function toggle(): void { svc.togglePanel("overview") }
  }

  IpcHandler {
    target: "cheatsheet"
    function toggle(): void { svc.togglePanel("cheatsheet") }
  }

  IpcHandler {
    target: "devoverlay"
    function toggle(): void { svc.togglePanel("devoverlay") }
  }

  IpcHandler {
    target: "appswitch"
    function toggle(): void { svc.togglePanel("appswitch") }
  }

  IpcHandler {
    target: "brightness"
    function brighter(): void { svc.brightnessBrighter() }
    function dimmer(): void { svc.brightnessDimmer() }
  }

  IpcHandler {
    target: "performance"
    function setProfile(p: int): void { svc.performanceSetProfile(p) }
  }

  IpcHandler {
    target: "screenshot"
    function region(): void { svc.screenshotRegion() }
    function screen(): void { svc.screenshotScreen() }
    function output(): void { svc.screenshotOutput() }
    function window(): void { svc.screenshotWindow() }
  }

  IpcHandler {
    target: "mode"
    function set(m: int): void { ModeService.setMode(m) }
    function cycle(): void { ModeService.cycleMode() }
  }
}
