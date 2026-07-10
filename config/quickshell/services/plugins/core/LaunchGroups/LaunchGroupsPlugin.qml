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
    defaultLayout: { "controlcenter_row": { order: 70 } },
    settings: [
      {
        key: "groups",
        label: "GROUPS",
        type: "json",
        default: JSON.stringify([
          { name: "DEV", apps: [
            { name: "Terminal", icon: "terminal", exec: "@terminal" },
            { name: "Editor", icon: "code", exec: "@editor" },
            { name: "Files", icon: "folder", exec: "@files" }
          ]},
          { name: "MEDIA", apps: [
            { name: "Browser", icon: "world", exec: "@browser" },
            { name: "Music", icon: "music", exec: "@music" },
            { name: "Video", icon: "player-play", exec: "@video" }
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
    var tokens = {
      "@terminal": "terminal",
      "@browser": "browser",
      "@files": "fileManager",
      "@editor": "editor",
      "@music": "audioPlayer",
      "@video": "videoPlayer",
      "@image": "imageViewer",
      "@pdf": "pdfViewer"
    }
    var cmd = exec
    if (tokens[exec]) {
      cmd = DefaultAppsService.execFor(tokens[exec])
      if (!cmd) {
        DefaultAppsService.launch(tokens[exec])
        return
      }
    }
    ProcessPool.runDetachedBusy(["sh", "-c", cmd + " >/dev/null 2>&1"], "launch:" + exec, 1500)
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
        spacing: Theme.spaceXs

        Text {
          text: (modelData.name || "").toUpperCase()
          color: Theme.textDisabled
          font.pixelSize: Theme.fontSizeMicro
          font.family: Theme.fontFamilyMono
          font.letterSpacing: 0.08
        }

        RowLayout {
          width: parent.width
          spacing: Theme.spaceSm

          Repeater {
            model: modelData.apps || []

            delegate: Button {
              required property var modelData
              shape: "tile"
              Layout.fillWidth: true
              Layout.fillHeight: true
              Layout.preferredHeight: tileContentHeight
              icon: modelData.icon || "player-play"
              label: (modelData.name || "").toUpperCase()
              actionId: "launch:" + (modelData.exec || "")
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
