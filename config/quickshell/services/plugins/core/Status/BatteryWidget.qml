import QtQuick
import Quickshell
import "../../../../styles"
import "../../../../services"
import "../../../../core"

Item {
  id: root

  width: contentRow.implicitWidth + 4
  height: 30
  visible: BatteryService.hasBattery

  Row {
    id: contentRow
    anchors.centerIn: parent
    spacing: Theme.spaceXs + 2

    Text {
      text: BatteryService.percentage.toFixed(0)
      color: BatteryService.lowBattery ? Theme.accent : Theme.textPrimary
      font.pixelSize: Theme.fontSizeBody
      font.family: Theme.fontFamilyMono
      font.weight: Font.Medium
    }

    Text {
      text: "%"
      color: Theme.textSecondary
      font.pixelSize: Theme.fontSizeCaption
      font.family: Theme.fontFamilyMono
    }

    Text {
      text: BatteryService.charging ? "↑" : (BatteryService.discharging ? "↓" : "─")
      color: BatteryService.charging ? Theme.success : Theme.textSecondary
      font.pixelSize: Theme.fontSizeCaption
      font.family: Theme.fontFamilyMono
      visible: BatteryService.hasBattery
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: batteryTooltip.toggle()
  }

  BatteryTooltip {
    id: batteryTooltip
    anchorItem: root
  }
}
