pragma Singleton
import QtQml
import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"

Singleton {
  id: svc

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC STATE
  // ═══════════════════════════════════════════════════════════════
  property int pendingUpdates: 0
  property bool hasUpdates: false

  // ═══════════════════════════════════════════════════════════════
  //  INTERNAL STATE
  // ═══════════════════════════════════════════════════════════════
  readonly property int _baseCheckInterval: 3600000
  readonly property int _baseInitialCheckInterval: 60000

  readonly property int _checkInterval: PerformanceService.scaleInterval(_baseCheckInterval)
  readonly property int _initialCheckInterval: PerformanceService.scaleInterval(_baseInitialCheckInterval)

  // ═══════════════════════════════════════════════════════════════
  //  TIMERS
  // ═══════════════════════════════════════════════════════════════
  Timer {
    interval: svc._checkInterval
    running: true
    repeat: true
    onTriggered: svc.check()
  }

  Timer {
    interval: svc._initialCheckInterval
    running: true
    repeat: false
    onTriggered: svc.check()
  }

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════
  function check(): void {
    ProcessPool.runTracked("Check updates", "timeout 10 pacman -Qu 2>/dev/null | wc -l || echo 0", {
      id: "check-updates",
      shell: true,
      callback: function(r) {
        var count = parseInt(r.stdout.trim()) || 0
        svc.pendingUpdates = count
        svc.hasUpdates = count > 0
      }
    })
  }

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════
  Component.onCompleted: {
  }
}
