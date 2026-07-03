pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../../styles"
import "../../../../components"
import "../../../../core"
import "../../../"

BasePlugin {
  id: root
  visible: false

  // ── Manifest ────────────────────────────────────────────────────
  pluginId: "disk"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Disk",
    description: "Storage usage",
    icon: "database",
    locations: ["controlcenter_row"],
    settings: []
  })

  // ── Public state ─────────────────────────────────────────────────

  // ── Internal state ───────────────────────────────────────────────
  property var _mounts: []
  property var _pollHandle: null

  readonly property int _basePollInterval: 10000

  readonly property int _pollInterval: PerformanceService.scaleInterval(_basePollInterval)

  property var _busHandles: []

  // ── Signal handlers ──────────────────────────────────────────────

  // ── Public API ───────────────────────────────────────────────────
  function _poll(): void {
    if (_pollHandle && _pollHandle.running) return
    _pollHandle = ProcessPool.runTracked("Disk poll", "df -h --output=source,size,used,avail,pcent,target -x tmpfs -x devtmpfs -x efivarfs 2>/dev/null | tail -n +2", { id: "disk-poll", shell: true, callback: function(r) {
        _pollHandle = null
        var lines = r.stdout.trim().split("\n")
        var mounts = []
        for (var i = 0; i < lines.length; i++) {
          var line = lines[i].replace(/\s+/g, " ").trim()
          if (line.length === 0) continue
          var parts = line.split(" ")
          if (parts.length >= 6) {
            mounts.push({
              device: parts[0],
              size: parts[1],
              used: parts[2],
              avail: parts[3],
              pct: parseInt(parts[4]) || 0,
              mount: line.split(/\s+/).slice(5).join(" ")
            })
          }
        }
        root._mounts = mounts
      }})
  }

  // ── Helpers ──────────────────────────────────────────────────────

  // ── Timers ───────────────────────────────────────────────────────
  Timer {
    id: pollTimer
    interval: root._pollInterval
    running: false
    repeat: true
    onTriggered: root._poll()
  }

  // ── Lifecycle ────────────────────────────────────────────────────
  Component.onCompleted: {
    _poll()
    pollTimer.running = true
  }

  // ── UI components ────────────────────────────────────────────────
  property Component controlCenterComponent: Column {
    width: parent.width
    spacing: Theme.spaceSm

    SectionLabel { label: "STORAGE" }

    Repeater {
      model: root._mounts

      delegate: Column {
        required property var modelData
        width: parent.width
        spacing: Theme.spaceXs

        RowLayout {
          width: parent.width

          Text {
            text: modelData.mount
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSizeCaption
            font.family: Theme.fontFamilyMono
            font.letterSpacing: 0.04
            Layout.fillWidth: true
            elide: Text.ElideRight
          }

          Text {
            text: modelData.used + " / " + modelData.size
            color: Theme.textPrimary
            font.pixelSize: Theme.fontSizeCaption
            font.family: Theme.fontFamilyMono
          }

          Text {
            text: modelData.pct + "%"
            color: modelData.pct > 90 ? Theme.error : modelData.pct > 75 ? Theme.warning : Theme.accent
            font.pixelSize: Theme.fontSizeCaption
            font.family: Theme.fontFamilyMono
            font.bold: true
          }
        }

        ProgressBar {
          width: parent.width
          value: modelData.pct / 100
          barColor: modelData.pct > 90 ? Theme.error : modelData.pct > 75 ? Theme.warning : Theme.accent
        }
      }
    }

    Text {
      text: root._mounts.length === 0 ? "NO DISKS FOUND" : ""
      color: Theme.textDisabled
      font.pixelSize: Theme.fontSizeCaption
      font.family: Theme.fontFamilyMono
      font.letterSpacing: 0.06
      visible: root._mounts.length === 0
      anchors.horizontalCenter: parent.horizontalCenter
    }
  }
}
