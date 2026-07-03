pragma ComponentBehavior: Bound

import QtQuick
import QtQml
import QtQuick.Layouts
import "../../../../styles"
import "../../../../services"
import "../../../../core"
import "../../../../components"

BasePlugin {
  id: root

  // ── Manifest ────────────────────────────────────────────────────
  pluginId: "resourcemonitor"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Resource Monitor",
    description: "CPU, memory, and GPU usage display",
    icon: "cpu",
    locations: ["desktop"],
    settings: [
      {
        key: "draggable",
        label: "DRAGGABLE",
        description: "Allow repositioning by dragging",
        type: "toggle",
        default: true
      },
      {
        key: "autoPosition",
        label: "AUTO POSITION",
        description: "Find best position on wallpaper automatically",
        type: "toggle",
        default: false
      },
      {
        key: "showBackground",
        label: "BACKGROUND",
        description: "Show background behind widget",
        type: "toggle",
        default: true
      },
      {
        key: "showCpu",
        label: "SHOW CPU",
        description: "Display CPU usage",
        type: "toggle",
        default: true
      },
      {
        key: "showMemory",
        label: "SHOW MEMORY",
        description: "Display memory usage",
        type: "toggle",
        default: true
      },
      {
        key: "showGpu",
        label: "SHOW GPU",
        description: "Display GPU usage if available",
        type: "toggle",
        default: true
      },
      {
        key: "showGraph",
        label: "SHOW GRAPH",
        description: "Display usage history graph",
        type: "toggle",
        default: true
      },
      {
        key: "widgetSize",
        label: "WIDGET SIZE",
        description: "Scale of the widget",
        type: "stepper",
        min: 80,
        max: 150,
        step: 10,
        unit: "%",
        default: 100
      }
    ]
  })

  // ── Public state ─────────────────────────────────────────────────

  // ── Internal state ───────────────────────────────────────────────

  // ── Signal handlers ──────────────────────────────────────────────

  // ── Public API ───────────────────────────────────────────────────

  // ── Helpers ──────────────────────────────────────────────────────

  // ── Timers ───────────────────────────────────────────────────────

  // ── Lifecycle ────────────────────────────────────────────────────

  // ── UI components ────────────────────────────────────────────────
  property Component desktopComponent: Item {
    id: monitorContainer
    width: mainCol.implicitWidth
    height: mainCol.implicitHeight

    property bool _showCpu: PluginService.getPluginSetting("resourcemonitor", "showCpu", "desktop") ?? true
    property bool _showMemory: PluginService.getPluginSetting("resourcemonitor", "showMemory", "desktop") ?? true
    property bool _showGpu: PluginService.getPluginSetting("resourcemonitor", "showGpu", "desktop") ?? true
    property bool _showGraph: PluginService.getPluginSetting("resourcemonitor", "showGraph", "desktop") ?? true
    property real _widgetSize: PluginService.getPluginSetting("resourcemonitor", "widgetSize", "desktop") ?? 100
    readonly property real _scale: monitorContainer._widgetSize / 100

    property var desktopWidget: null

    readonly property color _textColor: desktopWidget ? desktopWidget.widgetTextColor : Theme.textPrimary
    readonly property color _dimColor: desktopWidget ? desktopWidget.widgetDimColor : Theme.textSecondary
    readonly property color _accentColor: desktopWidget ? desktopWidget.widgetAccentColor : Theme.accent

    ColumnLayout {
      id: mainCol
      spacing: Theme.spaceSm * monitorContainer._scale

      MetricGauge {
        visible: monitorContainer._showCpu
        Layout.fillWidth: true
        scale: monitorContainer._scale
        label: "CPU"
        value: ResourceService.cpuUsage.toFixed(1) + "%"
        fraction: ResourceService.cpuUsage / 100
        labelColor: monitorContainer._dimColor
        valueColor: monitorContainer._textColor
        barColor: monitorContainer._accentColor
        trackColor: Qt.rgba(1, 1, 1, 0.1)

        Sparkline {
          visible: monitorContainer._showGraph && ResourceService.cpuHistory.length > 1
          Layout.fillWidth: true
          Layout.preferredHeight: 40 * monitorContainer._scale
          values: ResourceService.cpuHistory
          lineColor: monitorContainer._accentColor
        }
      }

      MetricGauge {
        visible: monitorContainer._showMemory
        Layout.fillWidth: true
        scale: monitorContainer._scale
        label: "MEM"
        value: ResourceService.memPct.toFixed(1) + "%"
        fraction: ResourceService.memPct / 100
        labelColor: monitorContainer._dimColor
        valueColor: monitorContainer._textColor
        barColor: monitorContainer._accentColor
        trackColor: Qt.rgba(1, 1, 1, 0.1)

        Text {
          text: ResourceService.memUsed + " MB / " + ResourceService.memTotal + " MB"
          font.family: Theme.fontFamilyMono
          font.pixelSize: Math.round(Theme.fontSizeCaption * monitorContainer._scale)
          color: monitorContainer._dimColor
        }
      }

      MetricGauge {
        visible: monitorContainer._showGpu && ResourceService.gpuAvailable && ResourceService.gpuHasData
        Layout.fillWidth: true
        scale: monitorContainer._scale
        label: "GPU"
        value: ResourceService.gpuLoad
        fraction: (parseFloat(ResourceService.gpuLoad) || 0) / 100
        labelColor: monitorContainer._dimColor
        valueColor: monitorContainer._textColor
        barColor: monitorContainer._accentColor
        trackColor: Qt.rgba(1, 1, 1, 0.1)

        RowLayout {
          Layout.fillWidth: true

          Text {
            visible: ResourceService.gpuTemp !== "---"
            text: ResourceService.gpuTemp
            font.family: Theme.fontFamilyMono
            font.pixelSize: Math.round(Theme.fontSizeCaption * monitorContainer._scale)
            color: monitorContainer._dimColor
          }

          Text {
            visible: ResourceService.gpuVramUsed !== "N/A"
            text: ResourceService.gpuVramUsed + " / " + ResourceService.gpuVramTotal
            font.family: Theme.fontFamilyMono
            font.pixelSize: Math.round(Theme.fontSizeCaption * monitorContainer._scale)
            color: monitorContainer._dimColor
          }
        }
      }
    }
  }
}
