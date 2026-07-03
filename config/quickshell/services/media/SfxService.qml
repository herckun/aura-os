pragma Singleton
import QtQuick
import Quickshell
import "../../core"
import "../"

Singleton {
  id: svc

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC STATE
  // ═══════════════════════════════════════════════════════════════
  property bool enabled: true

  // ═══════════════════════════════════════════════════════════════
  //  INTERNAL STATE
  // ═══════════════════════════════════════════════════════════════
  property bool _ready: false
  property var _lastPlayed: ({})
  property real _lastSpecificAt: 0

  readonly property int _throttleMs: 120
  readonly property int _suppressMs: 1200
  readonly property string _sfxDir: {
    var p = Qt.resolvedUrl("../../sfx/").toString()
    return p.indexOf("file://") === 0 ? p.substring(7) : p
  }

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════
  function _group(name: string): string {
    return name === "volume" || name === "mute" ? "audio" : name
  }

  function _spawn(name: string): void {
    ProcessPool.runDetached(["pw-play", svc._sfxDir + name + ".oga"])
  }

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════
  function init(): void {
  }

  function setEnabled(v: bool): void {
    svc.enabled = v
    Store.set("sfx.enabled", v)
  }

  function play(name: string): void {
    if (!svc.enabled || !svc._ready) return
    var now = Date.now()
    var group = svc._group(name)
    var last = svc._lastPlayed[group] || 0
    if (now - last < svc._throttleMs) return
    svc._lastPlayed[group] = now
    if (name.indexOf("notification") !== 0) svc._lastSpecificAt = now
    svc._spawn(name)
  }

  // ═══════════════════════════════════════════════════════════════
  //  SIGNAL CONNECTIONS
  // ═══════════════════════════════════════════════════════════════
  Connections {
    target: AudioService
    function onVolumeChanged() { svc.play("volume") }
    function onMutedChanged() { svc.play("mute") }
  }

  Connections {
    target: TimerService
    function onFinished() { svc.play("timer-done") }
  }

  Connections {
    target: NetworkService
    function onNetworkConnected(ssid) { svc.play("device-connect") }
    function onNetworkFailed(msg) { svc.play("network-error") }
  }

  Connections {
    target: BluetoothService
    function onDeviceConnected(mac) { svc.play("device-connect") }
    function onDeviceDisconnected(mac) { svc.play("device-disconnect") }
  }

  Connections {
    target: ScreenshotService
    function onCaptured() { svc.play("screenshot") }
  }

  Connections {
    target: BatteryService
    function onChargingChanged() { if (BatteryService.charging) svc.play("power-plug") }
    function onDischargingChanged() { if (BatteryService.discharging) svc.play("power-unplug") }
    function onLowBatteryChanged() { if (BatteryService.lowBattery) svc.play("battery-low") }
  }

  Connections {
    target: NotificationService
    function onPosted(urgency) {
      if (Date.now() - svc._lastSpecificAt < svc._suppressMs) return
      svc.play(urgency >= 2 ? "notification-urgent" : "notification")
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  TIMERS
  // ═══════════════════════════════════════════════════════════════
  Timer {
    id: readyTimer
    interval: 2500
    running: true
    repeat: false
    onTriggered: svc._ready = true
  }

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════
  Component.onCompleted: {
    svc.enabled = Store.getBool("sfx.enabled", true)
    Store.loadedLater(100, function() {
      svc.enabled = Store.getBool("sfx.enabled", true)
      if (svc.enabled) svc._spawn("startup")
    })
  }
}
