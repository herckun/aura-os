pragma ComponentBehavior: Bound
import QtQuick
import "../../../../core"
import "../../../"

BasePlugin {
  id: root
  visible: false

  // ── Manifest ────────────────────────────────────────────────────
  pluginId: "protonvpn"
  manifest: ({
    author: "herckun",
    version: "1.1",
    shellVersion: "2.0",
    name: "ProtonVPN",
    description: "ProtonVPN provider for the VPN toggle",
    icon: "shield",
    dependencies: [{ bin: "protonvpn", install: "yay -S --noconfirm protonvpn" }],
    locations: [],
    settings: []
  })

  // ── Public state ─────────────────────────────────────────────────
  readonly property var vpnProvider: ({
    id: "protonvpn",
    label: "ProtonVPN",
    icon: "shield",
    connect: function() { root.connect() },
    disconnect: function() { root.disconnect() }
  })

  // ── Internal state ───────────────────────────────────────────────
  property string _status: ""
  property string _server: ""
  property string _protocol: ""
  property bool _connected: _status === "Connected"
  property bool _available: false
  property bool connecting: false
  property int _seq: 0

  // ── Signal handlers ──────────────────────────────────────────────
  on_AvailableChanged: root._pushVpnState()
  on_ConnectedChanged: root._pushVpnState()
  onConnectingChanged: root._pushVpnState()
  on_ServerChanged: root._pushVpnState()

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
    root._protocol = ""
    var lines = raw.split("\n")
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim()
      if (line.indexOf("Status:") === 0) root._status = line.substring(7).trim()
      else if (line.indexOf("Server:") === 0) root._server = line.substring(7).trim()
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
  function _pushVpnState(): void {
    VpnService.submit("protonvpn", {
      available: root._available,
      connected: root._connected,
      connecting: root.connecting,
      detail: root._server + (root._protocol ? "  " + root._protocol.toUpperCase() : "")
    })
  }

  // ── Timers ───────────────────────────────────────────────────────
  property Timer _pollTimer: Timer {
    interval: PerformanceService.scaleInterval(30000)
    repeat: true
    running: root._available && !root.connecting
    onTriggered: root.refresh()
  }

  // ── Lifecycle ────────────────────────────────────────────────────
  function stopAllActivity(): void {
    root._pollTimer.running = false
  }

  Component.onCompleted: {
    ProcessPool.runTracked("ProtonVPN check available", "command -v protonvpn >/dev/null 2>&1 && echo AVAILABLE || echo MISSING", { id: "pvpn-available", shell: true, callback: function(r) {
      root._available = r.stdout.trim() === "AVAILABLE"
      if (root._available) root.refresh()
    }})
  }
}
