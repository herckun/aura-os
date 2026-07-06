pragma ComponentBehavior: Bound
import QtQuick
import QtQml
import QtQuick.Layouts
import "../../../../styles"
import "../../../../components"
import "../../../../core"
import "../../../"

BasePlugin {
  id: root

  // ── Manifest ────────────────────────────────────────────────────
  pluginId: "system"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "System",
    description: "CPU, memory, GPU, and updates",
    icon: "cpu",
    locations: ["controlcenter_row", "bar_right", "dashboard"],
    defaultLayout: { "bar_right": { enabled: false }, "controlcenter_row": { order: 30 }, "dashboard": { order: 10 } },
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

    SectionLabel {
      label: "SYSTEM"
    }

    Row {
      width: parent.width
      spacing: 0

      Column { spacing: Theme.spaceXxs; width: parent.width / 3
        Text { text: "CPU"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; font.letterSpacing: 0.06 }
        Text { text: ResourceService.cpuUsage + "%"; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeSubhead; font.family: Theme.fontFamilyDeco }
      }

      Column { spacing: Theme.spaceXxs; width: parent.width / 3
        Text { text: "MEM"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; font.letterSpacing: 0.06 }
        Text { text: ResourceService.memUsed + "MB"; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeSubhead; font.family: Theme.fontFamilyDeco }
      }

      Column { spacing: Theme.spaceXxs; width: parent.width / 3
        Text { text: UpdatesService.hasUpdates ? "UPDATES" : "STATUS"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; font.letterSpacing: 0.06 }
        Text { text: UpdatesService.hasUpdates ? UpdatesService.pendingUpdates + " PKG" : "UP TO DATE"; color: UpdatesService.hasUpdates ? Theme.warning : Theme.textSecondary; font.pixelSize: Theme.fontSizeBody; font.family: Theme.fontFamilyDeco }
      }
    }

    Column {
      width: parent.width
      spacing: Theme.spaceSm
      visible: ResourceService.gpuAvailable && ResourceService.gpuHasData

      Row {
        width: parent.width
        spacing: 0

        Column { spacing: Theme.spaceXxs; width: parent.width / 3
          Text { text: "LOAD"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; font.letterSpacing: 0.06 }
          Text { text: ResourceService.gpuLoad; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeSubhead; font.family: Theme.fontFamilyDeco }
        }

        Column { spacing: Theme.spaceXxs; width: parent.width / 3
          Text { text: "TEMP"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; font.letterSpacing: 0.06 }
          Text { text: ResourceService.gpuTemp; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeSubhead; font.family: Theme.fontFamilyDeco }
        }

        Column { spacing: Theme.spaceXxs; width: parent.width / 3
          Text { text: "CLOCK"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; font.letterSpacing: 0.06 }
          Text { text: ResourceService.gpuClock; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeSubhead; font.family: Theme.fontFamilyDeco }
        }
      }

      MetricGauge {
        width: parent.width
        visible: ResourceService.gpuVramUsed !== "N/A"
        label: "VRAM"
        labelColor: Theme.textDisabled
        labelLetterSpacing: 0.08
        value: ResourceService.gpuVramUsed + " / " + ResourceService.gpuVramTotal
        valueFontSize: Theme.fontSizeLabel
        fraction: (parseFloat(ResourceService.gpuVramPct) || 0) / 100
        barColor: {
          var p = parseFloat(ResourceService.gpuVramPct) || 0
          if (p > 90) return Theme.error
          if (p > 70) return Theme.warning
          return Theme.accent
        }
      }
    }

    ToolUnavailable {
      visible: !ResourceService.gpuAvailable
      toolName: "GPU Driver"
      toolPackage: "AMD GPU driver, NVIDIA driver, or Intel GPU driver"
    }
  }

  property Component barComponent: Row {
    spacing: Theme.controlSpacing
    visible: ResourceService.gpuAvailable && ResourceService.gpuHasData

    Rectangle {
      width: gpuTempLabel.implicitWidth + 12
      height: 20
      radius: Theme.radiusSmall
      color: Theme.controlBackground

      Text {
        id: gpuTempLabel
        anchors.centerIn: parent
        text: "GPU " + ResourceService.gpuTemp
        color: Theme.textSecondary
        font.pixelSize: Theme.fontSizeCaption
        font.family: Theme.fontFamilyMono
        font.letterSpacing: 0.04
      }
    }
  }

  property Component dashboardComponent: GridLayout {
    Layout.fillWidth: true
    Layout.preferredHeight: 40
    columns: _hardwareModel.length
    columnSpacing: Theme.spaceSm

    Repeater {
      model: _hardwareModel

      delegate: InfoCard {
        required property var modelData
        Layout.fillWidth: true
        Layout.fillHeight: true
        label: modelData.label
        infoValue: modelData.value
        active: modelData.active
      }
    }

    property var _hardwareModel: {
      var m = []
      if (ResourceService.cpuTemp !== "")
        m.push({ label: "CPU TEMP", value: ResourceService.cpuTemp + "°C", active: true })
      if (ResourceService.gpuAvailable && ResourceService.gpuHasData) {
        if (ResourceService.gpuTemp !== "---")
          m.push({ label: "GPU TEMP", value: ResourceService.gpuTemp, active: true })
        if (ResourceService.gpuLoad !== "---")
          m.push({ label: "GPU LOAD", value: ResourceService.gpuLoad, active: true })
      }
      if (ResourceService.fanSpeed !== "")
        m.push({ label: "FAN", value: ResourceService.fanSpeed + " RPM", active: true })
      return m
    }
  }
}
