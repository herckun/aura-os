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
    locations: ["controlcenter_row", "bar_right"],
    defaultLayout: { "bar_right": { enabled: false }, "controlcenter_row": { order: 30 } },
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

    function _fmtMb(mb) {
      return mb >= 1024 ? (mb / 1024).toFixed(1) + " GB" : Math.round(mb) + " MB"
    }

    function _barColor(pct) {
      if (pct > 90) return Theme.error
      if (pct > 70) return Theme.warning
      return Theme.accent
    }

    SectionLabel {
      label: "SYSTEM"
    }

    MetricGauge {
      width: parent.width
      label: "CPU"
      labelColor: Theme.textDisabled
      labelLetterSpacing: 0.08
      value: ResourceService.cpuUsage + "%" + (ResourceService.cpuTemp !== "" ? "  ·  " + ResourceService.cpuTemp + "°C" : "")
      valueFontSize: Theme.fontSizeLabel
      fraction: ResourceService.cpuUsage / 100
      barColor: parent._barColor(ResourceService.cpuUsage)
    }

    MetricGauge {
      width: parent.width
      label: "MEMORY"
      labelColor: Theme.textDisabled
      labelLetterSpacing: 0.08
      value: parent._fmtMb(ResourceService.memUsed) + " / " + parent._fmtMb(ResourceService.memTotal)
      valueFontSize: Theme.fontSizeLabel
      fraction: ResourceService.memPct / 100
      barColor: parent._barColor(ResourceService.memPct)
    }

    Item {
      width: parent.width
      height: updatesLabel.implicitHeight

      Text {
        id: updatesLabel
        anchors.left: parent.left
        text: "UPDATES"
        color: Theme.textDisabled
        font.pixelSize: Theme.fontSizeMicro
        font.family: Theme.fontFamilyMono
        font.letterSpacing: 0.08
      }

      Text {
        anchors.right: parent.right
        anchors.verticalCenter: updatesLabel.verticalCenter
        text: UpdatesService.hasUpdates ? UpdatesService.pendingUpdates + " PENDING" : "UP TO DATE"
        color: UpdatesService.hasUpdates ? Theme.warning : Theme.textSecondary
        font.pixelSize: Theme.fontSizeCaption
        font.family: Theme.fontFamilyMono
        font.letterSpacing: 0.04
      }
    }

    Column {
      width: parent.width
      spacing: Theme.spaceSm
      visible: ResourceService.gpuAvailable && ResourceService.gpuHasData

      SectionLabel {
        label: "GPU"
        topPadding: Theme.spaceXs
      }

      Row {
        width: parent.width
        spacing: 0

        Column { spacing: Theme.spaceXxs; width: parent.width / 3
          Text { text: "LOAD"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; font.letterSpacing: 0.06 }
          Text { text: ResourceService.gpuLoad; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeSubhead; font.family: Theme.fontFamilyDisplay }
        }

        Column { spacing: Theme.spaceXxs; width: parent.width / 3
          Text { text: "TEMP"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; font.letterSpacing: 0.06 }
          Text { text: ResourceService.gpuTemp + "C"; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeSubhead; font.family: Theme.fontFamilyDisplay }
        }

        Column { spacing: Theme.spaceXxs; width: parent.width / 3
          Text { text: "CLOCK"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; font.letterSpacing: 0.06 }
          Text { text: ResourceService.gpuClock; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeSubhead; font.family: Theme.fontFamilyDisplay }
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
      antialiasing: true
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
