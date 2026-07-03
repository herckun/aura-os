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
  pluginId: "powerprofile"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Power Profile",
    description: "CPU power profile switcher",
    icon: "bolt",
    dependencies: [{ bin: "tlp", install: "sudo pacman -S --noconfirm tlp" }],
    locations: ["controlcenter_row"],
    settings: []
  })

  // ── Public state ─────────────────────────────────────────────────

  // ── Internal state ───────────────────────────────────────────────
  readonly property int _profile: PerformanceService.profile

  // ── Signal handlers ──────────────────────────────────────────────

  // ── Public API ───────────────────────────────────────────────────

  // ── Helpers ──────────────────────────────────────────────────────
  function _profileName(): string {
    return _profile === 0 ? "PERFORMANCE" : _profile === 2 ? "BATTERY SAVER" : "BALANCED"
  }

  // ── Timers ───────────────────────────────────────────────────────

  // ── Lifecycle ────────────────────────────────────────────────────

  // ── UI components ────────────────────────────────────────────────
  property Component controlCenterComponent: Column {
    width: parent.width
    spacing: Theme.spaceSm

    SectionLabel { label: "POWER" }

    OptionSwitcher {
      width: parent.width
      options: ["PERF", "BAL", "SAVE"]
      currentIndex: root._profile
      size: "sm"
      onSelected: (idx) => PerformanceService.switchProfile(idx)
    }

    Text {
      text: root._profileName()
      color: Theme.textDisabled
      font.pixelSize: Theme.fontSizeMicro
      font.family: Theme.fontFamilyMono
      font.letterSpacing: 0.08
      anchors.horizontalCenter: parent.horizontalCenter
    }
  }
}
