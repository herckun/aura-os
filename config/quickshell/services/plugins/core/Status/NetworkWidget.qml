import QtQuick
import "../../../../styles"
import "../../../../services"

Item {
  id: root

  implicitWidth: row.width
  implicitHeight: 22

  property string networkIcon: {
    if (!NetworkService.online) return "⊘"
    if (NetworkService.ethernetConnected) return "⊡"
    if (NetworkService.signalStrength > 75) return "⊙"
    if (NetworkService.signalStrength > 50) return "⊚"
    if (NetworkService.signalStrength > 25) return "◐"
    return "◑"
  }

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.spaceXs

    Text {
      text: root.networkIcon
      color: NetworkService.online ? Theme.textPrimary : Theme.textDisabled
      font.pixelSize: Theme.fontSizeBody
      font.family: Theme.fontFamilyMono
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      text: NetworkService.online
            ? (NetworkService.ethernetConnected ? "ETH" : NetworkService.primarySsid)
            : "OFF"
      color: NetworkService.online ? Theme.textPrimary : Theme.textDisabled
      font.pixelSize: Theme.fontSizeCaption
      font.family: Theme.fontFamilyMono
      font.letterSpacing: 0.04
      anchors.verticalCenter: parent.verticalCenter
      elide: Text.ElideRight
      width: implicitWidth > 60 ? 60 : implicitWidth
    }
  }
}
