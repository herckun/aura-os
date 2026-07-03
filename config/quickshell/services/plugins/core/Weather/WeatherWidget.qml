import QtQuick
import "../../../../styles"
import "../../../../services"

Item {
  id: root
  implicitWidth: row.implicitWidth + 4
  implicitHeight: 30

  property bool hasData: WeatherService.hasData

  opacity: hasData ? 1.0 : 0.0
  Behavior on opacity {
    enabled: Theme.animationsEnabled
    NumberAnimation { duration: Theme.animationNormal }
  }
  visible: opacity > 0

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.spaceXs + 2

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: WeatherService.wmoIcon(WeatherService.weatherCode)
      color: Theme.textSecondary
      font.pixelSize: Theme.fontSizeBody
      font.family: Theme.fontFamilyMono
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: WeatherService.temp
      color: Theme.textPrimary
      font.pixelSize: Theme.fontSizeBody
      font.family: Theme.fontFamilyMono
      font.weight: Font.Medium
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: WeatherService.weather.toUpperCase()
      color: Theme.textSecondary
      font.pixelSize: Theme.fontSizeMicro
      font.family: Theme.fontFamilyMono
      font.letterSpacing: 0.06
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: weatherTooltip.toggle()
  }

  WeatherTooltip {
    id: weatherTooltip
    anchorItem: root
  }
}
