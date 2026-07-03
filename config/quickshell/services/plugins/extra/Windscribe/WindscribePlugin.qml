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
  pluginId: "windscribe"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Windscribe",
    description: "Windscribe VPN client",
    icon: "shield",
    locations: ["connectivity", "controlcenter_toggle"],
    settings: [],
    controlCenterToggle: {
      icon: "shield",
      label: "WINDSCRIBE",
      visible: root._available,
      plugin: root,
      activeKey: "_connected",
      actionId: "ws-connect",
      toggle: function() { root._connected ? root.disconnect() : root.connect() }
    }
  })

  // ── Public state ─────────────────────────────────────────────────

  // ── Internal state ───────────────────────────────────────────────
  property string _loginState: ""
  property string _connectState: ""
  property string _firewall: ""
  property string _dataUsage: ""
  property string _externalIp: ""
  property string _location: ""
  property string _updateAvailable: ""
  property bool _connected: _connectState === "Connected"
  property bool _available: false
  property bool connecting: false
  property int _seq: 0
  property bool isActiveToggle: _connected

  // ── Signal handlers ──────────────────────────────────────────────

  // ── Public API ───────────────────────────────────────────────────
  function _refreshStatus(seq: int): void {
    ProcessPool.runTracked("Windscribe status", ["windscribe-cli", "status"], { id: "ws-status", callback: function(r) {
      if (seq !== root._seq) return
      root._parseStatus(r.stdout)
    }})
  }

  function _parseStatus(raw: string): void {
    root._connectState = ""
    root._loginState = ""
    root._firewall = ""
    root._dataUsage = ""
    root._externalIp = ""
    root._location = ""
    root._updateAvailable = ""
    var lines = raw.split("\n")
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim()
      if (line.indexOf("Login state:") === 0) root._loginState = line.substring(12).trim()
      else if (line.indexOf("Connect state:") === 0) root._connectState = line.substring(14).trim()
      else if (line.indexOf("Firewall state:") === 0) root._firewall = line.substring(15).trim()
      else if (line.indexOf("Data usage:") === 0) root._dataUsage = line.substring(11).trim()
      else if (line.indexOf("External IP:") === 0) root._externalIp = line.substring(12).trim()
      else if (line.indexOf("Location:") === 0) root._location = line.substring(9).trim()
      else if (line.indexOf("Update available:") === 0) root._updateAvailable = line.substring(17).trim()
    }
  }

  function connect(): void {
    root._seq++
    var seq = root._seq
    root.connecting = true
    ProcessPool.runTracked("Windscribe connect", ["windscribe-cli", "connect"], { id: "ws-connect", callback: function(r) {
      if (seq !== root._seq) { root.connecting = false; return }
      root.connecting = false
      if (r.exitCode !== 0) root._connectState = ""
      else root._refreshStatus(seq)
    }})
  }
  function disconnect(): void {
    root._seq++
    var seq = root._seq
    root.connecting = true
    ProcessPool.runTracked("Windscribe disconnect", ["windscribe-cli", "disconnect"], { id: "ws-disconnect", callback: function(r) {
      if (seq !== root._seq) { root.connecting = false; return }
      root.connecting = false
      if (r.exitCode !== 0) root._connectState = "Connected"
      else root._refreshStatus(seq)
    }})
  }
  function refresh(): void { _refreshStatus(root._seq) }

  // ── Helpers ──────────────────────────────────────────────────────

  // ── Timers ───────────────────────────────────────────────────────

  // ── Lifecycle ────────────────────────────────────────────────────
  Component.onCompleted: {
    ProcessPool.runTracked("Windscribe check available", "command -v windscribe-cli >/dev/null 2>&1 && echo AVAILABLE || echo MISSING", { id: "ws-available", shell: true, callback: function(r) {
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

      SectionLabel { label: "WINDSCRIBE" }

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
                  ? (root._location || "Connected") + (root._externalIp ? "  " + root._externalIp : "")
                  : root._loginState === "Logged in" ? "Ready to connect" : root._loginState || "Not logged in"
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
                Text { text: "EXTERNAL IP"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; font.letterSpacing: 0.08 }
                Text { text: root._externalIp || "---"; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeLabel; font.family: Theme.fontFamilyMono }
              }
              Column { Layout.fillWidth: true; spacing: Theme.spaceXxs
                Text { text: "FIREWALL"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; font.letterSpacing: 0.08 }
                Text { text: root._firewall || "---"; color: root._firewall === "On" ? Theme.success : Theme.textPrimary; font.pixelSize: Theme.fontSizeLabel; font.family: Theme.fontFamilyMono }
              }
            }
          }

          // ── Disconnected Details ──────────────────────────
          Column {
            width: parent.width
            spacing: Theme.spaceSm
            visible: !root._connected && !root.connecting

            Divider {}

            GridLayout {
              width: parent.width
              columns: 2
              columnSpacing: Theme.spaceSm
              rowSpacing: Theme.spaceSm

              Column { Layout.fillWidth: true; spacing: Theme.spaceXxs
                Text { text: "LOGIN"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; font.letterSpacing: 0.08 }
                Text { text: root._loginState || "---"; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeLabel; font.family: Theme.fontFamilyMono }
              }
              Column { Layout.fillWidth: true; spacing: Theme.spaceXxs
                Text { text: "FIREWALL"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; font.letterSpacing: 0.08 }
                Text { text: root._firewall || "---"; color: root._firewall === "On" ? Theme.success : Theme.textPrimary; font.pixelSize: Theme.fontSizeLabel; font.family: Theme.fontFamilyMono }
              }
            }
          }

          // ── Data Usage ────────────────────────────────────
          Column {
            width: parent.width
            spacing: Theme.spaceSm
            visible: root._dataUsage !== "" && !root.connecting

            Divider {}

            Column {
              width: parent.width
              spacing: Theme.spaceSm

              Text { text: "DATA USAGE"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; font.letterSpacing: 0.08 }
              Text { text: root._dataUsage; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeLabel; font.family: Theme.fontFamilyMono }

              ProgressBar {
                width: parent.width
                value: {
                  var parts = root._dataUsage.split("/")
                  if (parts.length !== 2) return 0
                  var used = parseFloat(parts[0]) || 0
                  var limit = parseFloat(parts[1]) || 1
                  return Math.min(used / limit, 1)
                }
                barColor: {
                  var parts = root._dataUsage.split("/")
                  if (parts.length !== 2) return Theme.accent
                  var used = parseFloat(parts[0]) || 0
                  var limit = parseFloat(parts[1]) || 1
                  return (used / limit) > 0.9 ? Theme.error : Theme.accent
                }
              }
            }
          }

          // ── Update Available ──────────────────────────────
          RowLayout {
            width: parent.width
            spacing: Theme.spaceSm
            visible: root._updateAvailable !== "" && !root.connecting

            Badge {
              text: "UPDATE " + root._updateAvailable
              bgColor: Theme.warning
              textColor: Theme.background
              size: "sm"
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

      SectionLabel { label: "WINDSCRIBE" }

      ToolUnavailable {
        visible: !root._available
        toolName: "Windscribe"
        toolPackage: "windscribe-cli"
      }
    }
  }
}
