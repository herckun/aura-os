import QtQuick
import "../styles"

Rectangle {
  id: root

  property int level: 1
  property bool bordered: true
  property real padding: 0
  default property alias content: contentHolder.data

  radius: Theme.radiusLarge
  color: level >= 2 ? Theme.backgroundTertiary : Theme.backgroundSecondary
  border.width: bordered ? Theme.borderWidth : 0
  border.color: Theme.borderVisible

  Item {
    id: contentHolder
    anchors.fill: parent
    anchors.margins: root.padding
  }
}
