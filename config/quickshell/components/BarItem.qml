import QtQuick
import "../styles"

Item {
  id: root

  default property alias content: contentArea.data
  property bool pillMode: false
  property bool centered: true

  readonly property real _cw: {
    if (contentArea.children.length === 0) return 0
    var c = contentArea.children[0]
    return c.implicitWidth > 0 ? c.implicitWidth : c.width
  }

  readonly property real _ch: {
    if (contentArea.children.length === 0) return 0
    var c = contentArea.children[0]
    return c.implicitHeight > 0 ? c.implicitHeight : c.height
  }

  height: 24
  width: _cw + (pillMode ? Theme.spaceSm * 2 + 16 : 0)
  clip: true

  Rectangle {
    visible: root.pillMode
    anchors.fill: parent
    radius: Theme.radiusSmall
    antialiasing: true
    color: Theme.backgroundSecondary
  }

  Item {
    id: contentArea
    anchors.verticalCenter: parent.verticalCenter
    x: root.centered ? (parent.width - width) / 2 : (root.pillMode ? Theme.spaceSm : 0)
    width: _cw > 0 ? _cw : 0
    height: _ch > 0 ? _ch : 0
  }
}
