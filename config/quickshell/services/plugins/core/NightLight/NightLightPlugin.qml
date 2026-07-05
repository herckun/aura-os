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
  pluginId: "nightlight"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Night Light",
    description: "Blue light filter",
    icon: "moon",
    locations: ["controlcenter_row", "settings"],
    settings: [
      { key: "temperature", label: "TEMPERATURE (K)", type: "stepper", default: 3500, min: 2700, max: 6500, step: 100, shared: true },
      { key: "autoSchedule", label: "AUTO", description: "On at 20:00, off at 07:00", type: "toggle", default: false, shared: true }
    ]
  })

  // ── Public state ─────────────────────────────────────────────────
  property bool active: false
  property bool busy: false

  // ── Internal state ───────────────────────────────────────────────
  property int _temperature: PluginService.getPluginSetting("nightlight", "temperature", "") ?? 3500
  property bool _autoSchedule: PluginService.getPluginSetting("nightlight", "autoSchedule", "") ?? false

  // ── Signal handlers ──────────────────────────────────────────────

  // ── Public API ───────────────────────────────────────────────────
  function toggle(): void {
    if (busy) return
    if (active) stopDaemon()
    else startDaemon()
  }

  function startDaemon(): void {
    busy = true
    active = true
    ProcessPool.runDetached(["hyprsunset", "-t", String(_temperature)])
    _busyTimer.start()
  }

  function stopDaemon(): void {
    busy = true
    active = false
    ProcessPool.runTracked("NightLight stop", ["sh", "-c", "hyprctl hyprsunset reset temperature 2>/dev/null; pkill hyprsunset"], {
      id: "nl-stop",
      callback: function(r) {
        busy = false
        if (r.exitCode !== 0) {
          active = true
          Logger.warn("nightlight", "Failed to stop: " + r.stderr.trim())
        }
      }
    })
  }

  function _isNightTime(): bool {
    var d = new Date()
    var h = d.getHours()
    return h >= 20 || h < 7
  }

  function _autoTick(): void {
    if (!_autoSchedule || busy || !root.enabled) return
    var shouldBeOn = _isNightTime()
    if (shouldBeOn && !active) startDaemon()
    else if (!shouldBeOn && active) stopDaemon()
  }

  function setTemperature(temp: int): void {
    _temperature = temp
    PluginService.setPluginSetting("nightlight", "temperature", temp)
    if (active && !busy) {
      ProcessPool.runTracked("NightLight set temp", ["sh", "-c", "hyprctl hyprsunset temperature " + String(temp)], {
        id: "nl-set"
      })
    }
  }

  function _checkRunning(): void {
    if (root._checkHandle?.running) return
    root._checkHandle = ProcessPool.runTracked("NightLight check",
      "pgrep -x hyprsunset >/dev/null 2>&1 && echo RUNNING || echo STOPPED", {
        id: "nl-check", shell: true,
        callback: function(r) {
          root._checkHandle = null
          root.active = r.stdout.trim() === "RUNNING"
        }
      })
  }

  // ── Helpers ──────────────────────────────────────────────────────
  property var _checkHandle: null

  // ── Timers ───────────────────────────────────────────────────────
  Timer {
    id: _busyTimer
    interval: 500
    repeat: false
    onTriggered: root.busy = false
  }

  Timer {
    id: _pollTimer
    interval: PerformanceService.scaleInterval(5000)
    repeat: true
    running: false
    onTriggered: root._checkRunning()
  }

  Timer {
    id: _autoScheduleTimer
    interval: PerformanceService.scaleInterval(60000)
    repeat: true
    running: root._autoSchedule && root.enabled
    onTriggered: root._autoTick()
  }

  // ── Lifecycle ────────────────────────────────────────────────────
  function onActivated(): void {
    _pollTimer.start()
  }

  // Disable-only — not stopAllActivity, which also fires on restart where hyprsunset persists.
  function onDeactivated(): void {
    root.active = false
    ProcessPool.runDetached(["sh", "-c", "hyprctl hyprsunset reset temperature 2>/dev/null; pkill hyprsunset"])
  }

  function stopAllActivity(): void {
    _pollTimer.stop()
  }

  function onSettingChanged(key, value): void {
    if (key === "autoSchedule") {
      root._autoSchedule = value !== false
      if (root._autoSchedule) root._autoTick()
    }
  }

  Component.onCompleted: {
    _checkRunning()
    if (_autoSchedule) _autoTick()
  }

  // ── UI components ────────────────────────────────────────────────
  property Component controlCenterComponent: Column {
    width: parent.width
    spacing: Theme.spaceSm

    SectionLabel { label: "NIGHT LIGHT" }

    RowLayout {
      width: parent.width
      spacing: Theme.spaceSm

      Button {
        shape: "circle"
        width: 40; height: 40
        icon: "moon"
        active: root.active
        busy: root.busy
        onClicked: root.toggle()
      }

      Column {
        Layout.fillWidth: true
        spacing: Theme.space2

        Text {
          text: root.busy ? "LOADING..." : root.active ? "ON" : "OFF"
          color: root.active ? Theme.accent : Theme.textPrimary
          font.pixelSize: Theme.fontSizeBody
          font.family: Theme.fontFamilyMono
          font.bold: true
          font.letterSpacing: 0.06
        }

        Text {
          text: root.busy ? "Please wait" : "Tap to toggle"
          color: Theme.textSecondary
          font.pixelSize: Theme.fontSizeCaption
          font.family: Theme.fontFamilyMono
        }
      }
    }

    ButtonGroup {
      width: parent.width
      fillWidth: true

      Repeater {
        model: [
          { temp: 2700, label: "2700" },
          { temp: 3500, label: "3500" },
          { temp: 4500, label: "4500" },
          { temp: 5500, label: "5500" }
        ]

        delegate: Button {
          required property var modelData
          Layout.fillWidth: true
          size: "sm"
          text: modelData.label + "K"
          bgColor: root._temperature === modelData.temp ? Theme.accent : "transparent"
          onClicked: root.setTemperature(modelData.temp)
        }
      }
    }
  }

  property Component settingsComponent: Column {
    width: parent.width
    spacing: Theme.spaceSm

    SectionLabel { label: "NIGHT LIGHT" }

    Card {
      width: parent.width

      Column {
        width: parent.width
        spacing: Theme.spaceMd

        ToggleSetting {
          label: "AUTO"
          description: "On at 20:00, off at 07:00"
          checked: root._autoSchedule
          onToggled: function(checked) {
            root._autoSchedule = checked
            PluginService.setPluginSetting("nightlight", "autoSchedule", checked)
            if (checked) root._autoTick()
          }
        }

        RowLayout {
          width: parent.width

          Text {
            text: "TEMPERATURE"
            color: Theme.textPrimary
            font.pixelSize: Theme.fontSizeLabel
            font.family: Theme.fontFamilyMono
            font.weight: Font.Medium
            font.letterSpacing: 0.06
            Layout.fillWidth: true
          }

          Text {
            text: root._temperature + "K"
            color: Theme.accent
            font.pixelSize: Theme.fontSizeBody
            font.family: Theme.fontFamilyMono
          }
        }

        SliderControl {
          width: parent.width
          from: 2700
          to: 6500
          stepSize: 100
          value: root._temperature
          onMoved: root.setTemperature(Math.round(value))
        }
      }
    }

    ButtonGroup {
      width: parent.width
      fillWidth: true

      Repeater {
        model: [
          { temp: 2700, label: "2700" },
          { temp: 3500, label: "3500" },
          { temp: 4500, label: "4500" },
          { temp: 5500, label: "5500" }
        ]

        delegate: Button {
          required property var modelData
          Layout.fillWidth: true
          size: "sm"
          text: modelData.label + "K"
          bgColor: root._temperature === modelData.temp ? Theme.accent : "transparent"
          onClicked: root.setTemperature(modelData.temp)
        }
      }
    }
  }
}
