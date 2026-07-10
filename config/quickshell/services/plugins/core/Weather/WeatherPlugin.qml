pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../../../styles"
import "../../../../components"
import "../../../../core"
import "../../../"

BasePlugin {
  id: root
  visible: false

  // ── Manifest ────────────────────────────────────────────────────
  pluginId: "weather"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Weather",
    description: "Current weather conditions",
    icon: "sun",
    locations: ["controlcenter_row", "bar_right", "dashboard"],
    defaultLayout: { "bar_right": { enabled: false }, "controlcenter_row": { order: 20 }, "dashboard": { order: 30 } },
    settings: [
      { key: "showDetails", label: "SHOW DETAILS", type: "toggle", default: true, locations: ["controlcenter_row"] },
      { key: "location", label: "LOCATION", description: "Overrides IP-detected location", type: "text", placeholder: "City, Country", shared: true, default: "" }
    ]
  })

  // ── Internal state ───────────────────────────────────────────────
  property bool _showDetails: PluginService.getPluginSetting("weather", "showDetails", "controlcenter_row") ?? true

  readonly property bool _cfgReady: PluginService.loaded
  on_CfgReadyChanged: _syncLocation()

  // ── Helpers ──────────────────────────────────────────────────────
  function _syncLocation(): void {
    WeatherService.setLocationOverride(setting("location") || "")
  }

  // ── Lifecycle ────────────────────────────────────────────────────
  function onActivated(): void {
    _syncLocation()
  }

  function onSettingChanged(key, value): void {
    if (key === "location") WeatherService.setLocationOverride(value || "")
  }

  // ── UI components ────────────────────────────────────────────────
  property Component barComponent: WeatherWidget {}

  property Component dashboardComponent: Card {
    title: "WEATHER"
    visible: WeatherService.hasData

    GridLayout {
      width: parent.width
      columns: 2
      columnSpacing: Theme.spaceMd
      rowSpacing: 2

      Text {
        text: WeatherService.wmoIcon(WeatherService.weatherCode)
        color: Theme.textDisplay
        font.pixelSize: Theme.fontSizeHeading
        Layout.rowSpan: 2
        Layout.alignment: Qt.AlignTop
      }
      Text {
        text: WeatherService.temp
        color: Theme.textDisplay
        font.pixelSize: Theme.fontSizeTitle2
        font.family: Theme.fontFamilyDisplay
        Layout.rowSpan: 2
        Layout.alignment: Qt.AlignTop
      }

      Text { text: WeatherService.weather; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeCaption; font.family: Theme.fontFamilyMono; Layout.columnSpan: 2 }
      Text { text: "FEELS  " + WeatherService.feelsLike; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono }
      Text { text: "HUMIDITY  " + WeatherService.humidity; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono }
      Text { text: "WIND  " + WeatherService.windSpeed + " " + WeatherService.windDir; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; elide: Text.ElideRight; maximumLineCount: 1; Layout.fillWidth: true }
      Text { text: "PRESSURE  " + WeatherService.pressure; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono }
      Text { text: "UV  " + WeatherService.uvIndex; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono }
      Text { text: "SUNRISE  " + WeatherService.sunrise; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono }
      Text { text: "SUNSET  " + WeatherService.sunset; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono }
    }
  }

  property Component controlCenterComponent: Column {
    width: parent.width
    spacing: Theme.spaceSm

    SectionLabel {
      label: "WEATHER"
    }

    RowLayout {
      width: parent.width
      spacing: Theme.spaceMd

      Text {
        Layout.alignment: Qt.AlignVCenter
        text: WeatherService.wmoIcon(WeatherService.weatherCode)
        color: Theme.textPrimary
        font.pixelSize: Theme.fontSizeTitle2
        font.family: Theme.fontFamilyMono
      }

      Column {
        Layout.fillWidth: true
        spacing: Theme.space2

        RowLayout {
          width: parent.width
          spacing: Theme.spaceSm

          Text {
            text: WeatherService.temp
            color: Theme.textDisplay
            font.pixelSize: Theme.fontSizeTitle
            font.family: Theme.fontFamilyDisplay
            font.bold: true
          }

          Text {
            Layout.fillWidth: true
            text: WeatherService.weather.toUpperCase()
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSizeCaption
            font.family: Theme.fontFamilyMono
            font.letterSpacing: 0.04
            elide: Text.ElideRight
          }
        }

        Text {
          width: parent.width
          text: "FEELS " + WeatherService.feelsLike + "  ·  " + WeatherService.location.toUpperCase()
          color: Theme.textDisabled
          font.pixelSize: Theme.fontSizeMicro
          font.family: Theme.fontFamilyMono
          font.letterSpacing: 0.06
          elide: Text.ElideRight
        }
      }
    }

    Divider {
      width: parent.width
      visible: root._showDetails
    }

    GridLayout {
      width: parent.width
      columns: 3
      columnSpacing: Theme.spaceSm
      rowSpacing: Theme.spaceXs
      visible: root._showDetails

      WeatherStat { label: "HUMIDITY"; value: WeatherService.humidity }
      WeatherStat { label: "WIND"; value: WeatherService.windSpeed + " " + WeatherService.windDir }
      WeatherStat { label: "PRESSURE"; value: WeatherService.pressure }
      WeatherStat { label: "UV INDEX"; value: WeatherService.uvIndex }
      WeatherStat { label: "SUNRISE"; value: WeatherService.sunrise }
      WeatherStat { label: "SUNSET"; value: WeatherService.sunset }
    }
  }

  component WeatherStat: Column {
    id: statCell

    property string label: ""
    property string value: ""

    Layout.fillWidth: true
    spacing: Theme.spaceXxs

    Text {
      text: statCell.label
      color: Theme.textDisabled
      font.pixelSize: Theme.fontSizeMicro
      font.family: Theme.fontFamilyMono
      font.letterSpacing: 0.08
    }

    Text {
      width: parent.width
      text: statCell.value
      color: Theme.textPrimary
      font.pixelSize: Theme.fontSizeLabel
      font.family: Theme.fontFamilyMono
      elide: Text.ElideRight
    }
  }
}
