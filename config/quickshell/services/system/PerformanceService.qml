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
  enum Profile { Performance = 0, Balanced = 1, BatterySaver = 2 }

  readonly property int profile: Store.performance.profile

  readonly property bool batterySaver: profile === 2

  readonly property real pollIntervalMultiplier: {
    switch (svc.profile) {
      case 0: return 0.5
      case 1: return 1.0
      case 2: return 3.0
      default: return 1.0
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════
  function scaleInterval(base: int): int {
    return Math.round(base * pollIntervalMultiplier)
  }

  function switchProfile(p: int): void {
    Store.performance.profile = p
  }

  // ═══════════════════════════════════════════════════════════════
  //  INTERNAL STATE
  // ═══════════════════════════════════════════════════════════════
  property bool _ready: false
  property int _prevProfile: 1
  property real _savedBrightness: 0.7
  property var _tlpHandle: null

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════
  function _applyTLP(p: int): void {
    if (_tlpHandle && ProcessPool.isRunning(_tlpHandle)) {
      ProcessPool.stop(_tlpHandle)
    }
    var tlpName = p === 0 ? "performance" : p === 2 ? "power-saver" : "balanced"
    _tlpHandle = ProcessPool.runTracked("Perf: TLP", "tlpctl " + tlpName + " 2>/dev/null", {
      id: "perf-tlp",
      shell: true,
      silent: true,
      callback: function() { _tlpHandle = null }
    })
  }

  function _enterBatterySaver(): void {
    _applyTLP(2)
    svc._savedBrightness = BrightnessService.brightness
    BrightnessService.setBrightness(0.30)
    BluetoothService.setPower(false)
  }

  function _exitBatterySaver(): void {
    BrightnessService.setBrightness(svc._savedBrightness)
    BluetoothService.setPower(true)
  }

  // ═══════════════════════════════════════════════════════════════
  //  SIGNAL CONNECTIONS
  // ═══════════════════════════════════════════════════════════════
  readonly property bool autoSaverEngage: Store.power.autoBatterySaver
      && BatteryService.hasBattery
      && BatteryService.discharging
      && BatteryService.percentage <= Store.power.autoBatterySaverThreshold
  property bool _autoSaverActive: false
  property int _profileBeforeSaver: 1

  onAutoSaverEngageChanged: {
    if (!svc._ready)
      return
    if (svc.autoSaverEngage && svc.profile !== 2) {
      svc._profileBeforeSaver = svc.profile
      svc._autoSaverActive = true
      svc.switchProfile(2)
    } else if (!svc.autoSaverEngage && svc._autoSaverActive) {
      svc._autoSaverActive = false
      if (svc.profile === 2)
        svc.switchProfile(svc._profileBeforeSaver)
    }
  }

  onProfileChanged: {
    if (!svc._ready) {
      svc._prevProfile = svc.profile
      return
    }

    if (svc.profile === 2) {
      svc._enterBatterySaver()
    } else {
      svc._applyTLP(svc.profile)
      if (svc._prevProfile === 2) {
        svc._exitBatterySaver()
      }
    }
    svc._prevProfile = svc.profile
  }

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════
  Component.onCompleted: {
    svc._prevProfile = svc.profile
    svc._ready = true
    if (svc.profile === 2) {
      svc._enterBatterySaver()
    } else {
      svc._applyTLP(svc.profile)
    }
  }
}
