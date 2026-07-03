pragma Singleton
pragma ComponentBehavior: Bound
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

  property date currentDate: new Date()
  property string dateStr: ""
  property string timeStr: ""
  property string fullStr: ""

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════

  function format(pattern: string): string {
    return Qt.formatDateTime(svc.currentDate, pattern)
  }

  // ═══════════════════════════════════════════════════════════════
  //  INTERNAL STATE
  // ═══════════════════════════════════════════════════════════════

  property string _lastDate: ""
  readonly property int _tickInterval: 1000

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════

  function _update(): void {
    var now = new Date()
    svc.currentDate = now

    var newDateStr = Qt.formatDateTime(now, "yyyy-MM-dd")
    svc.dateStr = newDateStr
    svc.timeStr = Qt.formatDateTime(now, "HH:mm")
    svc.fullStr = Qt.formatDateTime(now, "ddd dd MMM yyyy HH:mm:ss")

    if (newDateStr !== svc._lastDate) {
      svc._lastDate = newDateStr
    }
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

  Timer {
    interval: svc._tickInterval
    running: true
    repeat: true
    onTriggered: svc._update()
  }

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════

}