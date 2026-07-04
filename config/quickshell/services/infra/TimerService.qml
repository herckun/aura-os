pragma Singleton
pragma ComponentBehavior: Bound
import QtQml
import QtQuick
import Quickshell
import "../../core"
import "../"

Singleton {
  id: svc

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC STATE
  // ═══════════════════════════════════════════════════════════════

  property int remaining: 0
  property int total: 0
  property bool running: false
  property bool paused: false
  property string label: "TIMER"

  readonly property string formattedTime: formatTime(remaining)

  signal finished()

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════

  function startTimer(seconds: int): void {
    _stopTimers()
    svc.remaining = seconds
    svc.total = seconds
    svc._mode = _modeTimer
    svc.running = true
    svc.paused = false
    svc.label = "TIMER"
    timer.start()
  }

  function startStopwatch(): void {
    _stopTimers()
    svc.remaining = 0
    svc.total = 0
    svc._mode = _modeStopwatch
    svc.running = true
    svc.paused = false
    svc.label = "STOPWATCH"
    stopwatch.start()
  }

  function pause(): void {
    svc.paused = !svc.paused
  }

  function stop(): void {
    _stopTimers()
    _resetState()
  }

  function formatTime(secs: int): string {
    var m = Math.floor(secs / 60)
    var s = secs % 60
    return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
  }

  function init(): void {}

  // ═══════════════════════════════════════════════════════════════
  //  INTERNAL STATE
  // ═══════════════════════════════════════════════════════════════

  property int _mode: 0

  readonly property int _modeTimer: 0
  readonly property int _modeStopwatch: 1
  readonly property int _tickInterval: 1000

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════

  function _resetState(): void {
    svc.running = false
    svc.paused = false
    svc.remaining = 0
    svc.total = 0
  }

  function _stopTimers(): void {
    timer.stop()
    stopwatch.stop()
  }

  function _emitUpdated(): void {
  }

  // ═══════════════════════════════════════════════════════════════
  //  SYSTEM INTEGRATION
  // ═══════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════
  //  SIGNAL CONNECTIONS
  // ═══════════════════════════════════════════════════════════════

  onRemainingChanged: _emitUpdated()
  onRunningChanged: _emitUpdated()
  onPausedChanged: _emitUpdated()
  onLabelChanged: _emitUpdated()
  onTotalChanged: _emitUpdated()

  // ═══════════════════════════════════════════════════════════════
  //  TIMERS
  // ═══════════════════════════════════════════════════════════════

  Timer {
    id: timer
    interval: svc._tickInterval
    repeat: true

    onTriggered: {
      if (svc.paused) return

      if (svc.remaining > 0) svc.remaining--

      if (svc.remaining <= 0) {
        timer.stop()
        svc.running = false
        svc.finished()
        NotificationService.systemNotify("TIMER", "Time's up", 1)
      }
    }
  }

  Timer {
    id: stopwatch
    interval: svc._tickInterval
    repeat: true

    onTriggered: {
      if (!svc.paused) svc.remaining++
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════

  Component.onCompleted: {
    _emitUpdated()
  }

  Component.onDestruction: {
    _stopTimers()
  }
}