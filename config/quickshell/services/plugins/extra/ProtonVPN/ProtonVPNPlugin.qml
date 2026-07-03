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
  pluginId: "protonvpn"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "ProtonVPN",
    description: "ProtonVPN secure core",
    icon: "shield",
    dependencies: [{ bin: "protonvpn", install: "yay -S --noconfirm protonvpn" }],
    locations: ["connectivity", "controlcenter_toggle"],
    settings: [
      { key: "killSwitch", label: "KILL SWITCH", type: "toggle", default: false, shared: true },
      { key: "secureCore", label: "SECURE CORE", type: "toggle", default: false, shared: true }
    ],
    controlCenterToggle: {
      icon: "shield",
      label: "PROTONVPN",
      visible: root._available,
      plugin: root,
      activeKey: "_connected",
      actionId: "pvpn-connect",
      toggle: function() { root._connected ? root.disconnect() : root.connect() }
    }
  })

  // ── Public state ─────────────────────────────────────────────────

  // ── Internal state ───────────────────────────────────────────────
  property string _status: ""
  property string _server: ""
  property string _load: ""
  property string _protocol: ""
  property bool _connected: _status === "Connected"
  property bool _available: false
  property bool connecting: false
  property int _seq: 0
  property bool isActiveToggle: _connected
  property real _loadValue: parseFloat(root._load) / 100 || 0

  // ── Signal handlers ──────────────────────────────────────────────

  // ── Public API ───────────────────────────────────────────────────
  function _refreshStatus(seq: int): void {
    ProcessPool.runTracked("ProtonVPN status", ["protonvpn", "status"], { id: "pvpn-status", callback: function(r) {
      if (seq !== root._seq) return
      root._parseStatus(r.stdout)
    }})
  }

  function _parseStatus(raw: string): void {
    root._status = ""
    root._server = ""
    root._load = ""
    root._protocol = ""
    var lines = raw.split("\n")
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim()
      if (line.indexOf("Status:") === 0) root._status = line.substring(7).trim()
      else if (line.indexOf("Server:") === 0) root._server = line.substring(7).trim()
      else if (line.indexOf("Load:") === 0) root._load = line.substring(5).trim()
      else if (line.indexOf("Protocol:") === 0) root._protocol = line.substring(9).trim()
    }
  }

  function connect(): void {
    root._seq++
    var seq = root._seq
    root.connecting = true
    ProcessPool.runTracked("ProtonVPN connect", ["protonvpn", "connect"], { id: "pvpn-connect", callback: function(r) {
      if (seq !== root._seq) { root.connecting = false; return }
      root.connecting = false
      if (r.exitCode !== 0) root._status = ""
      else root._refreshStatus(seq)
    }})
  }
  function disconnect(): void {
    root._seq++
    var seq = root._seq
    root.connecting = true
    ProcessPool.runTracked("ProtonVPN disconnect", ["protonvpn", "disconnect"], { id: "pvpn-disconnect", callback: function(r) {
      if (seq !== root._seq) { root.connecting = false; return }
      root.connecting = false
      if (r.exitCode !== 0) root._status = "Connected"
      else root._refreshStatus(seq)
    }})
  }
  function refresh(): void { _refreshStatus(root._seq) }

  // ── Helpers ──────────────────────────────────────────────────────

  // ── Timers ───────────────────────────────────────────────────────

  // ── Lifecycle ────────────────────────────────────────────────────
  Component.onCompleted: {
    ProcessPool.runTracked("ProtonVPN check available", "command -v protonvpn >/dev/null 2>&1 && echo AVAILABLE || echo MISSING", { id: "pvpn-available", shell: true, callback: function(r) {
      root._available = r.stdout.trim() === "AVAILABLE"
      if (root._available) root.refresh()
    }})
  }

  // ── UI components ────────────────────────────────────────────────
  property Component connectivityComponent: Column {
    width: parent.width
    spacing: Theme.spaceSm

    // ── Available UI ────────────────────────────────────────
    Column {
      width: parent.width
      spacing: Theme.spaceSm
      visible: root._available

      SectionLabel { label: "PROTONVPN" }

      Card {
        width: parent.width

        Column {
          width: parent.width
          spacing: Theme.spaceMd

          // ── Status Header ─────────────────────────────────
          RowLayout {
            width: parent.width
            spacing: Theme.spaceSm

            Rectangle {
              width: 8; height: 8
              radius: Theme.radiusSmall
              color: root._connected ? Theme.success : Theme.textDisabled
              Layout.alignment: Qt.AlignVCenter

              Behavior on color { enabled: Theme.animationsEnabled; ColorAnimation { duration: Theme.animationNormal } }
            }

            Column {
              Layout.fillWidth: true
              spacing: Theme.spaceXxs

              Text {
                text: root.connecting ? "CONNECTING..." : root._connected ? "CONNECTED" : "DISCONNECTED"
                color: root._connected ? Theme.success : Theme.textDisabled
                font.pixelSize: Theme.fontSizeBody
                font.family: Theme.fontFamilyMono
                font.weight: Font.Bold
                font.letterSpacing: 0.06
              }

              Text {
                width: parent.width
                text: root._connected
                  ? (root._server || "Connected") + (root._protocol ? "  " + root._protocol.toUpperCase() : "")
                  : "Ready to connect"
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSizeCaption
                font.family: Theme.fontFamilyMono
                elide: Text.ElideRight
                visible: !root.connecting
              }
            }

            Spinner {
              visible: root.connecting
              spinnerSize: 16
              spinnerColor: Theme.accent
            }

            Button {
              size: "sm"
              text: root._connected ? "STOP" : "CONNECT"
              variant: !root._connected && !root.connecting ? "accent" : "default"
              bgColor: "transparent"
              bgHoverColor: Theme.controlBackgroundHover
              enabled: !root.connecting
              onClicked: root._connected ? root.disconnect() : root.connect()
            }

            Button { shape: "circle";
              icon: "refresh"
              size: 26
              iconSize: 10
              onClicked: root.refresh()
            }
          }

          // ── Connected Details ─────────────────────────────
          Column {
            width: parent.width
            spacing: Theme.spaceSm
            visible: root._connected && !root.connecting

            Divider {}

            GridLayout {
              width: parent.width
              columns: 2
              columnSpacing: Theme.spaceSm
              rowSpacing: Theme.spaceSm

              Column { Layout.fillWidth: true; spacing: Theme.spaceXxs
                Text { text: "PROTOCOL"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; font.letterSpacing: 0.08 }
                Text { text: root._protocol ? root._protocol.toUpperCase() : "---"; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeLabel; font.family: Theme.fontFamilyMono }
              }
              Column { Layout.fillWidth: true; spacing: Theme.spaceXxs
                Text { text: "SERVER"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; font.letterSpacing: 0.08 }
                Text { text: root._server || "---"; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeLabel; font.family: Theme.fontFamilyMono; elide: Text.ElideRight; width: parent.width }
              }
            }
          }

          // ── Server Load ───────────────────────────────────
          Column {
            width: parent.width
            spacing: Theme.spaceSm
            visible: root._connected && root._load !== "" && !root.connecting

            Divider {}

            Column {
              width: parent.width
              spacing: Theme.spaceSm

              RowLayout {
                width: parent.width

                Text { text: "LOAD"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; font.letterSpacing: 0.08; Layout.fillWidth: true }
                Text { text: root._load; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeLabel; font.family: Theme.fontFamilyMono }
              }

              ProgressBar {
                width: parent.width
                value: root._loadValue
                barColor: root._loadValue > 0.8 ? Theme.error : root._loadValue > 0.6 ? Theme.warning : Theme.accent
              }
            }
          }
        }
      }
    }

    // ── Not Available ───────────────────────────────────────
    Column {
      width: parent.width
      spacing: Theme.spaceSm
      visible: !root._available

      SectionLabel { label: "PROTONVPN" }

      ToolUnavailable {
        visible: !root._available
        toolName: "ProtonVPN"
        toolPackage: "protonvpn"
      }
    }
  }
}
