pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../../../styles"
import "../../../../components"
import "../../../../core"
import "../../../"

BasePlugin {
  id: root

  // ── Manifest ────────────────────────────────────────────────────
  pluginId: "workspaces"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Workspaces",
    description: "Hyprland workspace switcher",
    icon: "grid",
    locations: ["overview"],
    defaultLayout: { "overview": { order: 10 } },
    overviewTab: { icon: "grid", label: "WS", key: "1" },
    settings: []
  })

  // ── Public state ─────────────────────────────────────────────────

  // ── Internal state ───────────────────────────────────────────────
  property var _fallbackWs: [{ id: 1, name: "1" }]

  // ── Signal handlers ──────────────────────────────────────────────

  // ── Public API ───────────────────────────────────────────────────

  // ── Helpers ──────────────────────────────────────────────────────

  // ── Timers ───────────────────────────────────────────────────────

  // ── Lifecycle ────────────────────────────────────────────────────

  // ── UI components ────────────────────────────────────────────────
  property Component overviewComponent: Item {
    implicitHeight: wsFlow.implicitHeight + (Theme.spaceSm + 2) * 2

    Flow {
      id: wsFlow
      anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; margins: Theme.spaceSm + 2 }
      spacing: Theme.spaceSm

      property int _itemCount: {
        var ws = HyprlandService.workspaces
        return ws ? ws.length : 1
      }
      property int _maxCols: Math.max(1, Math.floor((width + spacing) / (140 + spacing)))
      property int _cols: Math.min(_itemCount, _maxCols)
      property int _rows: Math.max(1, Math.ceil(_itemCount / _cols))
      property real tileWidth: (width - (_cols - 1) * spacing) / _cols
      property real tileHeight: tileWidth * 0.7

      Repeater {
        model: {
          var ws = HyprlandService.workspaces
          if (!ws || ws.length === 0) return root._fallbackWs
          return ws
        }

        delegate: Item {
          required property var modelData
          id: tileDelegate
          width: wsFlow.tileWidth
          height: wsFlow.tileHeight

          property bool isActive: modelData.id === HyprlandService.activeWsId
          property var wsClients: {
            var clients = []
            var allClients = HyprlandService.clients
            if (allClients) {
              for (var i = 0; i < allClients.length; i++) {
                if (allClients[i].workspace && allClients[i].workspace.id === modelData.id)
                  clients.push(allClients[i])
              }
            }
            return clients
          }
          property int _clickIndex: 0
          property var _wsId: modelData.id || index + 1

          Surface {
            anchors.fill: parent
            radius: Theme.radiusMedium
            antialiasing: true
            color: tileDelegate.isActive ? Theme.controlBackgroundActive : Theme.backgroundSecondary
            border.color: tileDelegate.isActive ? Theme.borderActive : Theme.border

            Behavior on border.color {
              enabled: Theme.animationsEnabled
              ColorAnimation { duration: Theme.animationFast }
            }
          }

          Column {
            anchors.fill: parent
            anchors.margins: Theme.spaceSm + 2
            spacing: Theme.spaceXs

            Row {
              width: parent.width
              spacing: Theme.spaceSm

              Rectangle {
                width: 6; height: 6
                radius: Theme.radiusSmall
                antialiasing: true
                color: tileDelegate.isActive ? Theme.accent : Theme.textDisabled
                anchors.verticalCenter: parent.verticalCenter
              }

              Text {
                text: modelData.name || (modelData.id || index + 1).toString()
                color: tileDelegate.isActive ? Theme.textPrimary : Theme.textSecondary
                font.pixelSize: Theme.fontSizeCaption
                font.family: Theme.fontFamilyMono
                font.letterSpacing: 0.04
                font.bold: tileDelegate.isActive
                anchors.verticalCenter: parent.verticalCenter
              }
            }

            Repeater {
              model: tileDelegate.wsClients.slice(0, 4)

              delegate: Text {
                required property var modelData
                width: parent ? parent.width : 0
                text: modelData.class || modelData.title || "Window"
                color: Qt.rgba(Theme.textSecondary.r, Theme.textSecondary.g, Theme.textSecondary.b, 0.7)
                font.pixelSize: Theme.fontSizeMicro
                font.family: Theme.fontFamilyMono
                elide: Text.ElideRight
              }
            }

            Item { width: 1; height: 1 }

            Text {
              text: tileDelegate.wsClients.length === 0 ? "EMPTY" : ""
              color: Theme.textDisabled
              font.pixelSize: Theme.fontSizeMicro
              font.family: Theme.fontFamilyMono
              font.letterSpacing: 0.06
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              var clients = tileDelegate.wsClients

              if (tileDelegate.isActive && clients.length > 0) {
                tileDelegate._clickIndex = (tileDelegate._clickIndex + 1) % clients.length
                HyprlandService.focusWindow(clients[tileDelegate._clickIndex].address)
              } else if (clients.length > 0) {
                HyprlandService.setWorkspace(tileDelegate._wsId)
                HyprlandService.focusWindow(clients[0].address)
              } else {
                HyprlandService.setWorkspace(tileDelegate._wsId)
              }
            }
          }
        }
      }
    }
  }
}
