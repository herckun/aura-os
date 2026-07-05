pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"
import "../"

Singleton {
  id: svc

  property bool enabled: true

  property bool _ready: false
  property var _lastPlayed: ({})
  property real _lastSpecificAt: 0

  readonly property int _throttleMs: 80
  readonly property int _suppressMs: 1200
  readonly property string _sfxDir: {
    var p = Qt.resolvedUrl("../../sfx/").toString()
    return p.indexOf("file://") === 0 ? p.substring(7) : p
  }

  // ═══════════════════════════════════════════════════════════════
  //  SOUND SLOT
  // ═══════════════════════════════════════════════════════════════
  Component {
    id: slotComponent

    Scope {
      id: slot

      Process {
        id: proc

        onExited: function (code) {
          if (slot._pending) {
            slot._pending = false
            retryTimer.file = slot._pendingFile
            retryTimer.start()
          }
        }
      }

      Timer {
        id: retryTimer
        interval: 10
        repeat: false
        property string file: ""
        onTriggered: slot._startPlayback(file)
      }

      property string _pendingFile: ""
      property bool _pending: false

      function _startPlayback(file: string): void {
        proc.command = [
          "canberra-gtk-play",
          "-f", file,
          "-d", "quickshell"
        ]
        proc.running = true
      }

      function play(file: string): void {
        retryTimer.stop()
        _pending = false

        if (proc.running) {
          proc.running = false
          _pendingFile = file
          _pending = true
        } else {
          _startPlayback(file)
        }
      }

      function stop(): void {
        retryTimer.stop()
        _pending = false
        if (proc.running) proc.running = false
      }
    }
  }

  property var _slots: ({})

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════
  function _group(name: string): string {
    return (name === "volume" || name === "mute") ? "audio" : name
  }

  function _getSlot(group: string): var {
    if (!_slots[group]) {
      _slots[group] = slotComponent.createObject(svc)
    }
    return _slots[group]
  }

  function _spawn(name: string): void {
    var group = svc._group(name)
    var file = svc._sfxDir + name + ".oga"
    var slot = _getSlot(group)
    if (slot) slot.play(file)
  }

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════
  function init(): void {}

  function setEnabled(v: bool): void {
    svc.enabled = v
    Store.sfx.enabled = v
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
  //  TIMERS & LIFECYCLE
  // ═══════════════════════════════════════════════════════════════
  Timer {
    interval: 2500
    running: true
    repeat: false
    onTriggered: svc._ready = true
  }

  Component.onCompleted: {
    svc.enabled = Store.sfx.enabled
    if (svc.enabled) svc._spawn("startup")
  }

  Component.onDestruction: {
    for (var g in _slots) {
      if (_slots[g]) { _slots[g].stop(); _slots[g].destroy() }
    }
    _slots = {}
  }
}
