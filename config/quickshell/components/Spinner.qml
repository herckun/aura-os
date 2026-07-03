import QtQuick
import "../styles"

Canvas {
  id: root

  property int spinnerSize: 32
  property color spinnerColor: Theme.accent

  width: spinnerSize
  height: spinnerSize

  property real _angle: 0

  FrameAnimation {
    running: root.visible
    onTriggered: {
      _angle = (_angle + 3 * Math.min(frameTime * 60, 2)) % 360
      root.requestPaint()
    }
  }

  onPaint: {
    var ctx = getContext("2d")
    ctx.reset()
    ctx.clearRect(0, 0, width, height)

    var cx = width / 2
    var cy = height / 2
    var r = Math.min(cx, cy) * 0.7
    var dotR = width * 0.055
    var count = 8

    for (var i = 0; i < count; i++) {
      var a = (_angle + i * (360 / count)) * Math.PI / 180
      var dx = cx + r * Math.cos(a)
      var dy = cy + r * Math.sin(a)
      var alpha = 0.15 + 0.85 * (i / count)

      ctx.beginPath()
      ctx.arc(dx, dy, dotR, 0, Math.PI * 2)
      ctx.fillStyle = Qt.rgba(root.spinnerColor.r, root.spinnerColor.g, root.spinnerColor.b, alpha)
      ctx.fill()
    }
  }
}
