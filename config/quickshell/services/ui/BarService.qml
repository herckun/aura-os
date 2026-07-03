pragma Singleton
import QtQuick
import Quickshell
import "../../styles"

Singleton {
  id: svc

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC STATE
  // ═══════════════════════════════════════════════════════════════
  property real barX: 0
  property real barY: 0
  property real barWidth: 0
  property real barHeight: 0
  property bool floating: false
  property int gap: Theme.spaceXs
  readonly property int sideOffset: floating ? Theme.spaceMd : 0

  readonly property int barBottom: Math.round(barY + barHeight)

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════
  function updateBar(x: real, y: real, w: real, h: real, isFloating: bool, g: int): void {
    barX = x
    barY = y
    barWidth = w
    barHeight = h
    floating = isFloating
    gap = g
  }
}
