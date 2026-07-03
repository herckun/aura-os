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

  readonly property int _throttleMs: 120
  readonly property string _sfxDir: {
    var p = Qt.resolvedUrl("../../sfx/").toString()
    return p.indexOf("file://") === 0 ? p.substring(7) : p
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
    var last = svc._lastPlayed[name] || 0
    if (now - last < svc._throttleMs) return
    svc._lastPlayed[name] = now
    ProcessPool.runDetached(["pw-play", svc._sfxDir + name + ".oga"])
  }

  // ═══════════════════════════════════════════════════════════════
  //  SIGNAL CONNECTIONS
  // ═══════════════════════════════════════════════════════════════
  Connections {
    target: AudioService
    function onVolumeChanged() { svc.play("volume") }
  }

  Connections {
    target: TimerService
    function onFinished() { svc.play("timer-done") }
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
    })
  }
}
