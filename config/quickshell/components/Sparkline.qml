import QtQuick
import "../styles"

Canvas {
  id: root

  // ── Properties ─────────────────────────────────────────────
  property var values: []
  property real maxValue: 100
  property color lineColor: Theme.accent
  property real lineWidth: 1.5

  onValuesChanged: requestPaint()
  onLineColorChanged: requestPaint()

  onPaint: {
    var ctx = getContext("2d")
    ctx.clearRect(0, 0, width, height)
    var v = root.values || []
    if (v.length < 2) return

    ctx.strokeStyle = root.lineColor
    ctx.lineWidth = root.lineWidth
    ctx.beginPath()
    var stepX = width / (v.length - 1)
    for (var i = 0; i < v.length; i++) {
      var n = Math.max(0, Math.min(root.maxValue, v[i]))
      var x = i * stepX
      var y = height - (n / root.maxValue * height)
      if (i === 0) ctx.moveTo(x, y)
      else ctx.lineTo(x, y)
    }
    ctx.stroke()
  }
}
