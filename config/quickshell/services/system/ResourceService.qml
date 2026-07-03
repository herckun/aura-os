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
  property real cpuUsage: 0
  property real memUsage: 0
  property real memTotal: 0
  property real memUsed: 0
  readonly property real memPct: memUsage
  property var diskUsage: ({})
  property string cpuTemp: ""

  property string fanSpeed: ""
  property string diskTotal: ""
  property string diskUsed: ""
  property string diskFree: ""

  property list<int> cpuHistory: []
  property list<int> memHistory: []

  property string hostname: ""
  property string kernel: ""
  property string uptime: ""
  property var topCpuProcesses: []
  property var topMemProcesses: []

  property string gpuLoad: "---"
  property string gpuTemp: "---"
  property string gpuClock: "---"
  property string gpuVramUsed: "---"
  property string gpuVramTotal: "---"
  property string gpuVramPct: "0"
  property string gpuVendor: ""
  property bool gpuAvailable: false
  property bool gpuHasData: false

  // ═══════════════════════════════════════════════════════════════
  //  INTERNAL STATE
  // ═══════════════════════════════════════════════════════════════
  readonly property int _maxHistory: 40
  property int _gpuRetryCount: 0
  property int _gpuMaxRetries: 3
  property var _pollHandle: null
  property var _gpuDetectHandle: null
  property var _gpuPollHandle: null

  readonly property int _baseCpuPollInterval: 5000
  readonly property int _baseGpuPollInterval: 3000
  readonly property int _baseGpuRetryInterval: 2000

  readonly property int _cpuPollInterval: PerformanceService.scaleInterval(_baseCpuPollInterval)
  readonly property int _gpuPollInterval: PerformanceService.scaleInterval(_baseGpuPollInterval)
  readonly property int _gpuRetryInterval: PerformanceService.scaleInterval(_baseGpuRetryInterval)

  // ═══════════════════════════════════════════════════════════════
  //  TIMERS
  // ═══════════════════════════════════════════════════════════════
  Timer {
    interval: svc._cpuPollInterval
    running: true
    repeat: true
    onTriggered: svc.poll()
  }

  Timer {
    id: gpuPollTimer
    interval: svc._gpuPollInterval
    running: svc.gpuAvailable && svc.gpuVendor !== ""
    repeat: true
    onTriggered: svc._gpuPoll()
  }

  Timer {
    id: gpuRetryTimer
    interval: svc._gpuRetryInterval
    repeat: false
    onTriggered: svc._gpuPoll()
  }

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════
  Component.onCompleted: {
    _detectGpu()
  }

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════
  function poll(): void {
    if (_pollHandle && ProcessPool.isRunning(_pollHandle)) return
    _pollHandle = ProcessPool.runTracked("Poll resources", [AppInfo.configHome + "/features/system/resource-stats.py"], {
      id: "resource-poll",
      callback: function(r) {
        svc._pollHandle = null
        var stdoutText = r.stdout.trim()
        var lines = stdoutText.split("\n")
        var section = ""
        var cpuProcs = []
        var memProcs = []

        for (var i = 0; i < lines.length; i++) {
          var line = lines[i].replace(/\s+/g, ' ').trim()
          if (line === "PROC_START") { section = "cpu_proc"; continue }
          if (line === "PROC_END") { section = ""; continue }
          if (line === "MEM_PROC_START") { section = "mem_proc"; continue }
          if (line === "MEM_PROC_END") { section = ""; continue }

          if (section === "cpu_proc" && line !== "") {
            var p = line.split(" ")
            if (p.length >= 3) cpuProcs.push({ pid: p[0], name: p[1], usage: parseFloat(p[2]) })
          } else if (section === "mem_proc" && line !== "") {
            var m = line.split(" ")
            if (m.length >= 3) memProcs.push({ pid: m[0], name: m[1], usage: parseFloat(m[2]) })
          } else if (section === "") {
            var parts = line.split(" ")
            if (parts[0] === "CPU" && parts.length > 1) {
              var val = parseFloat(parts[1])
              svc.cpuUsage = isNaN(val) ? 0 : Math.round(val)
            } else if (parts[0] === "MEM" && parts.length > 2) {
              svc.memUsed = parseInt(parts[1])
              svc.memTotal = parseInt(parts[2])
              svc.memUsage = svc.memTotal > 0 ? Math.round(svc.memUsed / svc.memTotal * 100) : 0
            } else if (parts[0] === "CPUT") {
              svc.cpuTemp = parts[1] || ""
            } else if (parts[0] === "DISK" && parts.length >= 4) {
              svc.diskTotal = parts[1] || ""
              svc.diskUsed = parts[2] || ""
              svc.diskFree = parts[3] || ""
            }
          }
        }

        svc.topCpuProcesses = cpuProcs
        svc.topMemProcesses = memProcs
        svc.cpuHistory = svc.cpuHistory.concat([svc.cpuUsage]).slice(-svc._maxHistory)
        svc.memHistory = svc.memHistory.concat([svc.memUsage]).slice(-svc._maxHistory)
      }
    })
  }

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════
  function _formatBytes(bytes) {
    var num = parseInt(bytes) || 0
    if (num >= 1073741824) {
      var gb = num / 1073741824
      return gb.toFixed(1) + " GB"
    }
    if (num >= 1048576) {
      var mb = Math.round(num / 1048576)
      return mb + " MB"
    }
    if (num > 0) {
      var kb = Math.round(num / 1024)
      return kb + " KB"
    }
    return "N/A"
  }

  function _safeString(value) {
    if (value === undefined || value === null) return ""
    return value.toString()
  }

  function _safeInt(value) {
    if (value === undefined || value === null) return 0
    var str = value.toString().trim()
    if (str === "") return 0
    var num = parseInt(str)
    if (isNaN(num)) return 0
    return num
  }

  function _extractDigits(text) {
    if (text === undefined || text === null) return ""
    var str = text.toString()
    var result = ""
    for (var i = 0; i < str.length; i++) {
      var ch = str.charAt(i)
      if (ch >= '0' && ch <= '9') {
        result = result + ch
      }
    }
    return result
  }

  function _getAmdPollCommand() {
    return "cat /sys/class/drm/card1/device/gpu_busy_percent 2>/dev/null && " +
           "cat /sys/class/drm/card1/device/hwmon/hwmon*/temp1_input 2>/dev/null | head -1 && " +
           "cat /sys/class/drm/card1/device/mem_info_vram_used 2>/dev/null && " +
           "cat /sys/class/drm/card1/device/mem_info_vram_total 2>/dev/null && " +
           "cat /sys/class/drm/card1/device/pp_dpm_sclk 2>/dev/null | grep '\\*' | head -1 || echo ''"
  }

  function _getNvidiaPollCommand() {
    return "nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total,clocks.current.sm --format=csv,noheader,nounits 2>/dev/null"
  }

  function _getIntelPollCommand() {
    return "cat /sys/class/drm/card0/device/hwmon/hwmon*/temp1_input 2>/dev/null | head -1 && " +
           "echo '---' && " +
           "cat /sys/class/drm/card0/device/hwmon/hwmon*/freq1_input 2>/dev/null | head -1"
  }

  function _parseAmdOutput(lines) {
    if (lines === undefined || lines === null) {
      svc.gpuHasData = false
      return
    }
    var lineCount = (lines.length !== undefined) ? lines.length : 0
    if (lineCount < 5) {
      svc.gpuHasData = false
      return
    }

    var loadVal = _safeString(lines[0]).trim()
    if (loadVal === "") loadVal = "0"
    svc.gpuLoad = loadVal + "%"

    var tempRaw = _safeInt(lines[1])
    svc.gpuTemp = tempRaw > 0 ? Math.round(tempRaw / 1000) + "°" : "---"

    var vramUsed = _safeInt(lines[2])
    var vramTotal = _safeInt(lines[3])
    svc.gpuVramUsed = _formatBytes(String(vramUsed))
    svc.gpuVramTotal = _formatBytes(String(vramTotal))
    svc.gpuVramPct = vramTotal > 0 ? String(Math.round((vramUsed / vramTotal) * 100)) : "0"

    var clockLine = _safeString(lines[4])
    var clockNum = _extractDigits(clockLine)
    svc.gpuClock = clockNum !== "" ? clockNum + " MHZ" : "---"

    svc.gpuHasData = true
  }

  function _parseNvidiaOutput(stdout) {
    var output = _safeString(stdout).trim()
    if (output === "") {
      svc.gpuHasData = false
      return
    }
    var parts = output.split(",")
    if (parts.length < 5) {
      svc.gpuHasData = false
      return
    }

    svc.gpuLoad = String(_safeInt(parts[0])) + "%"

    var tempVal = _safeInt(parts[1])
    svc.gpuTemp = tempVal > 0 ? String(tempVal) + "°" : "---"

    var vramUsed = _safeInt(parts[2]) * 1048576
    var vramTotal = _safeInt(parts[3]) * 1048576
    svc.gpuVramUsed = _formatBytes(String(vramUsed))
    svc.gpuVramTotal = _formatBytes(String(vramTotal))
    svc.gpuVramPct = vramTotal > 0 ? String(Math.round((vramUsed / vramTotal) * 100)) : "0"

    var clockVal = _safeInt(parts[4])
    svc.gpuClock = clockVal > 0 ? String(clockVal) + " MHZ" : "---"

    svc.gpuHasData = true
  }

  function _parseIntelOutput(stdout) {
    var output = _safeString(stdout).trim()
    if (output === "") {
      svc.gpuHasData = false
      return
    }
    var lines = output.split("\n")
    if (lines.length < 3) {
      svc.gpuHasData = false
      return
    }

    svc.gpuLoad = "N/A"

    var tempRaw = _safeInt(lines[0])
    svc.gpuTemp = tempRaw > 0 ? String(Math.round(tempRaw / 1000)) + "°" : "---"

    var freqRaw = _safeInt(lines[2])
    svc.gpuClock = freqRaw > 0 ? String(Math.round(freqRaw / 1000000)) + " MHZ" : "---"

    svc.gpuVramUsed = "N/A"
    svc.gpuVramTotal = "N/A"
    svc.gpuVramPct = "0"

    svc.gpuHasData = true
  }

  function _detectGpu() {
    _gpuDetectHandle = ProcessPool.runTracked("GPU detect", [
      "sh", "-c",
      "(test -f /sys/class/drm/card1/device/gpu_busy_percent && echo 'amd') || " +
      "(which nvidia-smi > /dev/null 2>&1 && nvidia-smi -L > /dev/null 2>&1 && echo 'nvidia') || " +
      "(test -f /sys/class/drm/card0/device/hwmon/hwmon*/temp1_input && echo 'intel') || " +
      "echo ''"
    ], { id: "gpu-detect", callback: function(r) {
      var output = (r && r.stdout !== undefined && r.stdout !== null) ? r.stdout.toString().trim() : ""
      if (output === "amd" || output === "nvidia" || output === "intel") {
        svc.gpuVendor = output
        svc.gpuAvailable = true
      } else {
        svc.gpuAvailable = false
      }
    }})
  }

  function _gpuPoll() {
    if (_gpuPollHandle && _gpuPollHandle.running) return
    if (svc._gpuRetryCount >= svc._gpuMaxRetries) return
    if (svc.gpuVendor === "" || svc.gpuVendor === undefined) return

    var command = ""
    if (svc.gpuVendor === "amd") {
      command = _getAmdPollCommand()
    } else if (svc.gpuVendor === "nvidia") {
      command = _getNvidiaPollCommand()
    } else if (svc.gpuVendor === "intel") {
      command = _getIntelPollCommand()
    } else {
      return
    }

    _gpuPollHandle = ProcessPool.runTracked("GPU poll", command, { id: "gpu-poll", shell: true, callback: function(r) {
      svc._gpuPollHandle = null

      if (!r || r.exitCode !== 0) {
        svc._gpuRetryCount = svc._gpuRetryCount + 1
        if (svc._gpuRetryCount < svc._gpuMaxRetries) {
          gpuRetryTimer.start()
        }
        return
      }

      svc._gpuRetryCount = 0
      var output = ""
      if (r.stdout !== undefined && r.stdout !== null) {
        output = r.stdout.toString()
      }
      if (output === "" || output.trim() === "") {
        svc.gpuHasData = false
        return
      }

      if (svc.gpuVendor === "amd") {
        svc._parseAmdOutput(output.trim().split("\n"))
      } else if (svc.gpuVendor === "nvidia") {
        svc._parseNvidiaOutput(output)
      } else if (svc.gpuVendor === "intel") {
        svc._parseIntelOutput(output)
      }
    }})
  }
}
