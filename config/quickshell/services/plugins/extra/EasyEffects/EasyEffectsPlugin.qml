pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Io
import "../../../../styles"
import "../../../../components"
import "../../../../core"
import "../../../../services"

BasePlugin {
  id: root
  visible: false

  // ── Manifest ────────────────────────────────────────────────────

  pluginId: "easyeffects"
  manifest: ({
    author: "herckun",
    version: "1.1",
    shellVersion: "2.0",
    name: "EasyEffects",
    description: "Audio effects and presets",
    icon: "speaker-high",
    dependencies: [
      { bin: "easyeffects", install: "sudo pacman -S --noconfirm easyeffects" },
      { bin: "calfjackhost", install: "sudo pacman -S --noconfirm calf" }
    ],
    locations: ["audio"],
    settings: [
      { key: "autoStart",     label: "AUTO START",            type: "toggle", default: true },
      { key: "manageRouting", label: "MANAGE AUDIO ROUTING",  type: "toggle", default: true }
    ]
  })

  // ── Public state ─────────────────────────────────────────────────

  property bool available: false
  property bool starting: false
  property bool stopping: false
  property bool restartPending: false
  property bool gaveUp: false
  property bool bypass: false
  property string inputPreset: ""
  property string outputPreset: ""
  property string pendingPreset: ""
  property var inputPresets: []
  property var outputPresets: []

  readonly property PwNode eeSink: _findEeSink(Pipewire.nodes.values)
  readonly property bool running: eeSink !== null
  readonly property bool routed: running && Pipewire.defaultAudioSink === eeSink
  readonly property bool busy: starting || stopping || restartPending || _refreshing

  readonly property string statusText: {
    if (!root._enabled) return ""
    if (root.restartPending) return "RESTARTING..."
    if (root.starting) return "STARTING..."
    if (root.stopping) return "STOPPING..."
    if (root.running) return root.bypass ? "BYPASSED" : "ACTIVE"
    if (root.gaveUp) return "FAILED"
    return "STOPPED"
  }

  readonly property color statusColor: {
    if (!root._enabled) return Theme.textDisabled
    if (root.restartPending || root.starting || root.stopping) return Theme.accent
    if (root.running) return root.bypass ? Theme.warning : Theme.success
    if (root.gaveUp) return Theme.error
    return Theme.textDisabled
  }

  readonly property string presetStatusText: {
    if (!root._enabled) return ""
    if (!root.running) return "Service not running"
    if (root._refreshing) return "Loading presets..."
    if (root.inputPreset || root.outputPreset) return "Presets loaded"
    return "No presets loaded"
  }

  readonly property string routingText: {
    if (!root._enabled || !root._manageRouting || !root.running) return ""
    if (root.routed) return "Output → EasyEffects → " + AudioService.sinkName
    return "Waiting for EE sink routing..."
  }

  // ── Internal state ───────────────────────────────────────────────

  property bool _autoStart: true
  property bool _manageRouting: true
  property bool _userStopped: false
  property bool _refreshing: false
  property bool _retriedRefresh: false
  property int _attempts: 0

  // ── Public API ───────────────────────────────────────────────────

  function toggleBypass(): void {
    if (!root._enabled || !root.running) return
    ProcessPool.runTracked("EE bypass toggle", ["easyeffects", "--bypass-toggle"], {
      id: "ee-bypass-toggle",
      callback: function() {
        if (!root._enabled || !root.running) return
        ProcessPool.runTracked("EE bypass", ["easyeffects", "-b", "3"], {
          id: "ee-bypass",
          callback: function(r) { root.bypass = r.stdout.trim() === "1" }
        })
      }
    })
  }

  function refresh(): void {
    if (!root._enabled || !root.available) return
    if (root.running) root._refreshState()
  }

  function startManual(): void {
    if (!root._enabled || !root.available || root.running || root.starting) return
    root._userStopped = false
    root.gaveUp = false
    root.restartPending = false
    root._attempts = 0
    _restartTimer.stop()
    root._start()
  }

  function stopManual(): void {
    if (!root._enabled || !root.running || root.stopping) return
    root._userStopped = true
    root.restartPending = false
    _restartTimer.stop()
    _startTimeout.stop()
    root.starting = false
    root.stopping = true
    _stopTimeout.restart()
    root._restoreRouting()
    _quitDelay.restart()
  }

  function loadPreset(name: string): void {
    if (!root._enabled || !root.running || root.pendingPreset !== "") return
    root.pendingPreset = name
    ProcessPool.runTracked("EE load preset " + name, ["easyeffects", "-l", name], {
      id: "ee-load-preset",
      callback: function(r) {
        if (!root._enabled || !root.running || r.exitCode !== 0) {
          root.pendingPreset = ""
          return
        }
        root._queryActivePresets()
      }
    })
  }

  // ── Detection ────────────────────────────────────────────────────

  function _isEeNode(n: PwNode): bool {
    if (!n) return false
    var name = (n.name || "").toLowerCase()
    if (name.indexOf("easyeffects") === 0) return true
    var p = n.properties || ({})
    var blob = ((p["application.id"] || "") + " " + (p["application.name"] || "")).toLowerCase()
    return blob.indexOf("easyeffects") !== -1
  }

  function _findEeSink(nodes: var): PwNode {
    if (!Pipewire.ready) return null
    for (var i = 0; i < nodes.length; i++) {
      var n = nodes[i]
      if (n.isSink && !n.isStream && _isEeNode(n)) return n
    }
    return null
  }

  onEeSinkChanged: {
    if (!root._enabled) return
    if (root.eeSink) {
      root.starting = false
      root.restartPending = false
      root.gaveUp = false
      root._retriedRefresh = false
      _restartTimer.stop()
      _startTimeout.stop()
      _autostartTimer.stop()
      _uptimeTimer.restart()
      _settleTimer.restart()
    } else {
      _uptimeTimer.stop()
      _settleTimer.stop()
      root.bypass = false
      root.inputPreset = ""
      root.outputPreset = ""
      root.pendingPreset = ""
      if (root.stopping) {
        root.stopping = false
        _stopTimeout.stop()
        root._restoreRouting()
      } else if (root._autoStart && !root._userStopped && !root.gaveUp) {
        root._scheduleRestart()
      }
    }
  }

  // ── Process control ──────────────────────────────────────────────

  function _checkAvailability(): void {
    if (!root._enabled) return
    ProcessPool.runTracked("EE check available",
      "command -v easyeffects >/dev/null 2>&1 && echo AVAILABLE || echo MISSING", {
        id: "ee-available", shell: true,
        callback: function(r) {
          if (!root._enabled) return
          root.available = r.stdout.trim() === "AVAILABLE"
          if (!root.available) return
          if (root.running) _settleTimer.restart()
          else if (root._autoStart) _autostartTimer.restart()
        }
      })
  }

  function _start(): void {
    if (!root._enabled || !root.available || root.running || root.starting) return
    root.starting = true
    ProcessPool.runTracked("EE start",
      "setsid easyeffects --service-mode --hide-window >/dev/null 2>&1 </dev/null &", {
        id: "ee-start", shell: true
      })
    _startTimeout.restart()
  }

  function _scheduleRestart(): void {
    root._attempts++
    if (root._attempts > 3) {
      root.gaveUp = true
      root.restartPending = false
      return
    }
    root.restartPending = true
    _restartTimer.interval = Math.round(2000 * Math.pow(2, root._attempts - 1))
    _restartTimer.restart()
  }

  // ── Routing ──────────────────────────────────────────────────────

  function _applyRouting(): void {
    if (!root._enabled || !root._manageRouting || !root.running) return
    if (Pipewire.defaultAudioSink !== root.eeSink) {
      Pipewire.preferredDefaultAudioSink = root.eeSink
    }
  }

  function _restoreRouting(): void {
    if (!root._manageRouting) return
    var nodes = Pipewire.nodes.values
    var pick = null
    for (var i = 0; i < nodes.length; i++) {
      var n = nodes[i]
      if (!n.isSink || n.isStream || _isEeNode(n)) continue
      if (!(n.properties && n.properties["device.api"])) continue
      if ((n.name || "").toLowerCase().indexOf("bluez") === -1) { pick = n; break }
      if (!pick) pick = n
    }
    if (pick) Pipewire.preferredDefaultAudioSink = pick
  }

  // ── State refresh ────────────────────────────────────────────────

  function _queryActivePresets(): void {
    ProcessPool.runTracked("EE active presets", ["easyeffects", "-s"], {
      id: "ee-presets",
      callback: function(r) {
        var lines = r.stdout.split("\n")
        for (var i = 0; i < lines.length; i++) {
          var line = lines[i].trim()
          if (!line) continue
          var lower = line.toLowerCase()
          if (lower.indexOf("input:") === 0) _set("inputPreset", line.substring(6).trim())
          else if (lower.indexOf("output:") === 0) _set("outputPreset", line.substring(7).trim())
        }
        root.pendingPreset = ""
      }
    })
  }

  function _refreshState(): void {
    if (!root._enabled || !root.running || root._refreshing) return
    root._refreshing = true
    var pending = 4
    function done() {
      if (--pending !== 0) return
      root._refreshing = false
      if (!root.inputPreset && !root.outputPreset && !root._retriedRefresh) {
        root._retriedRefresh = true
        _retryRefreshTimer.restart()
      }
    }
    ProcessPool.runTracked("EE bypass", ["easyeffects", "-b", "3"], {
      id: "ee-bypass", callback: function(r) { _set("bypass", r.stdout.trim() === "1"); done() }
    })
    ProcessPool.runTracked("EE active presets", ["easyeffects", "-s"], {
      id: "ee-presets",
      callback: function(r) {
        var lines = r.stdout.split("\n")
        for (var i = 0; i < lines.length; i++) {
          var line = lines[i].trim()
          if (!line) continue
          var lower = line.toLowerCase()
          if (lower.indexOf("input:") === 0) _set("inputPreset", line.substring(6).trim())
          else if (lower.indexOf("output:") === 0) _set("outputPreset", line.substring(7).trim())
        }
        done()
      }
    })
    ProcessPool.runTracked("EE list input presets",
      "for f in ${XDG_DATA_HOME:-$HOME/.local/share}/easyeffects/input/*.json ${XDG_CONFIG_HOME:-$HOME/.config}/easyeffects/input/*.json; do [ -e \"$f\" ] && basename \"$f\" .json; done 2>/dev/null | sort -u || true",
      { id: "ee-input-presets", shell: true,
        callback: function(r) {
          var raw = r.stdout.trim()
          _setArray("inputPresets", raw.length > 0 ? raw.split("\n") : [])
          done()
        }
      })
    ProcessPool.runTracked("EE list output presets",
      "for f in ${XDG_DATA_HOME:-$HOME/.local/share}/easyeffects/output/*.json ${XDG_CONFIG_HOME:-$HOME/.config}/easyeffects/output/*.json; do [ -e \"$f\" ] && basename \"$f\" .json; done 2>/dev/null | sort -u || true",
      { id: "ee-output-presets", shell: true,
        callback: function(r) {
          var raw = r.stdout.trim()
          _setArray("outputPresets", raw.length > 0 ? raw.split("\n") : [])
          done()
        }
      })
  }

  // ── Timers ───────────────────────────────────────────────────────

  Timer {
    id: _autostartTimer
    interval: 1500
    repeat: false
    onTriggered: {
      if (!root._enabled || !root._autoStart || root.running || root._userStopped) return
      root._start()
    }
  }

  Timer {
    id: _settleTimer
    interval: 800
    repeat: false
    onTriggered: {
      if (!root._enabled || !root.running) return
      root._applyRouting()
      root._refreshState()
    }
  }

  Timer {
    id: _startTimeout
    interval: 12000
    repeat: false
    onTriggered: {
      if (!root._enabled || root.running) return
      root.starting = false
      root._scheduleRestart()
    }
  }

  Timer {
    id: _stopTimeout
    interval: 8000
    repeat: false
    onTriggered: root.stopping = false
  }

  Timer {
    id: _quitDelay
    interval: 500
    repeat: false
    onTriggered: ProcessPool.runTracked("EE stop", ["easyeffects", "-q"], { id: "ee-stop" })
  }

  Timer {
    id: _restartTimer
    interval: 2000
    repeat: false
    onTriggered: {
      root.restartPending = false
      if (!root._enabled || root.running || root._userStopped) return
      root._start()
    }
  }

  Timer {
    id: _uptimeTimer
    interval: 30000
    repeat: false
    onTriggered: root._attempts = 0
  }

  Timer {
    id: _retryRefreshTimer
    interval: 2000
    repeat: false
    onTriggered: root._refreshState()
  }

  // ── Lifecycle ────────────────────────────────────────────────────

  function stopAllActivity(): void {
    _autostartTimer.stop()
    _settleTimer.stop()
    _startTimeout.stop()
    _stopTimeout.stop()
    _quitDelay.stop()
    _restartTimer.stop()
    _uptimeTimer.stop()
    _retryRefreshTimer.stop()
    root._refreshing = false
    root.starting = false
    root.stopping = false
    root.restartPending = false
    root.pendingPreset = ""
  }

  function onActivated(): void {
    root._autoStart = PluginService.getPluginSetting("easyeffects", "autoStart", "audio") !== false
    root._manageRouting = PluginService.getPluginSetting("easyeffects", "manageRouting", "audio") !== false
    root._userStopped = false
    root.gaveUp = false
    root._attempts = 0
    root._checkAvailability()
  }

  function onSettingChanged(key, value): void {
    if (key === "autoStart") {
      root._autoStart = value !== false
      if (!root._ready || !root._enabled) return
      if (root._autoStart && !root.running && !root.starting) {
        root._userStopped = false
        root.gaveUp = false
        root._attempts = 0
        root._start()
      }
    } else if (key === "manageRouting") {
      root._manageRouting = value !== false
      if (!root._ready || !root._enabled) return
      if (root._manageRouting) root._applyRouting()
      else if (root.routed) root._restoreRouting()
    }
  }

  // ── UI components ─────────────────────────────────────────────────

  property Component audioComponent: Column {
    id: audioPage
    width: parent.width
    spacing: Theme.spaceSm
    visible: root._enabled

    ToolUnavailable {
      visible: root._enabled && !root.available
      toolName: "EasyEffects"
      toolPackage: "easyeffects"
    }

    SectionLabel {
      label: "EASYEFFECTS"
      visible: root._enabled && root.available
    }

    Card {
      width: parent.width
      visible: root._enabled && root.available

      Column {
        width: parent.width
        spacing: Theme.spaceMd

        // ── Status header ────────────────────────────
        RowLayout {
          width: parent.width
          spacing: Theme.spaceSm

          Rectangle {
            width: 8; height: 8
            radius: Theme.radiusSmall
            color: root.statusColor
            Layout.alignment: Qt.AlignVCenter
            Behavior on color { enabled: Theme.animationsEnabled; ColorAnimation { duration: Theme.animationNormal } }
          }

          Column {
            Layout.fillWidth: true
            spacing: Theme.spaceXxs

            Text {
              text: root.statusText
              color: root.statusColor
              font.pixelSize: Theme.fontSizeBody
              font.family: Theme.fontFamilyMono
              font.weight: Font.Bold
              font.letterSpacing: 0.06
            }

            Text {
              text: root.presetStatusText
              color: Theme.textSecondary
              font.pixelSize: Theme.fontSizeCaption
              font.family: Theme.fontFamilyMono
              visible: !root.busy
            }
          }

          Button {
            shape: "circle"
            icon: root.bypass ? "play" : "pause"
            size: 32; iconSize: 12
            bgColor: root.running && !root.bypass ? Theme.accent : "transparent"
            onClicked: root.toggleBypass()
            visible: root.running
          }

          Spinner {
            visible: root.busy
            spinnerSize: 16; spinnerColor: Theme.accent
          }

          Button {
            visible: !root.running && !root.busy
            text: "START"; variant: "accent"
            bgColor: "transparent"; bgHoverColor: Theme.controlBackgroundHover
            onClicked: root.startManual()
          }

          Button {
            visible: root.running && !root.busy
            text: "STOP"
            bgColor: "transparent"; bgHoverColor: Theme.controlBackgroundHover
            onClicked: root.stopManual()
          }

          Button {
            shape: "circle"; icon: "refresh"
            size: 26; iconSize: 10
            onClicked: root.refresh()
            visible: !root.busy
          }
        }

        // ── Routing indicator ─────────────────────────
        Text {
          width: parent.width
          visible: root._enabled && root._manageRouting && root.running && root.routed
          text: root.routingText; color: Theme.accent
          font.pixelSize: Theme.fontSizeCaption; font.family: Theme.fontFamilyMono
          wrapMode: Text.WordWrap
        }
        Text {
          width: parent.width
          visible: root._enabled && root._manageRouting && root.running && !root.routed
          text: root.routingText; color: Theme.textSecondary
          font.pixelSize: Theme.fontSizeCaption; font.family: Theme.fontFamilyMono
        }

        // ── Restart gave up ───────────────────────────
        RowLayout {
          width: parent.width
          visible: root.gaveUp && !root.running
          spacing: Theme.spaceSm

          Text {
            text: "Auto-restart disabled after repeated failures"
            color: Theme.error
            font.pixelSize: Theme.fontSizeCaption; font.family: Theme.fontFamilyMono
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
          }
          Button {
            text: "RETRY"; variant: "accent"
            bgColor: "transparent"; bgHoverColor: Theme.controlBackgroundHover
            onClicked: root.startManual()
          }
        }

        // ── Active presets ────────────────────────────
        Column {
          width: parent.width
          spacing: Theme.spaceSm
          visible: root.running

          Divider {}

          GridLayout {
            width: parent.width
            columns: 2
            columnSpacing: Theme.spaceSm; rowSpacing: Theme.spaceSm

            Column {
              Layout.fillWidth: true; spacing: Theme.spaceXxs
              Text { text: "OUTPUT PRESET"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; font.letterSpacing: 0.08 }
              Text { text: root.outputPreset || "None"; color: root.outputPreset ? Theme.textPrimary : Theme.textDisabled; font.pixelSize: Theme.fontSizeLabel; font.family: Theme.fontFamilyMono }
            }
            Column {
              Layout.fillWidth: true; spacing: Theme.spaceXxs
              Text { text: "INPUT PRESET"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; font.letterSpacing: 0.08 }
              Text { text: root.inputPreset || "None"; color: root.inputPreset ? Theme.textPrimary : Theme.textDisabled; font.pixelSize: Theme.fontSizeLabel; font.family: Theme.fontFamilyMono }
            }
          }
        }

        // ── Output presets ────────────────────────────
        EepPresetList {
          title: "OUTPUT PRESETS"
          presets: root.outputPresets
          activePreset: root.outputPreset
          pendingPreset: root.pendingPreset
          visible: root.running && root.outputPresets.length > 0
          onSelected: name => root.loadPreset(name)
        }

        // ── Input presets ─────────────────────────────
        EepPresetList {
          title: "INPUT PRESETS"
          presets: root.inputPresets
          activePreset: root.inputPreset
          pendingPreset: root.pendingPreset
          visible: root.running && root.inputPresets.length > 0
          onSelected: name => root.loadPreset(name)
        }
      }
    }
  }
}
