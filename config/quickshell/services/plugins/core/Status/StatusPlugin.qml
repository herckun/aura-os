pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../../../styles"
import "../../../../components"
import "../../../../services"
import "../../../../core"
import "../../../"

BasePlugin {
  id: root

  // ── Manifest ────────────────────────────────────────────────────
  pluginId: "bar-status"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Status",
    description: "Weather, network, keyboard, and battery indicators",
    icon: "signal",
    locations: ["bar_right"],
    settings: []
  })

  // ── Public state ─────────────────────────────────────────────────

  // ── Internal state ───────────────────────────────────────────────

  // ── Signal handlers ──────────────────────────────────────────────

  // ── Public API ───────────────────────────────────────────────────

  // ── Helpers ──────────────────────────────────────────────────────

  // ── Timers ───────────────────────────────────────────────────────

  // ── Lifecycle ────────────────────────────────────────────────────

  // ── UI components ────────────────────────────────────────────────
  property Component barComponent: Row {
    spacing: Theme.spaceSm

    WeatherWidget { anchors.verticalCenter: parent.verticalCenter }

    Divider { vertical: true; height: 18; anchors.verticalCenter: parent.verticalCenter; visible: WeatherService.hasData }

    NetworkWidget { anchors.verticalCenter: parent.verticalCenter }

    Divider { vertical: true; height: 18; anchors.verticalCenter: parent.verticalCenter; visible: HyprlandKeyboardService.layout !== "" }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: HyprlandKeyboardService.layout ? HyprlandKeyboardService.layout.substring(0, 2).toUpperCase() : ""
      color: Theme.textSecondary
      font.pixelSize: Theme.fontSizeCaption
      font.family: Theme.fontFamilyMono
      font.letterSpacing: 0.04
      visible: text !== ""
    }

    Divider { vertical: true; height: 18; anchors.verticalCenter: parent.verticalCenter; visible: BatteryService.hasBattery }

    BatteryWidget { anchors.verticalCenter: parent.verticalCenter; visible: BatteryService.hasBattery }
  }
}
