import QtQuick
import "../../../../styles"
import "../../../../services"

Item {
  id: root
  implicitWidth: row.implicitWidth
  implicitHeight: 28

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
    spacing: Theme.spaceXs

    Text {
      text: WeatherService.location + (WeatherService.countryCode ? ", " + WeatherService.countryCode.toUpperCase() : "") + " " + WeatherService.temp
      color: Theme.textPrimary
      font.pixelSize: Theme.fontSizeCaption
      font.family: Theme.fontFamilyMono
      font.letterSpacing: 0.04
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: WeatherService.fetch()
  }
}
