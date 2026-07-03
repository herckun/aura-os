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
  pluginId: "screenshot"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Screenshots",
    description: "Screen capture",
    icon: "camera",
    locations: ["controlcenter_row"],
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
  property Component controlCenterComponent: Column {
    width: parent.width
    spacing: Theme.spaceSm

    SectionLabel { label: "SCREENSHOT" }

    ButtonGroup {
      width: parent.width
      fillWidth: true
      visible: ScreenshotService.available

      Repeater {
        model: [
          { icon: "square", tooltip: "REGION", fn: function() { ScreenshotService.captureRegion() } },
          { icon: "device-desktop", tooltip: "FULLSCREEN", fn: function() { ScreenshotService.captureScreen() } },
          { icon: "window", tooltip: "WINDOW", fn: function() { ScreenshotService.captureWindow() } }
        ]

        delegate: Button {
          required property var modelData
          Layout.fillWidth: true
          shape: "circle"
          icon: modelData.icon
          size: "md"
          buttonHeight: 30
          iconSize: 14
          tooltip: modelData.tooltip
          busy: ScreenshotService.capturing
          enabled: !ScreenshotService.capturing
          onClicked: modelData.fn()
        }
      }
    }

    ToolUnavailable {
      visible: !ScreenshotService.available
      toolName: "Grimblast"
      toolPackage: "grimblast"
    }
  }
}
