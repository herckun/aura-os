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
    icon: "alert",
    locations: ["controlcenter_row"],
    settings: [
      { key: "showDetails", label: "SHOW DETAILS", type: "toggle", default: true }
    ]
  })

  // ── Public state ─────────────────────────────────────────────────

  // ── Internal state ───────────────────────────────────────────────
  property bool _showDetails: PluginService.getPluginSetting("weather", "showDetails", "controlcenter_row") ?? true

  // ── Signal handlers ──────────────────────────────────────────────

  // ── Public API ───────────────────────────────────────────────────

  // ── Helpers ──────────────────────────────────────────────────────

  // ── Timers ───────────────────────────────────────────────────────

  // ── Lifecycle ────────────────────────────────────────────────────

  // ── UI components ────────────────────────────────────────────────
  property Component controlCenterComponent: Column {
    width: parent.width
    spacing: Theme.spaceSm

    SectionLabel {
      label: "WEATHER"
    }

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
        spacing: Theme.spaceXxs
        Layout.fillWidth: true

        Text {
          text: WeatherService.temp
          color: Theme.textDisplay
          font.pixelSize: Theme.fontSizeTitle2
          font.family: Theme.fontFamilyDisplay
          font.bold: true
        }

        Text {
          text: WeatherService.weather
          color: Theme.textSecondary
          font.pixelSize: Theme.fontSizeCaption
          font.family: Theme.fontFamilyMono
          font.letterSpacing: 0.04
          elide: Text.ElideRight
          width: parent.width
        }

        Text {
          text: "FEELS " + WeatherService.feelsLike
          color: Theme.textDisabled
          font.pixelSize: Theme.fontSizeMicro
          font.family: Theme.fontFamilyMono
          font.letterSpacing: 0.04
        }
      }
    }

    Item { width: 1; height: 8 }

    Text {
      text: WeatherService.location
      color: Theme.textDisabled
      font.pixelSize: Theme.fontSizeMicro
      font.family: Theme.fontFamilyMono
      font.letterSpacing: 0.06
      elide: Text.ElideRight
      width: parent.width
    }

    Item { width: 1; height: 8; visible: root._showDetails }

    GridLayout {
      width: parent.width
      columns: 3
      columnSpacing: 0
      rowSpacing: Theme.controlSpacing
      visible: root._showDetails

      Column { Layout.fillWidth: true; spacing: Theme.spaceXxs
        Text { text: "HUMIDITY"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; font.letterSpacing: 0.08 }
        Text { text: WeatherService.humidity; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeLabel; font.family: Theme.fontFamilyMono }
      }
      Column { Layout.fillWidth: true; spacing: Theme.spaceXxs
        Text { text: "WIND"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; font.letterSpacing: 0.08; elide: Text.ElideRight; width: parent.width }
        Text { text: WeatherService.windSpeed + " " + WeatherService.windDir; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeLabel; font.family: Theme.fontFamilyMono; elide: Text.ElideRight; width: parent.width }
      }
      Column { Layout.fillWidth: true; spacing: Theme.spaceXxs
        Text { text: "PRESSURE"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; font.letterSpacing: 0.08 }
        Text { text: WeatherService.pressure; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeLabel; font.family: Theme.fontFamilyMono }
      }
      Column { Layout.fillWidth: true; spacing: Theme.spaceXxs
        Text { text: "SUNRISE"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; font.letterSpacing: 0.08 }
        Text { text: WeatherService.sunrise; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeLabel; font.family: Theme.fontFamilyMono }
      }
      Column { Layout.fillWidth: true; spacing: Theme.spaceXxs
        Text { text: "SUNSET"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; font.letterSpacing: 0.08 }
        Text { text: WeatherService.sunset; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeLabel; font.family: Theme.fontFamilyMono }
      }
      Column { Layout.fillWidth: true; spacing: Theme.spaceXxs
        Text { text: "UV INDEX"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; font.letterSpacing: 0.08 }
        Text { text: WeatherService.uvIndex; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeLabel; font.family: Theme.fontFamilyMono }
      }
    }
  }
}
