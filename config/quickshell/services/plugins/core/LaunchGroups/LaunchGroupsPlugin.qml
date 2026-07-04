pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../../styles"
import "../../../../components"
import "../../../../core"
import "../../../"

BasePlugin {
  id: root
  visible: false

  // ── Manifest ────────────────────────────────────────────────────
  pluginId: "launchgroups"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Quick Launch",
    description: "App launcher groups",
    icon: "rocket",
    locations: ["controlcenter_row"],
    settings: [
      {
        key: "groups",
        label: "GROUPS",
        type: "json",
        default: JSON.stringify([
          { name: "DEV", apps: [
            { name: "Terminal", icon: "terminal", exec: "@terminal" },
            { name: "VS Code", icon: "code", exec: "code" },
            { name: "Files", icon: "folder", exec: "@files" }
          ]},
          { name: "MEDIA", apps: [
            { name: "Browser", icon: "world", exec: "@browser" },
            { name: "Spotify", icon: "music", exec: "spotify" },
            { name: "VLC", icon: "player-play", exec: "vlc" }
          ]}
        ])
      }
    ]
  })

  // ── Public state ─────────────────────────────────────────────────

  // ── Internal state ───────────────────────────────────────────────
  property var _groups: {
    var raw = PluginService.getPluginSetting("launchgroups", "groups", "controlcenter_row")
    try { return typeof raw === "string" ? JSON.parse(raw) : (raw || []) }
    catch(e) { return [] }
  }

  // ── Signal handlers ──────────────────────────────────────────────

  // ── Public API ───────────────────────────────────────────────────
  function _launch(exec: string): void {
    var tokens = { "@terminal": "terminal", "@browser": "browser", "@files": "fileManager", "@editor": "editor" }
    if (tokens[exec]) {
      DefaultAppsService.launch(tokens[exec])
      return
    }
    ProcessPool.runTracked("Launch", ["sh", "-c", "nohup " + exec + " >/dev/null 2>&1 &"], "launch-" + exec)
  }

  // ── Helpers ──────────────────────────────────────────────────────

  // ── Timers ───────────────────────────────────────────────────────

  // ── Lifecycle ────────────────────────────────────────────────────

  // ── UI components ────────────────────────────────────────────────
  property Component controlCenterComponent: Column {
    width: parent.width
    spacing: Theme.spaceMd

    SectionLabel { label: "LAUNCH" }

    Repeater {
      model: root._groups

      delegate: Column {
        required property var modelData
        width: parent.width
        spacing: Theme.spaceSm

        Text {
          text: modelData.name
          color: Theme.textDisabled
          font.pixelSize: Theme.fontSizeLabel
          font.family: Theme.fontFamilyMono
          font.letterSpacing: 0.1
        }

        ButtonGroup {
          width: parent.width
          fillWidth: true

          Repeater {
            model: modelData.apps || []

            delegate: Button {
              required property var modelData
              Layout.fillWidth: true
              size: "sm"
              text: (modelData.name || "").toUpperCase()
              icon: modelData.icon || "player-play"
              actionId: "launch"
              onClicked: root._launch(modelData.exec)
            }
          }
        }
      }
    }

    Text {
      text: root._groups.length === 0 ? "NO GROUPS CONFIGURED" : ""
      color: Theme.textDisabled
      font.pixelSize: Theme.fontSizeCaption
      font.family: Theme.fontFamilyMono
      font.letterSpacing: 0.06
      visible: root._groups.length === 0
      anchors.horizontalCenter: parent.horizontalCenter
    }
  }
}
