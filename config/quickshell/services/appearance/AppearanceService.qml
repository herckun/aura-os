pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"
import "../../styles"
import "../hyprland"
import "../ui"
import "../system"

Singleton {
  id: svc

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC STATE
  // ═══════════════════════════════════════════════════════════════

  readonly property bool animationsEnabled: Store.appearance.animations && !PerformanceService.batterySaver
  readonly property bool blurEnabled: Store.appearance.blur && !PerformanceService.batterySaver
  readonly property bool transparencyEnabled: Store.appearance.transparency && !PerformanceService.batterySaver
  readonly property bool barFloating: Store.appearance.barFloating

  readonly property bool locked: PerformanceService.batterySaver

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════

  function init(): void {}

  function setAnimations(on: bool): void {
    if (locked) return
    Store.appearance.animations = on
  }

  function setBlur(on: bool): void {
    if (locked) return
    Store.appearance.blur = on
  }

  function setTransparency(on: bool): void {
    if (locked) return
    Store.appearance.transparency = on
  }

  function setBarFloating(on: bool): void {
    if (locked) return
    Store.appearance.barFloating = on
  }

  function applyKittyConfig(): void {
    var opacity = transparencyEnabled ? "0.95" : "1.0"
    var blink = animationsEnabled ? "0.5" : "0"
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
      { pattern: /(leaf\s*=\s*"[^"]*",\s*enabled\s*=\s*)(?:true|false)/g, replacement: "$1" + animEnabled }
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

  readonly property string themeEngineState: JSON.stringify({
    accent: Store.theme.accent.replace("#", ""),
    preset: Store.theme.preset,
    shellMode: ModeService.mode,
    transparency: transparencyEnabled,
    animations: animationsEnabled,
    monochrome: Store.theme.monochrome,
    blur: blurEnabled
  })

  readonly property string hyprConfigState: JSON.stringify({
    animations: animationsEnabled,
    blur: blurEnabled,
    transparency: transparencyEnabled,
    outerGap: Theme.hyprOuterGap,
    innerGap: Theme.hyprInnerGap
  })

  function _flushThemeUpdate(): void {
    ProcessPool.runDetachedBusy([AppInfo.configHome + "/features/theme/engine.sh", themeEngineState], "theme-engine", 1500)
  }

  // ═══════════════════════════════════════════════════════════════
  //  SIGNAL CONNECTIONS
  // ═══════════════════════════════════════════════════════════════

  onThemeEngineStateChanged: _themeUpdateTimer.restart()
  onHyprConfigStateChanged: _hyprUpdateTimer.restart()

  onAnimationsEnabledChanged: {
    var blink = animationsEnabled ? "0.5" : "0"
    ProcessPool.runQueued("Kitty cursor", ["kitty", "@", "set-cursor-blink-interval", blink], { silent: true })
    applyKittyConfig()
  }

  onTransparencyEnabledChanged: {
    var opacity = transparencyEnabled ? "0.95" : "1.0"
    ProcessPool.runQueued("Kitty opacity", ["kitty", "@", "set-background-opacity", opacity], { silent: true })
    applyKittyConfig()
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
    _themeUpdateTimer.restart()
    _hyprUpdateTimer.restart()
  }
}
