import QtQuick
import "../../../../styles"

Rectangle {
  id: root

  property var bands: [0, 0, 0, 0, 0, 0, 0]
  property color bgColor: Theme.accent
  property real dotSize: 2
  property real dotGap: 2.5
  property real pad: 5

  readonly property int _cols: 7
  readonly property int _rows: 5
  readonly property color _litColor: Theme.contrastTextColor(bgColor)
  readonly property color _dimColor: Qt.rgba(
    Theme.contrastTextColor(bgColor).r,
    Theme.contrastTextColor(bgColor).g,
    Theme.contrastTextColor(bgColor).b,
    0.12
  )

  width: _cols * (dotSize + dotGap) - dotGap + pad * 2
  height: _rows * (dotSize + dotGap) - dotGap + pad * 2
  radius: Theme.radiusMedium
  color: bgColor

  property var _targetBands: [0,0,0,0,0,0,0]
  property var _smoothBands: [0,0,0,0,0,0,0]
  property bool _idle: true

  onBandsChanged: { _targetBands = bands; _idle = false; _idleTimer.restart() }

  Timer {
    id: _idleTimer
    interval: 1000
    repeat: false
    onTriggered: {
      var allZero = true
      for (var i = 0; i < root._cols; i++) {
        if (Math.abs(root._targetBands[i]) > 0.001) { allZero = false; break }
      }
      if (allZero) root._idle = true
    }
  }

  FrameAnimation {
    id: animTimer
    running: !root._idle
    onTriggered: {
      var changed = false
      var newBands = []
      var dt = Math.min(frameTime, 0.05)
      var scale = dt * 60
      for (var i = 0; i < root._cols; i++) {
        var target = root._targetBands[i] || 0
        var prev = root._smoothBands[i] || 0
        var diff = target - prev
        var iNorm = i / (root._cols - 1)
        var atk = 0.08 + iNorm * 0.77
        var dec = 0.03 + iNorm * 0.72
        var speed = target > prev ? atk : dec
        var next = prev + diff * speed * scale
        if (Math.abs(diff) < 0.002) next = target
        newBands.push(next)
        if (Math.abs(next - prev) > 0.0005) changed = true
      }
      root._smoothBands = newBands
      if (changed) canvas.requestPaint()
    }
  }

  Canvas {
    id: canvas
    anchors.fill: parent
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onVisibleChanged: if (visible) requestPaint()

    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      var cols = root._cols
      var rows = root._rows
      var ds = root.dotSize
      var dg = root.dotGap
      var ox = root.pad
      var oy = root.pad

      var envelope = [0.6, 0.85, 1.0, 0.9, 0.95, 0.8, 0.6]

      for (var col = 0; col < cols; col++) {
        var raw = (root._smoothBands[col] || 0) * (envelope[col] || 1)
        var shaped = Math.pow(raw, 0.8)
        var level = Math.min(Math.round(shaped * rows), rows)
        var half = level / 2
        var center = rows / 2
        var topRow = Math.floor(center - half)
        var botRow = Math.ceil(center + half) - 1
        if (level === 0) { topRow = rows; botRow = -1 }
        if (topRow < 0) topRow = 0
        if (botRow >= rows) botRow = rows - 1

        for (var row = 0; row < rows; row++) {
          var x = ox + col * (ds + dg)
          var y = oy + row * (ds + dg)
          var lit = row >= topRow && row <= botRow
          ctx.beginPath()
          ctx.fillStyle = lit ? root._litColor : root._dimColor
          ctx.arc(x + ds / 2, y + ds / 2, ds / 2, 0, Math.PI * 2)
          ctx.fill()
        }
      }
    }
  }

  scale: 0.8
  opacity: 0

  Behavior on scale {
    enabled: Theme.animationsEnabled
    NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic }
  }
  Behavior on opacity {
    enabled: Theme.animationsEnabled
    NumberAnimation { duration: Theme.animationSlow; easing.type: Easing.OutQuad }
  }
}
