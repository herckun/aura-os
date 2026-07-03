pragma Singleton
pragma ComponentBehavior: Bound
import QtQml
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: svc

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC STATE
  // ═══════════════════════════════════════════════════════════════

  readonly property int activeCount: {
    var keys = Object.keys(svc._watchers)
    var count = 0
    for (var i = 0; i < keys.length; i++) {
      if (svc._watchers[keys[i]]) count++
    }
    return count
  }

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════

  function register(id: string, command: var, onEvent: var, onDeath: var): var {
    if (svc._watchers[id]) svc.unregister(id)

    var watcher = ({
      id: id,
      command: command,
      onEvent: onEvent,
      onDeath: onDeath || null,
      proc: null,
      timer: null,
      backoff: svc._baseBackoff,
      startTime: 0,
      running: false,
      
      stop: function() { svc.unregister(id) },
      
      restart: function() {
        svc.unregister(id)
        svc._watchers[id] = watcher
        svc._startWatcher(watcher)
      }
    })

    svc._watchers[id] = watcher
    svc._startWatcher(watcher)

    return watcher
  }

  function unregister(id: string): void {
    var w = svc._watchers[id]
    if (!w) return

    if (w.proc) {
      w.proc.running = false
      w.proc.destroy()
      w.proc = null
    }

    if (w.timer) {
      w.timer.stop()
      w.timer.destroy()
      w.timer = null
    }

    w.running = false
    svc._watchers[id] = null
  }

  function clear(): void {
    var ids = Object.keys(svc._watchers)
    for (var i = 0; i < ids.length; i++) {
      svc.unregister(ids[i])
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  INTERNAL STATE
  // ═══════════════════════════════════════════════════════════════

  property var _watchers: ({})
  property var _processComponent: null

  readonly property int _baseBackoff: 1000
  readonly property int _maxBackoff: 30000
  readonly property int _stableTimeThreshold: 1000

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════

  function _createProcess(cmd: var): var {
    var safeCmd = Array.isArray(cmd) ? cmd : ["sh", "-c", cmd]
    var proc = svc._processComponent.createObject(svc, { command: safeCmd })

    var split = Qt.createQmlObject('import Quickshell.Io; SplitParser { splitMarker: "\\n" }', proc)
    proc.stdout = split

    return { proc: proc, split: split }
  }

  function _startWatcher(w: var): void {
    if (w.running) return

    w.running = true
    w.startTime = Date.now()

    var created = _createProcess(w.command)
    w.proc = created.proc

    created.split.onRead.connect(function(line) {
      if (w.running && w.onEvent) w.onEvent(line)
    })

    w.proc.onExited.connect(function(code) {
      w.running = false
      if (w.onDeath) w.onDeath(code)

      var elapsed = Date.now() - w.startTime
      if (elapsed > svc._stableTimeThreshold) {
        w.backoff = svc._baseBackoff
      } else {
        w.backoff = Math.min(w.backoff * 2, svc._maxBackoff)
      }

      var timer = Qt.createQmlObject("import QtQuick; Timer {}", svc)
      w.timer = timer
      timer.interval = w.backoff
      timer.repeat = false
      timer.triggered.connect(function() {
        w.timer = null
        timer.destroy()
        svc._startWatcher(w)
      })
      timer.start()
    })

    w.proc.running = true
  }

  // ═══════════════════════════════════════════════════════════════
  //  SYSTEM INTEGRATION
  // ═══════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════
  //  SIGNAL CONNECTIONS
  // ═══════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════
  //  TIMERS
  // ═══════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════

  Component.onCompleted: {
    svc._processComponent = Qt.createComponent("Quickshell.Io", "Process")
  }

  Component.onDestruction: {
    svc.clear()
    svc._processComponent = null
  }
}