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
    description: "Sound, network, and battery indicators",
    icon: "signal",
    locations: ["bar_right"],
    defaultLayout: { "bar_right": { order: 10 } },
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
  readonly property bool _pill: AppearanceService.barSeparatorStyle === "background"

  property Component barComponent: Row {
    spacing: root._pill ? Theme.spaceXs : Theme.spaceSm

    BarItem { pillMode: root._pill; SoundWidget { } }

    Divider {
      visible: !root._pill
      vertical: true; height: 18
      anchors.verticalCenter: parent.verticalCenter
    }

    BarItem { pillMode: root._pill; NetworkWidget { } }

    Divider {
      visible: !root._pill && BatteryService.hasBattery
      vertical: true; height: 18
      anchors.verticalCenter: parent.verticalCenter
    }

    BarItem {
      pillMode: root._pill
      visible: BatteryService.hasBattery
      BatteryWidget { }
    }

    Divider {
      visible: !root._pill
      vertical: true; height: 18
      anchors.verticalCenter: parent.verticalCenter
    }

    BarItem {
      pillMode: root._pill
      Button {
        shape: "icon"
        anchors.centerIn: parent
        width: 24; height: 24
        text: "⋮"
        showBackground: false
        onClicked: IpcService.togglePanel("controlcenter")
      }
    }
  }
}
