import QtQuick
import "../styles"

Item {
  id: root

  property bool busy: false
  property color overlayColor: Theme.panelBackgroundSecondary
  property color spinnerColor: Theme.accent
  property int radius: 0

  visible: busy

  Rectangle {
    anchors.fill: parent
    radius: root.radius
    antialiasing: true
    color: root.overlayColor
    opacity: 0.4
  }

  Spinner {
    anchors.centerIn: parent
    spinnerSize: Math.min(parent.width, parent.height) * 0.4
    spinnerColor: root.spinnerColor
  }
}
