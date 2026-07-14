import QtQuick
import "../../../../styles"

Rectangle {
  id: root

  property var bands: [0, 0, 0, 0, 0, 0, 0]
  property color barColor: Theme.accent
  property int cols: 21
  property int rows: 8
  property real dotRatio: 0.75

  readonly property color _dimColor: Qt.rgba(
    Theme.contrastTextColor(barColor).r,
    Theme.contrastTextColor(barColor).g,
    Theme.contrastTextColor(barColor).b,
    0.08
  )
  readonly property color _glowColor: Qt.rgba(
    Theme.contrastTextColor(barColor).r,
    Theme.contrastTextColor(barColor).g,
    Theme.contrastTextColor(barColor).b,
    0.25
  )

  width: parent ? parent.width : 200
  height: 60
  radius: Theme.radiusMedium
  antialiasing: true
  color: "transparent"
  clip: true

  property var _targetBands: []
  property var _smoothBands: []
  property bool _idle: true

  Component.onCompleted: {
    var init = []
    for (var i = 0; i < cols; i++) init.push(0)
    _targetBands = init.slice()
    _smoothBands = init
  }

  onBandsChanged: {
    var remapped = []
    var step = bands.length / cols
    for (var i = 0; i < cols; i++) {
      var pos = i * step
      var idx = Math.floor(pos)
      var frac = pos - idx
      var a = bands[Math.min(idx, bands.length - 1)] || 0
      var b = bands[Math.min(idx + 1, bands.length - 1)] || 0
      remapped.push(a + (b - a) * frac)
    }
    _targetBands = remapped
    _idle = false
    _idleTimer.restart()
  }

  Timer {
    id: _idleTimer
    interval: 1000
    repeat: false
    onTriggered: {
      var allZero = true
      for (var i = 0; i < root.cols; i++) {
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
      for (var i = 0; i < root.cols; i++) {
        var target = root._targetBands[i] || 0
        var prev = root._smoothBands[i] || 0
        var diff = target - prev
        var srcIdx = Math.min(Math.floor(i / 3), 6)
        var iNorm = srcIdx / 6
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

      var c = root.cols
      var r = root.rows
      var w = root.width
      var h = root.height
      var dotW = w / c
      var dotH = h / r
      var dotSize = Math.min(dotW, dotH) * root.dotRatio
      var gapX = (w - c * dotSize) / (c + 1)
      var gapY = (h - r * dotSize) / (r + 1)

      var maxRow = []
      for (var i = 0; i < c; i++) {
        var norm = i / (c - 1)
        var dist = Math.abs(norm - 0.5) * 2
        maxRow.push(Math.max(2, Math.round((1 - Math.pow(dist, 3)) * r)))
      }

      for (var col = 0; col < c; col++) {
        var val = root._smoothBands[col] || 0
        var mRows = maxRow[col]
        var offsetY = (r - mRows) * (dotSize + gapY) / 2
        var level = val * mRows
        var half = level / 2
        var center = mRows / 2
        var topRow = Math.floor(center - half)
        var botRow = Math.ceil(center + half) - 1
        if (level < 0.01) { topRow = mRows; botRow = -1 }
        if (topRow < 0) topRow = 0
        if (botRow >= mRows) botRow = mRows - 1

        for (var row = 0; row < mRows; row++) {
          var inBar = row >= topRow && row <= botRow
          var onEdge = inBar && (row === topRow || row === botRow) && level > 0.5

          var x = gapX + col * (dotSize + gapX)
          var y = offsetY + gapY + row * (dotSize + gapY)

          ctx.beginPath()
          if (inBar) {
            var edgeFade = onEdge ? 0.6 : 1.0
            ctx.fillStyle = Qt.rgba(
              root.barColor.r, root.barColor.g, root.barColor.b,
              edgeFade
            )
          } else if (onEdge && level > 0.3) {
            ctx.fillStyle = root._glowColor
          } else {
            ctx.fillStyle = root._dimColor
          }
          ctx.arc(x + dotSize / 2, y + dotSize / 2, dotSize / 2, 0, Math.PI * 2)
          ctx.fill()
        }
      }
    }
  }
}
