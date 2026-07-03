import QtQuick
import Qt5Compat.GraphicalEffects
import "../styles"

Item {
  id: root

  property string source: ""
  property int size: 16
  property color color: Theme.textPrimary
  property bool byPassColorOverlay: false

  implicitWidth: size
  implicitHeight: size

  Image {
    id: image
    anchors.fill: parent
    source: root.source
    fillMode: Image.PreserveAspectFit
    sourceSize.width: Math.max(root.size * 2, 32)
    sourceSize.height: Math.max(root.size * 2, 32)
    smooth: true
    asynchronous: true
    visible: root.byPassColorOverlay
  }

  ColorOverlay {
    anchors.fill: image
    source: image
    color: root.color
    smooth: true
    visible: !root.byPassColorOverlay
  }
}
