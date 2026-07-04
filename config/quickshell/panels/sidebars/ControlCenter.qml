import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../styles"
import "../../core"
import "../../services"
import "../../components"

PanelContainer {
  id: cc

  implicitWidth: 320
  paddingX: 22
  paddingY: 20
  maxHeightRatio: 0.88

  // ── Header ──────────────────────────────────────────────
  ControlCenterHeader {}

  // ── Quick Toggles ───────────────────────────────────────
  Section {
    borderEnabled: false
    transparentBg: true
    paddingX: 0
    paddingY: 0
    QuickToggles {
      width: parent.width
    }
  }

  // ── Volume + Brightness ─────────────────────────────────
  Section {
    Column {
      width: parent.width
      spacing: Theme.spaceMd

      SliderControl {
        width: parent.width
        from: 0; to: 1.0
        value: AudioService.volume
        stepSize: 0.05
        label: AudioService.muted ? "VOLUME  ·  MUTED" : "VOLUME"
        unit: "%"
        displayMin: 0; displayMax: 100
        opacity: AudioService.muted ? 0.5 : 1
        onMoved: (v) => AudioService.setVolume(v)
      }

      SliderControl {
        width: parent.width
        from: 0.05; to: 1
        value: BrightnessService.brightness
        stepSize: 0.05
        label: "BRIGHTNESS"
        unit: "%"
        displayMin: 5; displayMax: 100
        visible: BrightnessService.hasDevice
        onMoved: (v) => BrightnessService.setBrightness(v)
      }
    }
  }

  // ── Plugin Sections ─────────────────────────────────────
  PluginHost {
    width: parent.width
    location: "controlcenter_row"
    sectioned: true
  }
}
