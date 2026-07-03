import QtQuick
import "../../../../styles"
import "../../../../services"

Item {
  id: root
  width: 14
  height: 14
  visible: count > 0

  property int count: NotificationService.unreadCount

  Rectangle {
    anchors.fill: parent
    radius: Theme.radiusPill
    color: Theme.accent
  }

  Text {
    anchors.centerIn: parent
    text: count > 9 ? "9+" : count.toString()
    color: Theme.contrastTextColor(Theme.accent)
    font.pixelSize: Theme.fontSizeMicro
    font.family: Theme.fontFamilyMono
    font.bold: true
  }
}
