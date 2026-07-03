pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../../../styles"
import "../../../../components"
import "../../../../services"
import "../../../../core"
import "../../../"

BasePlugin {
  id: root

  // ── Manifest ────────────────────────────────────────────────────
  pluginId: "bar-workspaces"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Workspaces",
    description: "Workspace indicators and window title",
    icon: "grid",
    locations: ["bar_left"],
    settings: []
  })

  // ── Public state ─────────────────────────────────────────────────

  // ── Internal state ───────────────────────────────────────────────

  // ── Signal handlers ──────────────────────────────────────────────

  // ── Public API ───────────────────────────────────────────────────
  function getActiveClientTitle(): string {
    var c = HyprlandService.activeClient
    
    if (c && c.title) {
      if (c.title.length > 25) {
        return c.title.substring(0, 10) + "..." + c.title.substring(c.title.length - 5, c.title.length)
      } else {
        return c.title
      }
    } else {
      return AppInfo.displayName
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────

  // ── Timers ───────────────────────────────────────────────────────

  // ── Lifecycle ────────────────────────────────────────────────────

  // ── UI components ────────────────────────────────────────────────
  property Component barComponent: Row {
    spacing: Theme.spaceSm

    WorkspacesWidget { anchors.verticalCenter: parent.verticalCenter }

    Divider { vertical: true; height: 18; anchors.verticalCenter: parent.verticalCenter }

    Item {
      anchors.verticalCenter: parent.verticalCenter
      width: 200
      height: 24
      clip: true

      Row {
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        spacing: Theme.controlSpacing

        Text {
          text: {
            var c = HyprlandService.activeClient
            return c && c.class ? c.class : ""
          }
          color: Theme.textSecondary
          font.pixelSize: Theme.fontSizeCaption
          font.family: Theme.fontFamilyMono
          font.letterSpacing: 0.04
          visible: text !== ""
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          id: titleText
          anchors.verticalCenter: parent.verticalCenter
          width: 180
          text: getActiveClientTitle()
          color: Theme.textPrimary
          font.pixelSize: Theme.fontSizeCaption
          font.family: Theme.fontFamilyMono
          font.letterSpacing: 0.04
          elide: Text.ElideRight
          maximumLineCount: 1
        }
      }
    }
  }
}
