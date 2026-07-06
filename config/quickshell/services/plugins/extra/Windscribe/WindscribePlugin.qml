pragma ComponentBehavior: Bound
import QtQuick
import "../../../../core"
import "../../../"

BasePlugin {
  id: root
  visible: false

  // ── Manifest ────────────────────────────────────────────────────
  pluginId: "windscribe"
  manifest: ({
    author: "herckun",
    version: "1.1",
    shellVersion: "2.0",
    name: "Windscribe",
    description: "Windscribe provider for the VPN toggle",
    icon: "shield",
    dependencies: [{ bin: "windscribe-cli", install: "yay -S --noconfirm windscribe-cli" }],
    locations: [],
    settings: []
  })

  // ── Public state ─────────────────────────────────────────────────
  readonly property var vpnProvider: ({
    id: "windscribe",
    label: "Windscribe",
    icon: "shield",
    connect: function() { root.connect() },
    disconnect: function() { root.disconnect() }
  })

  // ── Internal state ───────────────────────────────────────────────
  property string _loginState: ""
  property string _connectState: ""
  property string _externalIp: ""
  property string _location: ""
  property bool _connected: _connectState === "Connected"
  property bool _available: false
  property bool connecting: false
  property int _seq: 0

  // ── Signal handlers ──────────────────────────────────────────────
  on_AvailableChanged: root._pushVpnState()
  on_ConnectedChanged: root._pushVpnState()
  onConnectingChanged: root._pushVpnState()
  on_LocationChanged: root._pushVpnState()

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
    root._externalIp = ""
    root._location = ""
    var lines = raw.split("\n")
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim()
      if (line.indexOf("Login state:") === 0) root._loginState = line.substring(12).trim()
      else if (line.indexOf("Connect state:") === 0) root._connectState = line.substring(14).trim()
      else if (line.indexOf("External IP:") === 0) root._externalIp = line.substring(12).trim()
      else if (line.indexOf("Location:") === 0) root._location = line.substring(9).trim()
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
  function _pushVpnState(): void {
    VpnService.submit("windscribe", {
      available: root._available,
      connected: root._connected,
      connecting: root.connecting,
      detail: root._location + (root._externalIp ? "  " + root._externalIp : "")
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
    ProcessPool.runTracked("Windscribe check available", "command -v windscribe-cli >/dev/null 2>&1 && echo AVAILABLE || echo MISSING", { id: "ws-available", shell: true, callback: function(r) {
      root._available = r.stdout.trim() === "AVAILABLE"
      if (root._available) root.refresh()
    }})
  }
}
