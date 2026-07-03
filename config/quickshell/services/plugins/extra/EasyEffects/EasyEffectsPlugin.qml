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
    version: "1.0",
    shellVersion: "2.0",
    name: "EasyEffects",
    description: "Audio effects and presets",
    icon: "speaker-high",
    dependencies: [{ bin: "easyeffects", install: "sudo pacman -S --noconfirm easyeffects" }],
    locations: ["audio"],
    settings: [
      { key: "autoStart",     label: "AUTO START",            type: "toggle", default: true },
      { key: "manageRouting", label: "MANAGE AUDIO ROUTING",  type: "toggle", default: true }
    ]
  })

  // ── Public state ─────────────────────────────────────────────────

  property bool available: false
  property bool running: false
  property bool bypass: false
  property bool busy: false
  property string inputPreset: ""
  property string outputPreset: ""
  property var inputPresets: []
  property var outputPresets: []

  readonly property string statusText: {
    if (!root._enabled) return ""
    if (root._pendingRestart) return "RESTARTING..."
    if (root.busy && !root.running) return "STARTING..."
    if (root._transitioning) return "STABILIZING..."
    if (root.running) return root.bypass ? "BYPASSED" : "ACTIVE"
    if (root._restartGaveUp) return "FAILED"
    return "STOPPED"
  }

  readonly property color statusColor: {
    if (!root._enabled) return Theme.textDisabled
    if (root._pendingRestart || root.busy || root._transitioning) return Theme.accent
    if (root.running) return root.bypass ? Theme.warning : Theme.success
    if (root._restartGaveUp) return Theme.danger
    return Theme.textDisabled
  }

  readonly property string presetStatusText: {
    if (!root._enabled) return ""
    if (root._transitioning) return "Waiting for stable connection..."
    if (!root.running) return "Service not running"
    if (root._refreshing) return "Loading presets..."
    if (root.inputPreset || root.outputPreset) return "Presets loaded"
    return "No presets loaded"
  }

  readonly property string routingText: {
    if (!root._enabled || !root._manageRouting || !root.running) return ""
    if (root._transitioning) return "Waiting for stable sink before routing..."
    if (root._eeSink) return "Output → EasyEffects → " + AudioService.sinkName
    if (root._consideredStable) return "EE sink not detected — might be running as a filter"
    return "Waiting for EE sink node..."
  }

  readonly property bool showRoutingWaiting: root._enabled && root._manageRouting && root.running && !root._eeSink && !root._consideredStable
  readonly property bool showRoutingFailed:  root._enabled && root._manageRouting && root.running && !root._eeSink && root._consideredStable
  readonly property bool showRoutingActive:  root._enabled && root._manageRouting && root.running && root._eeSink && root._consideredStable

  // ── Internal state ───────────────────────────────────────────────

  property bool _started: false
  property bool _stateLoaded: false
  property bool _autoStart: true
  property bool _manageRouting: true

  property bool _transitioning: false
  property bool _consideredStable: false
  property bool _firstStableRefresh: false
  property bool _pendingRestart: false
  property int _restartAttempts: 0
  property bool _restartGaveUp: false
  readonly property int _maxRestartAttempts: 3

  property var _checkHandle: null
  property bool _refreshing: false
  readonly property int _basePollInterval: 3000
  readonly property int _pollInterval: PerformanceService.scaleInterval(_basePollInterval)

  property PwNode _eeSink: null
  property PwNode _hwSink: null
  property int _sinkRetryCount: 0

  // ── Signal handlers ────────────────────────────────

  // ── Public API ───────────────────────────────────────────────────

  function toggleBypass(): void {
    if (!root._enabled || !root._consideredStable) return
    ProcessPool.runTracked("EE bypass toggle", ["easyeffects", "--bypass-toggle"], {
      id: "ee-bypass-toggle",
      callback: function() {
        if (!root._enabled) return
        ProcessPool.runTracked("EE bypass", ["easyeffects", "-b", "3"], {
          id: "ee-bypass",
          callback: function(r) { root.bypass = r.stdout.trim() === "1" }
        })
      }
    })
  }

  function refresh(): void {
    if (!root._enabled || root._transitioning) return
    root._started = true
    root.busy = true
    root._stateLoaded = false
    if (root._checkHandle?.running) return
    root._checkHandle = ProcessPool.runTracked("EE check running",
      "pgrep -x easyeffects >/dev/null 2>&1 && echo RUNNING || echo STOPPED", {
        id: "ee-check", shell: true,
        callback: function(r) {
          root._checkHandle = null
          if (!root._enabled) return
          var isRunning = r.stdout.trim() === "RUNNING"
          var wasRunning = root.running
          root.running = isRunning
          if (isRunning) root._handleRunningDetected(wasRunning)
          else root._handleStoppedDetected(wasRunning)
        }
      })
  }

  function startManual(): void {
    if (!root._enabled || root.busy || root._transitioning) return
    root._restartAttempts = 0
    root._restartGaveUp = false
    root._pendingRestart = false
    root._started = true
    root.busy = true
    root._stateLoaded = false
    root._eeSink = null
    root._findHWSink()
    ProcessPool.runTracked("EE start", ["easyeffects", "--service-mode", "--hide-window"], {
      id: "ee-start",
      callback: function(r) {
        if (!root._enabled) return
        root.busy = false
        if (r.exitCode !== 0)
          Logger.warn("easyeffects", "Start failed (exit " + r.exitCode + "): " + r.stderr.trim())
      }
    })
  }

  function stopManual(): void {
    if (!root._enabled || root.busy) return
    _stabilityTimer.stop()
    _restartDelay.stop()
    _sinkRetryTimer.stop()
    _retryRefreshTimer.stop()
    root._transitioning = false
    root._consideredStable = false
    root._pendingRestart = false
    root._firstStableRefresh = false
    root._stateLoaded = false
    root.busy = true
    root._eeSink = null
    ProcessPool.runTracked("EE stop", ["easyeffects", "-q"], {
      id: "ee-stop",
      callback: function() {
        root.busy = false
        root.running = false
        root._started = false
        root._findHWSink()
        root._applyRouting()
      }
    })
  }

  function loadPreset(name: string): void {
    if (!root._enabled || !root._consideredStable) return
    ProcessPool.runTracked("EE load preset " + name, ["easyeffects", "-l", name], {
      id: "ee-load-" + name,
      callback: function(r) {
        if (!root._enabled || r.exitCode !== 0) return
        ProcessPool.runTracked("EE active presets", ["easyeffects", "-s"], {
          id: "ee-presets",
          callback: function(r2) {
            var lines = r2.stdout.split("\n")
            for (var i = 0; i < lines.length; i++) {
              var line = lines[i].trim()
              if (!line) continue
              var lower = line.toLowerCase()
              if (lower.indexOf("input:") === 0) root.inputPreset = line.substring(6).trim()
              else if (lower.indexOf("output:") === 0) root.outputPreset = line.substring(7).trim()
            }
          }
        })
      }
    })
  }

  // ── Helpers ──────────────────────────────────────────────────────

  function _checkAvailability(): void {
    if (!root._enabled) return
    ProcessPool.runTracked("EE check available",
      "command -v easyeffects >/dev/null 2>&1 && echo AVAILABLE || echo MISSING", {
        id: "ee-available", shell: true,
        callback: function(r) {
          if (!root._enabled) return
          root.available = r.stdout.trim() === "AVAILABLE"
          if (root.available) _pollTimer.start()
        }
      })
  }

  function stopAllActivity(): void {
    _pollTimer.stop()
    _stabilityTimer.stop()
    _restartDelay.stop()
    _sinkRetryTimer.stop()
    _retryRefreshTimer.stop()
    _refreshGuard.stop()
    root._refreshing = false
    root.busy = false
    root._transitioning = false
    root._consideredStable = false
    root._pendingRestart = false
    root._firstStableRefresh = false
    root._checkHandle = null
  }

  // ── Process state machine ────────────────────────────────────────

  function _handleRunningDetected(wasRunning): void {
    if (!root._transitioning && !root._consideredStable) {
      root._transitioning = true
      _pollTimer.stop()
      _stabilityTimer.start()
      root._startSinkDiscovery()
      Logger.info("easyeffects", "Process detected, waiting for stability...")
    }
    if (!root._stateLoaded && root._consideredStable) root._refreshState()
  }

  function _handleStoppedDetected(wasRunning): void {
    if (root._transitioning || root._refreshing || root._firstStableRefresh) {
      Logger.debug("easyeffects", "Ignored stopped detection during transition")
      return
    }
    _stabilityTimer.stop()
    _retryRefreshTimer.stop()
    root._transitioning = false
    root._consideredStable = false
    root._eeSink = null
    _sinkRetryTimer.stop()
    var shouldRetry = root._autoStart && !root._restartGaveUp && !root._pendingRestart
    if (wasRunning) {
      Logger.warn("easyeffects", "Process stopped unexpectedly")
    } else if (root._started) {
      Logger.warn("easyeffects", "Process failed to stay running")
    }
    if (root._started && shouldRetry) root._handleUnexpectedStop()
    else if (!root._started && root._autoStart) root._doAutoStart()
    else { root._findHWSink(); root._applyRouting() }
  }

  function _handleUnexpectedStop(): void {
    root._restartAttempts++
    if (root._restartAttempts > root._maxRestartAttempts) {
      root._restartGaveUp = true
      root._pendingRestart = false
      Logger.warn("easyeffects", "Gave up auto-restart after " + root._maxRestartAttempts + " attempts")
      root._findHWSink()
      root._applyRouting()
      return
    }
    root._pendingRestart = true
    var delay = Math.round(2000 * Math.pow(2, root._restartAttempts - 1))
    Logger.info("easyeffects",
      "Scheduling restart in " + delay + "ms (attempt " + root._restartAttempts + "/" + root._maxRestartAttempts + ")")
    _restartDelay.interval = delay
    _restartDelay.start()
  }

  function _doAutoStart(): void {
    if (!root._enabled || !root._autoStart) return
    root._started = true
    root.startManual()
  }

  // ── State refresh ────────────────────────────────────────────────

  function _refreshState(): void {
    if (!root._enabled || root._refreshing || !root._consideredStable) return
    root._refreshing = true
    _refreshGuard.restart()
    var pending = 4
    function done() {
      if (--pending === 0) {
        root._refreshing = false
        _refreshGuard.stop()
        root.busy = false
        _pollTimer.start()
        if (!root.inputPreset && !root.outputPreset && root._firstStableRefresh) {
          root._firstStableRefresh = false
          _retryRefreshTimer.start()
        } else {
          root._firstStableRefresh = false
          root._stateLoaded = true
        }
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
      "ls ${XDG_CONFIG_HOME:-$HOME/.config}/easyeffects/input/*.json 2>/dev/null | xargs -n 1 basename -s .json || true",
      { id: "ee-input-presets", shell: true,
        callback: function(r) {
          var raw = r.stdout.trim()
          _setArray("inputPresets", raw.length > 0 ? raw.split("\n") : [])
          done()
        }
      })
    ProcessPool.runTracked("EE list output presets",
      "ls ${XDG_CONFIG_HOME:-$HOME/.config}/easyeffects/output/*.json 2>/dev/null | xargs -n 1 basename -s .json || true",
      { id: "ee-output-presets", shell: true,
        callback: function(r) {
          var raw = r.stdout.trim()
          _setArray("outputPresets", raw.length > 0 ? raw.split("\n") : [])
          done()
        }
      })
  }

  // ── PipeWire discovery ───────────────────────────────────────────

  function _isEENode(node): bool {
    if (!node) return false
    var terms = [
      (node.name || "").toLowerCase(), (node.description || "").toLowerCase(),
      (node.nickname || "").toLowerCase(),
      node.properties ? (node.properties["media.name"] || "").toLowerCase() : "",
      node.properties ? (node.properties["node.description"] || "").toLowerCase() : "",
      node.properties ? (node.properties["application.name"] || "").toLowerCase() : ""
    ]
    for (var i = 0; i < terms.length; i++) {
      var t = terms[i]
      if (t.indexOf("easyeffects") !== -1 || t.indexOf("easy effects") !== -1 || t.indexOf("easy_effect") !== -1) return true
    }
    return false
  }

  function _findEESink(): void {
    if (!root._enabled) return
    var found = null
    if (Pipewire.ready) {
      var nodes = Pipewire.nodes.values || []
      for (var i = 0; i < nodes.length; i++) {
        var node = nodes[i]
        if (!node.ready || !_isEENode(node)) continue
        var mediaClass = node.properties ? (node.properties["media.class"] || "null") : "null"
        Logger.info("easyeffects",
          "Matched EE node: " + (node.name || "?") + " isSink=" + node.isSink +
          " hasAudio=" + (node.audio !== null) + " mediaClass=" + mediaClass)
        if (node.isSink && node.audio) { found = node; break }
      }
    }
    if (found !== root._eeSink) {
      if (found) Logger.info("easyeffects", "Selected EE sink: " + (found.description || found.name || "unnamed"))
      else if (root.running) Logger.warn("easyeffects", "No suitable EE sink node found (running as filter?)")
      root._eeSink = found
    }
  }

  function _findHWSink(): void {
    if (!root._enabled) return
    var found = null
    if (Pipewire.ready) {
      for (var i = 0; i < Pipewire.nodes.count; i++) {
        var node = Pipewire.nodes.get(i)
        if (!node.isSink || !node.ready || !node.audio || _isEENode(node)) continue
        var name = (node.name || "").toLowerCase()
        if (name.indexOf("bluez") === -1) { found = node; break }
        else if (!found) found = node
      }
    }
    if (!found) Logger.warn("easyeffects", "No hardware sink found")
    else Logger.debug("easyeffects", "HW sink: " + (found.description || found.name))
    root._hwSink = found
  }

  function _applyRouting(): void {
    if (!root._enabled || !root._manageRouting) return
    var usingEESink = (root._eeSink !== null && Pipewire.defaultAudioSink === root._eeSink)
    if (root.running && root._consideredStable && root._eeSink) {
      if (!usingEESink) {
        Logger.info("easyeffects", "Routing output through EE sink")
        Pipewire.preferredDefaultAudioSink = root._eeSink
      }
    } else if (usingEESink && root._hwSink) {
      Logger.info("easyeffects", "Restoring hardware sink routing")
      Pipewire.preferredDefaultAudioSink = root._hwSink
    }
  }

  function _startSinkDiscovery(): void {
    if (!root._enabled) return
    root._sinkRetryCount = 0
    root._findEESink()
    if (!root._eeSink) _sinkRetryTimer.start()
  }

  // ── Timers ───────────────────────────────────────────────────────

  Timer {
    id: _pollTimer
    interval: root._pollInterval
    repeat: true
    running: false
    onTriggered: {
      if (!root._enabled || !root.available || root.busy || root._pendingRestart) return
      if (root._transitioning || root._refreshing || root._firstStableRefresh) return
      if (root._checkHandle?.running) return
      root._checkHandle = ProcessPool.runTracked("EE check running",
        "pgrep -x easyeffects >/dev/null 2>&1 && echo RUNNING || echo STOPPED", {
          id: "ee-check", shell: true,
          callback: function(r) {
            root._checkHandle = null
            if (!root._enabled) return
            if (root._transitioning || root._refreshing || root._firstStableRefresh) {
              Logger.debug("easyeffects", "Poll ignored during transition state")
              return
            }
            var isRunning = r.stdout.trim() === "RUNNING"
            var wasRunning = root.running
            root.running = isRunning
            if (isRunning) root._handleRunningDetected(wasRunning)
            else root._handleStoppedDetected(wasRunning)
          }
        })
    }
  }

  Timer {
    id: _stabilityTimer
    interval: 2000
    repeat: false
    onTriggered: {
      if (!root._enabled || !root.running) { root._transitioning = false; _pollTimer.start(); return }
      root._consideredStable = true
      root._transitioning = false
      root._restartAttempts = 0
      root._restartGaveUp = false
      root._firstStableRefresh = true
      Logger.info("easyeffects", "Process stable")
      root._findEESink()
      root._applyRouting()
      root._refreshState()
    }
  }

  Timer {
    id: _retryRefreshTimer
    interval: 2000
    repeat: false
    onTriggered: {
      if (root._enabled && root.running && root._consideredStable) root._refreshState()
    }
  }

  Timer {
    id: _restartDelay
    interval: 2000
    repeat: false
    onTriggered: {
      root._pendingRestart = false
      if (!root._enabled) return
      root.startManual()
    }
  }

  Timer {
    id: _sinkRetryTimer
    interval: 500
    repeat: false
    onTriggered: {
      if (!root._enabled || !root.running || root._eeSink) { root._sinkRetryCount = 0; return }
      root._findEESink()
      if (root._eeSink) {
        root._sinkRetryCount = 0
      } else {
        root._sinkRetryCount++
        if (root._sinkRetryCount < 20) _sinkRetryTimer.start()
        else { Logger.warn("easyeffects", "EE sink not found after waiting 10s"); root._sinkRetryCount = 0 }
      }
    }
  }

  Timer {
    id: _refreshGuard
    interval: 10000
    repeat: false
    onTriggered: { root._refreshing = false; root.busy = false }
  }

  // ── Lifecycle ────────────────────────────────────────────────────
  function onActivated(): void {
    root._autoStart = PluginService.getPluginSetting("easyeffects", "autoStart", "audio") !== false
    root._manageRouting = PluginService.getPluginSetting("easyeffects", "manageRouting", "audio") !== false
    root._checkAvailability()
  }

  function onSettingChanged(key, value): void {
    if (key === "autoStart") {
      root._autoStart = value !== false
      if (!root._ready || !root._enabled || root.running || root.busy) return
      if (root._autoStart && !root._started) root._doAutoStart()
    } else if (key === "manageRouting") {
      root._manageRouting = value !== false
      if (!root._ready || !root._enabled) return
      if (root._manageRouting) root._applyRouting()
      else if (root._hwSink && Pipewire.defaultAudioSink === root._eeSink)
        Pipewire.preferredDefaultAudioSink = root._hwSink
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
              visible: !root.busy && !root._transitioning && !root._pendingRestart
            }
          }

          Button {
            shape: "circle"
            icon: root.bypass ? "play" : "pause"
            size: 32; iconSize: 12
            bgColor: root.running && !root.bypass && root._consideredStable ? Theme.accent : "transparent"
            onClicked: root.toggleBypass()
            visible: root.running && root._consideredStable
          }

          Spinner {
            visible: (root.busy && !root.running) || root._transitioning || root._pendingRestart || root._refreshing
            spinnerSize: 16; spinnerColor: Theme.accent
          }

          Button {
            visible: !root.running && !root.busy && !root._transitioning && !root._pendingRestart
            text: "START"; variant: "accent"
            bgColor: "transparent"; bgHoverColor: Theme.controlBackgroundHover
            onClicked: root.startManual()
          }

          Button {
            shape: "circle"; icon: "refresh"
            size: 26; iconSize: 10
            onClicked: root.refresh()
            visible: !root._transitioning && !root._pendingRestart
          }
        }

        // ── Routing indicator ─────────────────────────
        Text {
          width: parent.width
          visible: root.showRoutingActive
          text: root.routingText; color: Theme.accent
          font.pixelSize: Theme.fontSizeCaption; font.family: Theme.fontFamilyMono
          wrapMode: Text.WordWrap
        }
        Text {
          width: parent.width
          visible: root.showRoutingWaiting
          text: root.routingText; color: Theme.textSecondary
          font.pixelSize: Theme.fontSizeCaption; font.family: Theme.fontFamilyMono
        }
        Text {
          width: parent.width
          visible: root.showRoutingFailed
          text: root.routingText; color: Theme.warning
          font.pixelSize: Theme.fontSizeCaption; font.family: Theme.fontFamilyMono
        }

        // ── Restart gave up ───────────────────────────
        RowLayout {
          width: parent.width
          visible: root._restartGaveUp && !root.running
          spacing: Theme.spaceSm

          Text {
            text: "Auto-restart disabled after repeated failures"
            color: Theme.danger
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
          visible: root.running && root._consideredStable

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
          visible: root.running && root._consideredStable && root.outputPresets.length > 0
          onSelected: name => root.loadPreset(name)
        }

        // ── Input presets ─────────────────────────────
        EepPresetList {
          title: "INPUT PRESETS"
          presets: root.inputPresets
          activePreset: root.inputPreset
          visible: root.running && root._consideredStable && root.inputPresets.length > 0
          onSelected: name => root.loadPreset(name)
        }
      }
    }
  }
}
