pragma Singleton
import QtQml
import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"

Singleton {
  id: svc

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC STATE
  // ═══════════════════════════════════════════════════════════════
  property bool enabled: false
  property bool hasBluetooth: false
  property var devices: ([])
  property var pairedDevices: ([])
  property bool scanning: false
  property string lastError: ""

  signal deviceConnected(string mac)
  signal deviceDisconnected(string mac)

  // ═══════════════════════════════════════════════════════════════
  //  INTERNAL STATE
  // ═══════════════════════════════════════════════════════════════
  property var _pollHandle: null
  property var _deviceInfo: ({})

  readonly property int _basePollInterval: 10000

  readonly property int _pollInterval: PerformanceService.scaleInterval(_basePollInterval)

  // ═══════════════════════════════════════════════════════════════
  //  TIMERS
  // ═══════════════════════════════════════════════════════════════
  Timer {
    interval: svc._pollInterval
    running: true
    repeat: true
    onTriggered: svc.poll()
  }

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════
  Component.onCompleted: {
    svc.poll()
  }

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════
  function toggle(): void {
    svc.setPower(!enabled)
  }

  function setPower(on: bool): void {
    if (enabled === on) return
    enabled = on
    ProcessPool.runQueued("BT power", ["rfkill", on ? "unblock" : "block", "bluetooth"], {
      id: "bt-toggle",
      silent: true,
      callback: function(r) {
        if (r.exitCode !== 0) enabled = !on
      }
    })
  }

  function scan(): void {
    if (!enabled || scanning) return
    scanning = true
    lastError = ""
    startScan()
  }

  function pair(mac: string): void {
    lastError = ""
    ProcessPool.runQueued("BT pair", ["bluetoothctl", "pair", mac], {
      id: "bt-pair",
      callback: function(r) {
        if (r.exitCode !== 0) lastError = "Pairing failed"
        poll()
      }
    })
  }

  function connectDevice(mac: string): void {
    lastError = ""
    ProcessPool.runQueued("BT connect", ["bluetoothctl", "connect", mac], {
      id: "bt-connect",
      callback: function(r) {
        if (r.exitCode !== 0) lastError = "Connection failed"
        else svc.deviceConnected(mac)
        poll()
      }
    })
  }

  function disconnectDevice(mac: string): void {
    lastError = ""
    ProcessPool.runQueued("BT disconnect", ["bluetoothctl", "disconnect", mac], {
      id: "bt-disconnect",
      callback: function(r) {
        if (r.exitCode !== 0) lastError = "Disconnect failed"
        else svc.deviceDisconnected(mac)
        poll()
      }
    })
  }

  function remove(mac: string): void {
    lastError = ""
    ProcessPool.runQueued("BT remove", ["bluetoothctl", "remove", mac], {
      id: "bt-remove",
      callback: function(r) {
        if (r.exitCode !== 0) lastError = "Remove failed"
        poll()
      }
    })
  }

  function poll(): void {
    if (_pollHandle && ProcessPool.isRunning(_pollHandle)) return
    _pollHandle = ProcessPool.runTracked("Bluetooth poll",
      "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo 'on' || echo 'off'; bluetoothctl devices 2>/dev/null",
      {
        id: "bt-poll",
        shell: true,
        callback: function(r) {
          _pollHandle = null
          if (r.exitCode !== 0) {
            return
          }
          var lines = r.stdout.trim().split("\n")
          svc.hasBluetooth = lines[0] === "on" || lines[0] === "off"
          svc.enabled = lines[0] === "on"
          var devs = []
          for (var i = 1; i < lines.length; i++) {
            var line = lines[i].trim()
            if (!line || !line.startsWith("Device ")) continue
            var rest = line.substring(7)
            var spaceIdx = rest.indexOf(" ")
            if (spaceIdx === -1) continue
            var mac = rest.substring(0, spaceIdx)
            var name = rest.substring(spaceIdx + 1)
            devs.push({ mac: mac, name: name || mac })
          }
          svc.devices = devs
          if (svc.enabled) {
            svc._deviceInfo = {}
            svc._queryDeviceInfo()
          } else {
            svc.pairedDevices = []
          }
        }
      })
  }

  function parseInfo(output: string): void {
    var lines = output.trim().split("\n")
    var mac = ""
    var paired = false
    var connected = false
    var name = ""
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim()
      if (line.startsWith("Device ")) {
        if (mac) _deviceInfo[mac] = { paired: paired, connected: connected, name: name }
        mac = line.substring(7).split(" ")[0]
        paired = false
        connected = false
        name = ""
      }
      if (line.includes("Paired: yes")) paired = true
      if (line.includes("Connected: yes")) connected = true
      if (line.startsWith("Name: ")) name = line.substring(6)
    }
    if (mac) _deviceInfo[mac] = { paired: paired, connected: connected, name: name }
    var pairedList = []
    for (var key in _deviceInfo) {
      if (_deviceInfo[key].paired) {
        pairedList.push({ mac: key, name: _deviceInfo[key].name || key, connected: _deviceInfo[key].connected })
      }
    }
    pairedDevices = pairedList
  }

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════
  function _queryDeviceInfo(): void {
    var snapshot = svc.devices.slice()
    if (snapshot.length === 0) return
    var macs = []
    for (var i = 0; i < snapshot.length; i++) macs.push(snapshot[i].mac)
    ProcessPool.runTracked("BT info batch", ["sh", "-c", "for m in " + macs.join(" ") + "; do bluetoothctl info $m 2>/dev/null; done"], {
      id: "bt-info-batch",
      callback: function(r) {
        if (r.exitCode === 0 && r.stdout) svc.parseInfo(r.stdout)
      }
    })
  }

  function setTimeout(callback: var, delay: int): void {
    var t = Qt.createQmlObject("import QtQuick; Timer { repeat: false }", svc, "dynamic_timer")
    t.interval = delay
    t.triggered.connect(function() { callback(); t.destroy() })
    t.start()
  }

  function startScan(): void {
    scanning = true
    ProcessPool.runTracked("BT scan on", ["bluetoothctl", "scan", "on"], {
      id: "bt-scan",
      callback: function(r) {
        if (r.exitCode !== 0) {
          svc.scanning = false
          return
        }
        setTimeout(function() {
          ProcessPool.runTracked("BT scan off", ["bluetoothctl", "scan", "off"], {
            id: "bt-scan-off",
            callback: function() {
              scanning = false
              poll()
            }
          })
        }, 10000)
      }
    })
  }
}
