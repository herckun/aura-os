pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"
import "../"

Singleton {
  id: svc

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC STATE
  // ═══════════════════════════════════════════════════════════════
  property bool online: false
  property string primarySsid: ""
  property int signalStrength: 0
  property bool ethernetConnected: false
  property bool hasEthernet: false
  property string ethernetDevice: ""
  property string ethernetConnection: ""
  property var wiredConnections: []
  property var vpnConnections: []
  property bool wifiEnabled: false
  property bool hasWifi: false
  property var availableNetworks: []
  property var savedWifiNetworks: []
  property bool scanning: false
  property bool connecting: false
  property string pendingConnectSsid: ""
  property string lastSsid: ""
  property string lastWiredName: ""
  property string lastConnectionType: ""
  property string lastError: ""

  property bool liveStatsEnabled: false
  property real downRate: -1
  property real upRate: -1
  property int pingMs: -1

  signal networkConnected(string ssid)
  signal networkFailed(string msg)
  signal passwordRequired(string ssid, bool savedFailed)

  // ═══════════════════════════════════════════════════════════════
  //  INTERNAL STATE
  // ═══════════════════════════════════════════════════════════════
  property bool _autoConnectAttempted: false
  property real _lastRxBytes: -1
  property real _lastTxBytes: -1
  property double _lastStatsAt: 0

  readonly property int _basePollInterval: 5000
  readonly property int _baseRescanInterval: 1500
  readonly property int _baseAutoConnectInterval: 2000

  readonly property int _pollInterval: PerformanceService.scaleInterval(_basePollInterval)
  readonly property int _rescanInterval: PerformanceService.scaleInterval(_baseRescanInterval)
  readonly property int _autoConnectInterval: PerformanceService.scaleInterval(_baseAutoConnectInterval)

  // ═══════════════════════════════════════════════════════════════
  //  TIMERS
  // ═══════════════════════════════════════════════════════════════
  Timer {
    id: pollTimer
    interval: svc._pollInterval
    running: true
    repeat: true
    onTriggered: svc.poll()
  }

  Timer {
    id: rescanTimer
    interval: svc._rescanInterval
    repeat: false
    onTriggered: if (svc.wifiEnabled) svc.scan()
  }

  Timer {
    id: autoConnectTimer
    interval: svc._autoConnectInterval
    repeat: false
    onTriggered: svc._maybeAutoConnect()
  }

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════
  onLiveStatsEnabledChanged: {
    if (!liveStatsEnabled) {
      downRate = -1
      upRate = -1
      pingMs = -1
      _lastRxBytes = -1
      _lastTxBytes = -1
    }
  }

  property Timer _liveStatsTimer: Timer {
    interval: PerformanceService.scaleInterval(2000)
    running: svc.liveStatsEnabled
    repeat: true
    triggeredOnStart: true
    onTriggered: svc._sampleLiveStats()
  }

  function _sampleLiveStats(): void {
    ProcessPool.runTracked("Net live stats", ["sh", "-c",
      "cat /proc/net/dev; echo '===PING==='; ping -n -c1 -W1 1.1.1.1 2>/dev/null | grep -oE 'time=[0-9.]+' | head -1"], {
      id: "net-live-stats",
      callback: function(r) {
        var parts = (r.stdout || "").split("===PING===")
        var rx = 0
        var tx = 0
        var lines = (parts[0] || "").split("\n")
        for (var i = 0; i < lines.length; i++) {
          var sep = lines[i].indexOf(":")
          if (sep < 0) continue
          var dev = lines[i].substring(0, sep).trim()
          if (dev === "lo") continue
          var fields = lines[i].substring(sep + 1).trim().split(/\s+/)
          if (fields.length < 9) continue
          rx += parseInt(fields[0]) || 0
          tx += parseInt(fields[8]) || 0
        }
        var now = Date.now()
        if (svc._lastRxBytes >= 0 && now > svc._lastStatsAt) {
          var dt = (now - svc._lastStatsAt) / 1000
          svc.downRate = Math.max(0, (rx - svc._lastRxBytes) / dt)
          svc.upRate = Math.max(0, (tx - svc._lastTxBytes) / dt)
        }
        svc._lastRxBytes = rx
        svc._lastTxBytes = tx
        svc._lastStatsAt = now
        var m = (parts[1] || "").match(/time=([0-9.]+)/)
        svc.pingMs = m ? Math.round(parseFloat(m[1])) : -1
      }
    })
  }

  property Timer _restoreTimer: Timer {
    interval: 400
    repeat: false
    running: true
    onTriggered: {
      svc.lastSsid = Store.network.lastSsid
      svc.lastWiredName = Store.network.lastWiredName
      svc.lastConnectionType = Store.network.lastConnectionType
      if (svc.lastSsid !== "" || svc.lastWiredName !== "") autoConnectTimer.restart()
    }
  }

  Component.onCompleted: {
    svc.poll()
  }

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════
  function _emitUpdated(): void {
  }

  function _maybeAutoConnect(): void {
    if (_autoConnectAttempted || online) return
    _autoConnectAttempted = true
    
    if (lastConnectionType === "wired" && lastWiredName !== "") {
      svc.autoConnectLastWired()
      return
    }
    
    if (lastConnectionType === "wifi" && wifiEnabled && lastSsid !== "") {
      svc.autoConnectLast()
      return
    }
    
    if (lastWiredName !== "") {
      svc.autoConnectLastWired()
    } else if (wifiEnabled && lastSsid !== "") {
      svc.autoConnectLast()
    }
  }

  function _saveLastSsid(ssid: string): void {
    if (ssid === "" || svc.lastSsid === ssid) return
    svc.lastSsid = ssid
    svc.lastConnectionType = "wifi"
    Store.network.lastSsid = ssid
    Store.network.lastConnectionType = "wifi"
  }

  function _saveLastWired(name: string): void {
    if (name === "" || svc.lastWiredName === name) return
    svc.lastWiredName = name
    svc.lastConnectionType = "wired"
    Store.network.lastWiredName = name
    Store.network.lastConnectionType = "wired"
  }

  function _cleanError(text: string): string {
    var t = (text || "").trim()
    if (t === "") return ""
    var lines = t.split("\n")
    var last = lines[lines.length - 1].trim()
    last = last.replace(/^Error:\s*/i, "")
    return last
  }

  function _isSecretsError(msg: string): bool {
    return /secrets were required|no secrets|passwords or encryption keys are required|authentication required/i.test(msg)
  }

  function isKnownNetwork(ssid: string): bool {
    return savedWifiNetworks.indexOf(ssid) !== -1
  }

  function _shellQuote(s: string): string {
    return "'" + s.replace(/'/g, "'\\''") + "'"
  }

  function _onConnectResult(code: int, output: string, isAuto: bool, ssid: string, promptOnSecrets: bool): void {
    svc.connecting = false
    svc.pendingConnectSsid = ""
    if (code !== 0) {
      var msg = svc._cleanError(output) || "Connection failed"
      if (promptOnSecrets && svc._isSecretsError(msg)) {
        svc.lastError = ""
        svc._emitUpdated()
        svc.passwordRequired(ssid, svc.isKnownNetwork(ssid))
        return
      }
      svc.lastError = msg
      svc.networkFailed(msg)
      svc._emitUpdated()
      if (!isAuto) {
        NotificationService.systemNotify("WI-FI", ssid + ": " + msg, 2)
      }
      return
    }

    svc.lastError = ""
    svc._saveLastSsid(ssid)
    svc._autoConnectAttempted = true
    svc.networkConnected(ssid)
    svc._emitUpdated()
    NotificationService.systemNotify("WI-FI", ssid + " connected", 1)
    svc.poll()
  }

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════
  function poll(): void {
    if (ProcessPool.isBusy("network-status")) return
    ProcessPool.runTracked(
      "Network status",
      "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null; echo '===RADIO==='; nmcli -t radio wifi 2>/dev/null; echo '===WIRED==='; nmcli -t -f NAME,TYPE,DEVICE connection show 2>/dev/null",
      {
        id: "network-status",
        shell: true,
        callback: function(r) {
          var text = r.stdout || ""
          var radioSep = "===RADIO==="
          var wiredSep = "===WIRED==="
          var radioIdx = text.indexOf(radioSep)
          var wiredIdx = text.indexOf(wiredSep)

          var statusText = radioIdx >= 0 ? text.substring(0, radioIdx).trim() : text
          var radioText = radioIdx >= 0 && wiredIdx >= 0 ? text.substring(radioIdx + radioSep.length, wiredIdx).trim() : ""
          var wiredText = wiredIdx >= 0 ? text.substring(wiredIdx + wiredSep.length).trim() : ""

          svc.parseStatus(statusText)
          var hasWifiDev = false
          var devLines = statusText.split("\n")
          for (var d = 0; d < devLines.length; d++) {
            if (devLines[d].split(":")[1] === "wifi") {
              hasWifiDev = true
              break
            }
          }
          svc.hasWifi = hasWifiDev
          svc.wifiEnabled = hasWifiDev && radioText === "enabled"

          var conns = []
          var savedWifi = []
          var vpns = []
          if (wiredText) {
            var lines = wiredText.split("\n")
            for (var i = 0; i < lines.length; i++) {
              var parts = lines[i].split(":")
              if (parts.length < 2) continue
              if (parts[1] === "802-3-ethernet") {
                conns.push({
                  name: parts[0],
                  device: parts.length > 2 ? parts[2] : "",
                  active: parts.length > 2 && parts[2] !== ""
                })
              } else if (parts[1] === "802-11-wireless") {
                savedWifi.push(parts[0])
              } else if (parts[1] === "vpn" || parts[1] === "wireguard") {
                vpns.push({
                  name: parts[0],
                  type: parts[1],
                  active: parts.length > 2 && parts[2] !== ""
                })
              }
            }
          }
          svc.wiredConnections = conns
          svc.savedWifiNetworks = savedWifi
          svc.vpnConnections = vpns

          if (svc.primarySsid !== "") {
            ProcessPool.runTracked(
              "Network signal",
              ["nmcli", "-t", "-f", "SSID,SIGNAL", "device", "wifi", "list", "--rescan", "no"],
              {
                id: "network-signal",
                callback: function(r2) {
                  if (r2.exitCode === 0) svc.parseSignal(r2.stdout)
                  else svc.signalStrength = 0
                  svc._emitUpdated()
                }
              }
            )
          } else {
            svc.signalStrength = 0
            svc._emitUpdated()
          }

          if (svc.wifiEnabled && !svc.online && !svc._autoConnectAttempted) {
            svc._maybeAutoConnect()
          }
        }
      }
    )
  }

  function scan(): void {
    if (scanning || !wifiEnabled) return
    scanning = true
    lastError = ""
    ProcessPool.runTracked(
      "WiFi scan",
      ["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "yes"],
      {
        id: "wifi-scan",
        callback: function(r) {
          if (r.exitCode !== 0) {
            svc.lastError = svc._cleanError(r.stderr || r.stdout) || "Scan failed"
            svc.availableNetworks = []
          } else {
            svc.parseNetworks(r.stdout)
          }
          svc.scanning = false
          svc._emitUpdated()
        }
      }
    )
  }

  function toggleWifi(): void {
    var newState = !wifiEnabled
    wifiEnabled = newState
    lastError = ""
    ProcessPool.runQueued(
      "WiFi toggle",
      ["nmcli", "radio", "wifi", newState ? "on" : "off"],
      {
        id: "wifi-toggle",
        silent: true,
        callback: function(r) {
          if (r.exitCode !== 0) {
            wifiEnabled = !newState
            lastError = svc._cleanError(r.stderr || r.stdout) || "Wi-Fi toggle failed"
            return
          }
          if (newState) {
            rescanTimer.restart()
            autoConnectTimer.restart()
          } else {
            availableNetworks = []
            primarySsid = ""
            pendingConnectSsid = ""
            signalStrength = 0
            online = ethernetConnected
          }
          svc.poll()
        }
      }
    )
  }

  function connectNetwork(ssid: string, secured: bool): void {
    if (connecting) return
    if (secured && !isKnownNetwork(ssid)) {
      passwordRequired(ssid, false)
      return
    }
    lastError = ""
    connecting = true
    pendingConnectSsid = ssid
    var cmd = isKnownNetwork(ssid)
      ? ["nmcli", "connection", "up", ssid]
      : ["nmcli", "dev", "wifi", "connect", ssid]
    var capturedSsid = ssid
    ProcessPool.runQueued(
      "WiFi connect",
      cmd,
      {
        id: "wifi-connect",
        silent: true,
        callback: function(r) {
          svc._onConnectResult(r.exitCode, r.stderr || r.stdout, false, capturedSsid, true)
        }
      }
    )
  }

  function submitPassword(ssid: string, password: string): void {
    lastError = ""
    connecting = true
    pendingConnectSsid = ssid
    var capturedSsid = ssid
    var q = svc._shellQuote
    var cmd = isKnownNetwork(ssid)
      ? "nmcli connection delete " + q(ssid) + " >/dev/null 2>&1; nmcli dev wifi connect " + q(ssid) + " password " + q(password)
      : "nmcli dev wifi connect " + q(ssid) + " password " + q(password)
    ProcessPool.runQueued(
      "WiFi connect",
      cmd,
      {
        id: "wifi-connect",
        shell: true,
        silent: true,
        callback: function(r) {
          svc._onConnectResult(r.exitCode, r.stderr || r.stdout, false, capturedSsid, false)
        }
      }
    )
  }

  function autoConnectLast(): void {
    if (lastSsid === "" || connecting) return
    connecting = true
    lastError = ""
    pendingConnectSsid = lastSsid
    var capturedSsid = lastSsid
    ProcessPool.runQueued(
      "WiFi auto-connect",
      ["nmcli", "connection", "up", lastSsid],
      {
        id: "wifi-auto",
        silent: true,
        callback: function(r) {
          svc._onConnectResult(r.exitCode, r.stderr || r.stdout, true, capturedSsid, false)
        }
      }
    )
  }

  function autoConnectLastWired(): void {
    if (lastWiredName === "" || connecting) return
    connecting = true
    lastError = ""
    ProcessPool.runQueued(
      "Wired auto-connect",
      ["nmcli", "connection", "up", lastWiredName],
      {
        id: "wired-auto",
        silent: true,
        callback: function(r) {
          connecting = false
          if (r.exitCode !== 0) {
            lastError = svc._cleanError(r.stderr || r.stdout) || "Wired auto-connect failed"
          } else {
            lastError = ""
            NotificationService.systemNotify("WIRED", lastWiredName + " connected", 1)
            svc.poll()
          }
          svc._emitUpdated()
        }
      }
    )
  }

  function disconnectNetwork(): void {
    if (primarySsid === "") return
    lastError = ""
    pendingConnectSsid = ""
    ProcessPool.runQueued(
      "WiFi disconnect",
      ["nmcli", "connection", "down", primarySsid],
      {
        id: "wifi-disconnect",
        silent: true,
        callback: function(r) {
          if (r.exitCode !== 0) {
            svc.lastError = svc._cleanError(r.stderr || r.stdout) || "Disconnect failed"
          } else {
            svc.lastError = ""
            svc.primarySsid = ""
            svc.signalStrength = 0
            svc.online = svc.ethernetConnected
            svc._emitUpdated()
            NotificationService.systemNotify("WI-FI", "Disconnected", 1)
            svc.poll()
          }
        }
      }
    )
  }

  function activateConnection(name: string): void {
    lastError = ""
    ProcessPool.runQueued(
      "Wired connect",
      ["nmcli", "connection", "up", name],
      {
        id: "wired-up",
        silent: true,
        callback: function(r) {
          if (r.exitCode !== 0) {
            svc.lastError = svc._cleanError(r.stderr || r.stdout) || "Activation failed"
          } else {
            svc.lastError = ""
            svc._saveLastWired(name)
            svc.poll()
            NotificationService.systemNotify("WIRED", name + " connected", 1)
          }
        }
      }
    )
  }

  function deactivateDevice(ifname: string): void {
    lastError = ""
    ProcessPool.runQueued(
      "Wired disconnect",
      ["nmcli", "device", "disconnect", ifname],
      {
        id: "wired-down",
        silent: true,
        callback: function(r) {
          if (r.exitCode !== 0) {
            svc.lastError = svc._cleanError(r.stderr || r.stdout) || "Deactivation failed"
          } else {
            svc.lastError = ""
            svc.poll()
            NotificationService.systemNotify("WIRED", ifname + " disconnected", 1)
          }
        }
      }
    )
  }

  function forgetNetwork(ssid: string): void {
    lastError = ""
    ProcessPool.runQueued(
      "Forget network",
      ["nmcli", "connection", "delete", ssid],
      {
        id: "wifi-forget",
        silent: true,
        callback: function(r) {
          if (r.exitCode !== 0) {
            svc.lastError = svc._cleanError(r.stderr || r.stdout) || "Forget failed"
          } else {
            svc.lastError = ""
            if (svc.lastSsid === ssid) {
              svc.lastSsid = ""
              Store.network.lastSsid = ""
            }
            var idx = svc.savedWifiNetworks.indexOf(ssid)
            if (idx !== -1) {
              var saved = svc.savedWifiNetworks.slice()
              saved.splice(idx, 1)
              svc.savedWifiNetworks = saved
            }
            NotificationService.systemNotify("WI-FI", ssid + " forgotten", 1)
            svc.poll()
          }
        }
      }
    )
  }

  function parseStatus(output: string): void {
    var lines = output.trim().split("\n")
    var hasEth = false
    var hasWifiSsid = ""
    var ethDev = ""
    var ethConn = ""
    var foundEth = false

    for (var i = 0; i < lines.length; i++) {
      var parts = lines[i].split(":")
      if (parts.length < 3) continue
      var device = parts[0]
      var type = parts[1]
      var state = parts[2]
      var connection = parts.length > 3 ? parts.slice(3).join(":") : ""

      if (type === "ethernet") {
        foundEth = true
        if (state === "connected") {
          hasEth = true
          ethDev = device
          ethConn = connection
        }
      }
      if (state !== "connected") continue
      if (type === "wifi" && connection !== "") hasWifiSsid = connection
    }

    hasEthernet = foundEth
    ethernetConnected = hasEth
    ethernetDevice = ethDev
    ethernetConnection = ethConn
    primarySsid = hasWifiSsid
    online = hasEth || hasWifiSsid !== ""
    if (hasWifiSsid !== "") {
      svc._saveLastSsid(hasWifiSsid)
      svc._autoConnectAttempted = true
    } else if (hasEth && ethConn !== "") {
      svc._saveLastWired(ethConn)
      svc._autoConnectAttempted = true
    } else if (!online) {
      svc._autoConnectAttempted = false
    }
  }

  function parseSignal(output: string): void {
    var lines = output.trim().split("\n")
    for (var i = 0; i < lines.length; i++) {
      var parts = lines[i].split(":")
      if (parts.length < 2) continue
      if (parts[0] === primarySsid) {
        signalStrength = parseInt(parts[1]) || 0
        return
      }
    }
    signalStrength = 0
  }

  function parseNetworks(output: string): void {
    var lines = output.trim().split("\n")
    var seen = {}
    var networks = []
    for (var i = 0; i < lines.length; i++) {
      var parts = lines[i].split(":")
      if (parts.length < 3) continue
      var ssid = parts[0]
      var signal = parseInt(parts[1]) || 0
      var security = parts[2] || ""
      if (ssid === "" || seen[ssid]) continue
      seen[ssid] = true
      networks.push({
        ssid: ssid,
        signal: signal,
        security: security,
        secured: security !== ""
      })
    }
    networks.sort(function(a, b) { return b.signal - a.signal })
    availableNetworks = networks
  }
}
