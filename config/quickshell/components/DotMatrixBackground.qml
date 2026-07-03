import QtQuick
import "../styles"

Canvas {
  id: root

  onPaint: {
    var ctx = getContext("2d")
    ctx.fillStyle = Qt.rgba(Theme.borderVisible.r, Theme.borderVisible.g, Theme.borderVisible.b, 0.3)
    for (var x = 8; x < width; x += 16) {
      for (var y = 8; y < height; y += 16) {
        ctx.beginPath()
        ctx.arc(x, y, 0.5, 0, Math.PI * 2)
        ctx.fill()
      }
    }
  }
}
