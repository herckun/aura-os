pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"
import "../../services"

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
    function brighter(): void { BrightnessService.brighter() }
    function dimmer(): void { BrightnessService.dimmer() }
  }

  IpcHandler {
    target: "volume"
    function up(): void { AudioService.volumeUp() }
    function down(): void { AudioService.volumeDown() }
    function toggleMute(): void { AudioService.toggleMute() }
    function toggleMicMute(): void { AudioService.toggleMicMute() }
    function setVolume(v: int): void { AudioService.setVolume(v / 100) }
  }

  IpcHandler {
    target: "performance"
    function setProfile(p: int): void { PerformanceService.switchProfile(p) }
  }

  IpcHandler {
    target: "apps"
    function terminal(): void { DefaultAppsService.launch("terminal") }
    function browser(): void { DefaultAppsService.launch("browser") }
    function files(): void { DefaultAppsService.launch("fileManager") }
    function editor(): void { DefaultAppsService.launch("editor") }
  }

  IpcHandler {
    target: "screenshot"
    function region(): void { ScreenshotService.captureRegion() }
    function screen(): void { ScreenshotService.captureScreen() }
    function output(): void { ScreenshotService.captureOutput() }
    function window(): void { ScreenshotService.captureWindow() }
  }

  IpcHandler {
    target: "wallpaper"
    function cycle(): void { WallpaperService.cycleWallpaper() }
  }

  IpcHandler {
    target: "mode"
    function set(m: int): void { ModeService.setMode(m) }
    function cycle(): void { ModeService.cycleMode() }
  }
}
