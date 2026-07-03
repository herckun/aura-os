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

  property int profile: 1

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
    if (p === svc.profile) return
    svc.profile = p
    Store.set("performance.profile", p)
  }

  // ═══════════════════════════════════════════════════════════════
  //  INTERNAL STATE
  // ═══════════════════════════════════════════════════════════════
  property bool _ready: false
  property int _prevProfile: 1
  property bool _savedBlur: true
  property bool _savedTransparency: true
  property bool _savedAnimations: true
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
    svc._savedBlur = Store.getBool("appearance.blur", true)
    svc._savedTransparency = Store.getBool("appearance.transparency", true)
    svc._savedAnimations = Store.getBool("performance.animations", true)
    Store.set("appearance.blur", false)
    Store.set("appearance.transparency", false)
    Store.set("performance.animations", false)
  }

  function _restoreAppearance(): void {
    BrightnessService.setBrightness(svc._savedBrightness)
    BluetoothService.setPower(true)
    Store.set("appearance.blur", svc._savedBlur)
    Store.set("appearance.transparency", svc._savedTransparency)
    Store.set("performance.animations", svc._savedAnimations)
  }

  // ═══════════════════════════════════════════════════════════════
  //  SIGNAL CONNECTIONS
  // ═══════════════════════════════════════════════════════════════
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
        svc._restoreAppearance()
      }
    }
    svc._prevProfile = svc.profile
  }

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════
  Component.onCompleted: {
    Store.watch("performance.profile", function(_, value) {
      svc.profile = value
    })
    Store.loadedLater(50, function() {
      svc._syncFromStore()
      svc._ready = true
      if (svc.profile === 2) {
        svc._enterBatterySaver()
      } else {
        svc._applyTLP(svc.profile)
      }
    })
  }

  function _syncFromStore(): void {
    svc.profile = Store.getInt("performance.profile", 1)
  }
}
