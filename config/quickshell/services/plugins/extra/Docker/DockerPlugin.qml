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
  pluginId: "docker"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Docker",
    description: "Container management",
    icon: "container",
    dependencies: [{ bin: "docker", install: "sudo pacman -S --noconfirm docker" }],
    locations: ["controlcenter_row"],
    defaultLayout: { "controlcenter_row": { enabled: false } },
    settings: [
      { key: "pollInterval", label: "POLL INTERVAL (S)", type: "stepper", default: 10, min: 5, max: 60, step: 5 }
    ]
  })

  // ── Public state ─────────────────────────────────────────────────

  // ── Internal state ───────────────────────────────────────────────
  property bool _available: false
  property var _containers: []

  property int _basePollInterval: PluginService.getPluginSetting("docker", "pollInterval", "controlcenter_row") ?? 10
  readonly property int _pollInterval: PerformanceService.scaleInterval(_basePollInterval)

  property var _busHandles: []

  property bool _ccVisible: false

  // ── Signal handlers ──────────────────────────────────────────────

  // ── Public API ───────────────────────────────────────────────────
  function _pollContainers(): void {
    ProcessPool.runTracked("Docker ps", "docker ps --format '{{.ID}}\\t{{.Names}}\\t{{.Status}}\\t{{.Image}}\\t{{.Ports}}' 2>/dev/null", { id: "docker-ps", shell: true, callback: function(r) {
        var lines = r.stdout.trim().split("\n")
        var containers = []
        for (var i = 0; i < lines.length; i++) {
          var parts = lines[i].split("\t")
          if (parts.length >= 4) {
            containers.push({
              id: parts[0],
              name: parts[1],
              status: parts[2],
              image: parts[3],
              ports: parts[4] || ""
            })
          }
        }
        root._containers = containers
      }})
  }

  function _toggle(container: var): void {
    var isRunning = container.status.indexOf("Up") >= 0
    var cmd = isRunning ? ["docker", "stop", container.id] : ["docker", "start", container.id]
    ProcessPool.runTracked("Docker toggle", cmd, { id: "docker-toggle-" + container.id, callback: function(r) {
      root._pollContainers()
    }})
  }

  // ── Helpers ──────────────────────────────────────────────────────

  // ── Timers ───────────────────────────────────────────────────────
  Timer {
    id: pollTimer
    interval: root._pollInterval * 1000
    running: false
    repeat: true
    onTriggered: root._pollContainers()
  }

  // ── Lifecycle ────────────────────────────────────────────────────

  // ── UI components ────────────────────────────────────────────────
  property Component controlCenterComponent: Column {
    width: parent.width
    spacing: Theme.spaceSm

    SectionLabel { 
      label: "DOCKER" 
      visible: root._available 
    }

    Column {
      width: parent.width
      spacing: Theme.spaceXs
      visible: root._available 

      Repeater {
        model: root._containers

        delegate: Rectangle {
          required property var modelData
          width: parent.width
          height: 44
          radius: Theme.radiusSmall
          color: containerMouse.containsMouse ? Theme.controlBackgroundHover : Theme.controlBackground

          RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.spaceSm
            spacing: Theme.spaceSm

            Rectangle {
              width: 6; height: 6
              radius: Theme.radiusSmall
              color: modelData.status.indexOf("Up") >= 0 ? Theme.success : Theme.textDisabled
              Layout.alignment: Qt.AlignVCenter
            }

            Column {
              Layout.fillWidth: true
              spacing: Theme.space2

              Text {
                width: parent.width
                text: modelData.name
                color: Theme.textPrimary
                font.pixelSize: Theme.fontSizeCaption
                font.family: Theme.fontFamilyMono
                font.bold: true
                elide: Text.ElideRight
              }

              Text {
                width: parent.width
                text: modelData.image.split("/").pop()
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSizeMicro
                font.family: Theme.fontFamilyMono
                font.letterSpacing: 0.04
                elide: Text.ElideRight
              }
            }

            Text {
              text: modelData.status.indexOf("Up") >= 0 ? "STOP" : "START"
              color: modelData.status.indexOf("Up") >= 0 ? Theme.warning : Theme.success
              font.pixelSize: Theme.fontSizeMicro
              font.family: Theme.fontFamilyMono
              font.letterSpacing: 0.04
              Layout.alignment: Qt.AlignVCenter
            }
          }

          MouseArea {
            id: containerMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root._toggle(modelData)
          }
        }
      }

      Text {
        text: root._containers.length === 0 ? "NO CONTAINERS" : ""
        color: Theme.textDisabled
        font.pixelSize: Theme.fontSizeCaption
        font.family: Theme.fontFamilyMono
        font.letterSpacing: 0.06
        visible: root._containers.length === 0
        anchors.horizontalCenter: parent.horizontalCenter
      }
    }

    ToolUnavailable {
      visible: !root._available
      toolName: "Docker"
      toolPackage: "docker"
    }
  }
}
