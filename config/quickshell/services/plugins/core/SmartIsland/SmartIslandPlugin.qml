pragma ComponentBehavior: Bound

import QtQuick
import QtQml
import "../../../../styles"
import "../../../../services"
import "../../../../core"
import "../../../"

BasePlugin {
  id: root

  // ── Manifest ────────────────────────────────────────────────────
  pluginId: "smartIsland"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Smart Island",
    description: "A small, dynamic island that shows media and timer information.",
    icon: "clock",
    locations: ["bar_center"],
    settings: []
  })

  // ── Public state ─────────────────────────────────────────────────

  // ── Internal state ───────────────────────────────────────────────
  property var _busHandles: []

  property var _smartIslandPopup: null

  // ── Signal handlers ──────────────────────────────────────────────

  // ── Public API ───────────────────────────────────────────────────

  // ── Helpers ──────────────────────────────────────────────────────

  // ── Timers ───────────────────────────────────────────────────────

  // ── Lifecycle ────────────────────────────────────────────────────

  // ── UI components ────────────────────────────────────────────────
  property Component barComponent: Item {
    implicitWidth: smartIsland.implicitWidth
    implicitHeight: smartIsland.implicitHeight

    SmartIsland {
      id: smartIsland
      anchors.centerIn: parent
      onClicked: smartIslandPopup.toggle()
    }

    SmartIslandPopup {
      id: smartIslandPopup
      anchorItem: smartIsland
    }
  }
}
