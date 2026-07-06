pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../../../styles"
import "../../../../core"
import "../../../../services"
import "../../../../components"

PanelWindow {
  id: weatherPopup

  implicitWidth: 300
  implicitHeight: contentCol.implicitHeight + 32

  anchors { top: true; left: true }
  margins.top: PopupPositioner.belowBar()
  margins.left: popupX
  exclusiveZone: 0
  color: "transparent"
  visible: false

  mask: Region { item: bg }

  property Item anchorItem: null
  property real popupX: PopupPositioner.anchorCenterX(anchorItem, weatherPopup.width, weatherPopup.screen ? weatherPopup.screen.width : 0)

  function _recalcPopupX() {
    popupX = PopupPositioner.anchorCenterX(anchorItem, weatherPopup.width, weatherPopup.screen ? weatherPopup.screen.width : 0)
  }

  onWidthChanged: _recalcPopupX()
  onScreenChanged: _recalcPopupX()
  onVisibleChanged: if (visible) _recalcPopupX()

  function toggle(): void {
    visible = !visible
  }

  HyprlandFocusGrab {
    windows: [weatherPopup]
    active: weatherPopup.visible
    onCleared: weatherPopup.visible = false
  }

  Timer {
    id: leaveTimer
    interval: 2000
    onTriggered: weatherPopup.visible = false
  }

  HoverHandler {
    onHoveredChanged: {
      if (hovered) leaveTimer.stop()
      else if (weatherPopup.visible) leaveTimer.restart()
    }
  }

  Surface {
    id: bg
    anchors.fill: parent
    radius: Theme.radiusLarge

    Column {
      id: contentCol
      anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: Theme.spaceMd }
      spacing: Theme.spaceSm

      // ── Hero ───────────────────────────────────────
      RowLayout {
        width: parent.width
        spacing: Theme.spaceSm

        Text {
          text: WeatherService.wmoIcon(WeatherService.weatherCode)
          color: Theme.textPrimary
          font.pixelSize: Theme.fontSizeDisplay
          font.family: Theme.fontFamilyMono
        }

        Column {
          Layout.fillWidth: true
          spacing: Theme.space2

          Text {
            text: WeatherService.temp
            color: Theme.textDisplay
            font.pixelSize: Theme.fontSizeTitle2
            font.family: Theme.fontFamilyDeco
            font.weight: Font.Bold
          }

          Text {
            width: parent.width
            text: WeatherService.weather.toUpperCase() + "  ·  FEELS " + WeatherService.feelsLike
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSizeMicro
            font.family: Theme.fontFamilyMono
            font.letterSpacing: 0.06
            elide: Text.ElideRight
          }
        }

        Button {
          Layout.alignment: Qt.AlignTop
          shape: "icon"
          icon: "refresh"
          size: "xs"
          showBackground: false
          enabled: !WeatherService.fetching
          onClicked: WeatherService.fetch()
        }
      }

      Row {
        spacing: Theme.spaceXs

        Icon {
          anchors.verticalCenter: parent.verticalCenter
          source: Icons.get("map-pin")
          size: Theme.fontSizeMicro
          color: Theme.textDisabled
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: (WeatherService.location + (WeatherService.countryCode ? ", " + WeatherService.countryCode.toUpperCase() : "")).toUpperCase()
          color: Theme.textDisabled
          font.pixelSize: Theme.fontSizeMicro
          font.family: Theme.fontFamilyMono
          font.letterSpacing: 0.06
        }
      }

      Divider { width: parent.width }

      // ── Hourly strip ───────────────────────────────
      Row {
        width: parent.width
        visible: WeatherService.hourly.length > 0

        Repeater {
          model: WeatherService.hourly.slice(0, 6)

          Column {
            required property var modelData
            width: parent.width / Math.min(6, Math.max(1, WeatherService.hourly.length))
            spacing: Theme.spaceXxs

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: modelData.hour
              color: Theme.textDisabled
              font.pixelSize: Theme.fontSizeMicro
              font.family: Theme.fontFamilyMono
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: WeatherService.wmoIcon(modelData.code)
              color: Theme.textSecondary
              font.pixelSize: Theme.fontSizeCaption
              font.family: Theme.fontFamilyMono
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: modelData.temp
              color: Theme.textPrimary
              font.pixelSize: Theme.fontSizeCaption
              font.family: Theme.fontFamilyMono
              font.weight: Font.DemiBold
            }
          }
        }
      }

      Divider { width: parent.width; visible: WeatherService.daily.length > 1 }

      // ── Daily forecast ─────────────────────────────
      Column {
        width: parent.width
        spacing: Theme.spaceXs
        visible: WeatherService.daily.length > 1

        Repeater {
          model: WeatherService.daily.slice(1, 6)

          Row {
            required property var modelData
            width: parent.width
            spacing: Theme.spaceSm

            Text {
              width: 42
              anchors.verticalCenter: parent.verticalCenter
              text: modelData.day
              color: Theme.textSecondary
              font.pixelSize: Theme.fontSizeMicro
              font.family: Theme.fontFamilyMono
              font.letterSpacing: 0.06
            }

            Text {
              width: 18
              anchors.verticalCenter: parent.verticalCenter
              text: WeatherService.wmoIcon(modelData.code)
              color: Theme.textSecondary
              font.pixelSize: Theme.fontSizeCaption
              font.family: Theme.fontFamilyMono
            }

            Text {
              width: parent.width - 42 - 18 - 66 - Theme.spaceSm * 3
              anchors.verticalCenter: parent.verticalCenter
              text: WeatherService.wmoDescription(modelData.code).toUpperCase()
              color: Theme.textDisabled
              font.pixelSize: Theme.fontSizeMicro
              font.family: Theme.fontFamilyMono
              font.letterSpacing: 0.04
              elide: Text.ElideRight
            }

            Row {
              width: 66
              anchors.verticalCenter: parent.verticalCenter
              spacing: Theme.spaceXs

              Text {
                text: modelData.min
                color: Theme.textDisabled
                font.pixelSize: Theme.fontSizeCaption
                font.family: Theme.fontFamilyMono
              }

              Text {
                text: modelData.max
                color: Theme.textPrimary
                font.pixelSize: Theme.fontSizeCaption
                font.family: Theme.fontFamilyMono
                font.weight: Font.DemiBold
              }
            }
          }
        }
      }

      Divider { width: parent.width }

      // ── Stats grid ─────────────────────────────────
      GridLayout {
        width: parent.width
        columns: 3
        columnSpacing: Theme.spaceSm
        rowSpacing: Theme.spaceXs

        StatCell { label: "HUMIDITY"; value: WeatherService.humidity }
        StatCell { label: "WIND"; value: WeatherService.windSpeed + " " + WeatherService.windDir }
        StatCell { label: "PRESSURE"; value: WeatherService.pressure }
        StatCell { label: "UV INDEX"; value: WeatherService.uvIndex }
        StatCell { label: "SUNRISE"; value: WeatherService.sunrise }
        StatCell { label: "SUNSET"; value: WeatherService.sunset }
      }
    }
  }

  component StatCell: Column {
    property string label: ""
    property string value: ""
    Layout.fillWidth: true
    spacing: Theme.space2

    Text {
      text: label
      color: Theme.textDisabled
      font.pixelSize: Theme.fontSizeMicro
      font.family: Theme.fontFamilyMono
      font.letterSpacing: 0.08
    }

    Text {
      width: parent.width
      text: value
      color: Theme.textPrimary
      font.pixelSize: Theme.fontSizeCaption
      font.family: Theme.fontFamilyMono
      font.weight: Font.DemiBold
      elide: Text.ElideRight
    }
  }
}
