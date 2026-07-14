pragma Singleton
import QtQml
import QtQuick
import Quickshell
import "../../core"
import "../hyprland"

Singleton {
  id: svc

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC STATE
  // ═══════════════════════════════════════════════════════════════

  readonly property bool autoSuspend: Store.power.autoSuspend
  readonly property int autoSuspendMinutes: Store.power.autoSuspendMinutes
  readonly property bool autoBatterySaver: Store.power.autoBatterySaver
  readonly property int autoBatterySaverThreshold: Store.power.autoBatterySaverThreshold

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════

  function init(): void {}

  function setAutoSuspend(on: bool): void {
    Store.power.autoSuspend = on
  }

  function setAutoSuspendMinutes(min: int): void {
    Store.power.autoSuspendMinutes = Math.max(1, Math.min(720, Math.round(min)))
  }

  function setAutoBatterySaver(on: bool): void {
    Store.power.autoBatterySaver = on
  }

  function setAutoBatterySaverThreshold(pct: int): void {
    Store.power.autoBatterySaverThreshold = Math.max(5, Math.min(50, Math.round(pct)))
  }

  function suspendNow(): void {
    ProcessPool.runDetached(["systemctl", "suspend"])
  }

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════

  property bool _ready: false

  readonly property string idleConfigState: JSON.stringify({
    on: autoSuspend,
    min: autoSuspendMinutes,
    lockMin: Store.lock.autoLockMinutes
  })

  function _applyIdleConfig(): void {
    var lines = [
      "# @managed: power-settings",
      "general {",
      "    lock_cmd = pidof hyprlock || hyprlock",
      "    before_sleep_cmd = loginctl lock-session",
      "    after_sleep_cmd = hyprctl dispatch dpms on",
      "}",
      "",
      "listener {",
      "    timeout = " + (Math.max(1, Store.lock.autoLockMinutes || 5) * 60),
      "    on-timeout = ~/.config/features/hypr/idle-lock.sh",
      "}"
    ]
    if (autoSuspend) {
      lines.push("")
      lines.push("listener {")
      lines.push("    timeout = " + (autoSuspendMinutes * 60))
      lines.push("    on-timeout = ~/.config/features/hypr/idle-suspend.sh")
      lines.push("}")
    }
    HyprlandService.writeConfig(AppInfo.hyprDir + "/hypridle.conf", lines.join("\n") + "\n", function (r) {
      if (r.exitCode === 0) {
        ProcessPool.runDetached(["sh", "-c", "pkill -x hypridle; sleep 0.3; setsid hypridle >/dev/null 2>&1 &"])
      }
    })
  }

  // ═══════════════════════════════════════════════════════════════
  //  SIGNAL CONNECTIONS
  // ═══════════════════════════════════════════════════════════════

  onIdleConfigStateChanged: {
    if (svc._ready)
      svc._applyTimer.restart()
  }

  // ═══════════════════════════════════════════════════════════════
  //  TIMERS
  // ═══════════════════════════════════════════════════════════════

  property Timer _applyTimer: Timer {
    interval: 400
    repeat: false
    onTriggered: svc._applyIdleConfig()
  }

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════

  Component.onCompleted: {
    svc._ready = true
  }
}
