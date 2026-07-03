pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"
import "../../styles"
import "../hyprland"

Singleton {
  id: svc

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC STATE
  // ═══════════════════════════════════════════════════════════════

  property bool animationsEnabled: true
  property bool blurEnabled: true
  property bool transparencyEnabled: true
  property bool barFloating: false

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════

  function snapshot(): var {
    return {
      animationsEnabled: animationsEnabled,
      blurEnabled: blurEnabled,
      transparencyEnabled: transparencyEnabled,
      barFloating: barFloating
    }
  }

  function setAnimations(on: bool): void {
    Store.set("performance.animations", on)
    var blink = on ? "0.5" : "0"
    ProcessPool.runQueued("Kitty cursor", ["kitty", "@", "set-cursor-blink-interval", blink], {
      silent: true
    })
    applyKittyConfig(on, blurEnabled, transparencyEnabled)
  }

  function setBlur(on: bool): void {
    Store.set("appearance.blur", on)
  }

  function setTransparency(on: bool): void {
    Store.set("appearance.transparency", on)
    var opacity = on ? "0.95" : "1.0"
    ProcessPool.runQueued("Kitty opacity", ["kitty", "@", "set-background-opacity", opacity], {
      silent: true
    })
    applyKittyConfig(animationsEnabled, blurEnabled, on)
  }

  function applyKittyConfig(anim: bool, blr: bool, trn: bool): void {
    var opacity = trn ? "0.95" : "1.0"
    var blink = anim ? "0.5" : "0"
    var conf = AppInfo.configHome + "/kitty/kitty.conf"
    ProcessPool.runQueued("Kitty config", [
      "sh", "-c",
      "sed -i \"s/^background_opacity .*/background_opacity " + opacity + "/\" \"$1\"; " +
      "sed -i \"s/^cursor_blink_interval .*/cursor_blink_interval " + blink + "/\" \"$1\"; " +
      "pkill -SIGUSR1 kitty 2>/dev/null || true",
      "--", conf
    ], {
      silent: true
    })
  }

  function applyHyprlandSettings(): void {
    var hyprDir = AppInfo.hyprDir
    var rounding = Theme.hyprOuterGap
    var opacity = transparencyEnabled ? "0.95" : "1.0"
    var animEnabled = animationsEnabled ? "true" : "false"
    var blurEnabledStr = blurEnabled ? "true" : "false"

    var gapsStr = Theme.hyprInnerGap || "4,8"
    var gapsParts = gapsStr.split(",")
    var gapsIn = gapsParts[0] || "4"
    var gapsOut = gapsParts.length > 1 ? gapsParts[1] : gapsParts[0] || "8"

    HyprlandService.modifyConfig(hyprDir + "/animations.lua", [
      { pattern: /(leaf[^=]*enabled\s*=\s*)(?:true|false)/g, replacement: "$1" + animEnabled }
    ])

    HyprlandService.modifyConfig(hyprDir + "/decorations.lua", [
      { pattern: /(blur[\s\S]*?enabled\s*=\s*)(?:true|false)/, replacement: "$1" + blurEnabledStr },
      { pattern: /active_opacity\s*=\s*[\d.]+/, replacement: "active_opacity = " + opacity },
      { pattern: /inactive_opacity\s*=\s*[\d.]+/, replacement: "inactive_opacity = " + opacity },
      { pattern: /fullscreen_opacity\s*=\s*[\d.]+/, replacement: "fullscreen_opacity = " + opacity },
      { pattern: /rounding\s*=\s*\d+/, replacement: "rounding = " + rounding }
    ])

    HyprlandService.modifyConfig(hyprDir + "/hyprland.lua", [
      { pattern: /gaps_in\s*=\s*\d+/, replacement: "gaps_in = " + gapsIn },
      { pattern: /gaps_out\s*=\s*\d+/, replacement: "gaps_out = " + gapsOut }
    ])
  }

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════

  function _syncFromStore(): void {
    animationsEnabled = Store.getBool("performance.animations", true)
    blurEnabled = Store.getBool("appearance.blur", true)
    transparencyEnabled = Store.getBool("appearance.transparency", true)
    barFloating = Store.getBool("appearance.barFloating", false)
  }

  function _watchStore(key: string, handler: var): void {
    Store.watch(key, function(_, value) {
      handler(value)
    })
  }

  function _scheduleHyprUpdate(): void {
    _hyprUpdateTimer.restart()
  }

  function _themeArgs(): string {
    var raw = Store.getString("theme.accent", "#D71921")
    var accent = raw.replace("#", "")
    var transparency = Store.getBool("appearance.transparency", true)
    var animations = Store.getBool("performance.animations", true)
    var monochrome = Store.getBool("theme.monochrome", false)
    var blur = Store.getBool("appearance.blur", true)
    var mode = Store.getInt("shell.mode", 0)
    return JSON.stringify({
      accent: accent,
      shellMode: mode,
      transparency: transparency,
      animations: animations,
      monochrome: monochrome,
      blur: blur
    })
  }

  function _flushThemeUpdate(): void {
    ProcessPool.runDetachedBusy([AppInfo.configHome + "/features/theme/engine.sh", _themeArgs()], "theme-engine", 1500)
  }

  function _scheduleThemeUpdate(): void {
    _themeUpdateTimer.restart()
  }

  // ═══════════════════════════════════════════════════════════════
  //  TIMERS
  // ═══════════════════════════════════════════════════════════════

  property Timer _hyprUpdateTimer: Timer {
    interval: 100
    repeat: false
    onTriggered: svc.applyHyprlandSettings()
  }

  property Timer _themeUpdateTimer: Timer {
    interval: 100
    repeat: false
    onTriggered: svc._flushThemeUpdate()
  }

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════

  Component.onCompleted: {
    svc._syncFromStore()

    _watchStore("theme.accent", function(_) { svc._scheduleThemeUpdate() })
    _watchStore("theme.monochrome", function(_) { svc._scheduleThemeUpdate() })
    _watchStore("appearance.blur", function(value) {
      svc.blurEnabled = value
      svc._scheduleThemeUpdate()
      svc._scheduleHyprUpdate()
    })
    _watchStore("appearance.transparency", function(value) {
      svc.transparencyEnabled = value
      var opacity = value ? "0.95" : "1.0"
      ProcessPool.runQueued("Kitty opacity", ["kitty", "@", "set-background-opacity", opacity], { silent: true })
      svc.applyKittyConfig(svc.animationsEnabled, svc.blurEnabled, value)
      svc._scheduleThemeUpdate()
      svc._scheduleHyprUpdate()
    })
    _watchStore("performance.animations", function(value) {
      svc.animationsEnabled = value
      var blink = value ? "0.5" : "0"
      ProcessPool.runQueued("Kitty cursor", ["kitty", "@", "set-cursor-blink-interval", blink], { silent: true })
      svc.applyKittyConfig(value, svc.blurEnabled, svc.transparencyEnabled)
      svc._scheduleThemeUpdate()
      svc._scheduleHyprUpdate()
    })
    _watchStore("appearance.barFloating", function(value) {
      svc.barFloating = value
      svc._scheduleHyprUpdate()
    })
    _watchStore("shell.mode", function(_) {
      svc._scheduleHyprUpdate()
      svc._scheduleThemeUpdate()
    })

    Store.loaded.connect(function() {
      svc._syncFromStore()
      svc._scheduleThemeUpdate()
      svc._scheduleHyprUpdate()
    })
  }
}
