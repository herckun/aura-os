pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../../core"

Singleton {
  id: svc

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC STATE
  // ═══════════════════════════════════════════════════════════════
  readonly property UPowerDevice display: UPower.displayDevice
  readonly property bool hasBattery: display !== null && display.ready && display.isLaptopBattery

  readonly property real percentage: hasBattery ? display.percentage * 100 : 0
  readonly property bool charging: hasBattery && display.state === UPowerDeviceState.Charging
  readonly property bool discharging: hasBattery && display.state === UPowerDeviceState.Discharging
  readonly property bool fullyCharged: hasBattery && display.state === UPowerDeviceState.FullyCharged

  readonly property real energy: hasBattery ? display.energy : 0
  readonly property real energyCapacity: hasBattery ? display.energyCapacity : 0
  readonly property real changeRate: hasBattery ? display.changeRate : 0
  readonly property real timeToEmpty: hasBattery ? display.timeToEmpty : 0
  readonly property real timeToFull: hasBattery ? display.timeToFull : 0

  readonly property real powerRate: hasBattery && discharging ? Math.abs(changeRate) : 0

  property string modelName: ""
  property bool healthSupported: false
  property real healthPercentage: 0

  readonly property string iconName: {
    if (!hasBattery) return "powerplug"
    if (charging || fullyCharged) return "battery.100.bolt"
    const pct = percentage
    if (pct > 90) return "battery.100"
    if (pct > 65) return "battery.75"
    if (pct > 40) return "battery.50"
    if (pct > 15) return "battery.25"
    return "battery.0"
  }

  readonly property bool lowBattery: hasBattery && !charging && percentage < 20
  readonly property bool criticalBattery: hasBattery && !charging && percentage < 10

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════
  function snapshot(): var {
    return {
      hasBattery: hasBattery,
      percentage: percentage,
      charging: charging,
      discharging: discharging,
      fullyCharged: fullyCharged,
      energy: energy,
      energyCapacity: energyCapacity,
      changeRate: changeRate,
      timeToEmpty: timeToEmpty,
      timeToFull: timeToFull,
      powerRate: powerRate,
      modelName: modelName,
      healthSupported: healthSupported,
      healthPercentage: healthPercentage,
      iconName: iconName,
      lowBattery: lowBattery,
      criticalBattery: criticalBattery
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  INTERNAL STATE
  // ═══════════════════════════════════════════════════════════════
  property var _modelQueryHandle: null

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════
  function _emitUpdated(): void {
  }

  function _findBattery(): void {
    if (_modelQueryHandle && ProcessPool.isRunning(_modelQueryHandle)) return
    try {
      var devs = UPower.devices.values
      for (var i = 0; i < devs.length; i++) {
        var d = devs[i]
        if (d && d.ready && d.isLaptopBattery) {
          modelName = d.model || ""
          healthSupported = d.healthSupported || false
          healthPercentage = d.healthPercentage || 0
          return
        }
      }
    } catch(e) {
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  SIGNAL CONNECTIONS
  // ═══════════════════════════════════════════════════════════════
  onHasBatteryChanged: _emitUpdated()
  onPercentageChanged: _emitUpdated()
  onChargingChanged: _emitUpdated()
  onDischargingChanged: _emitUpdated()
  onFullyChargedChanged: _emitUpdated()
  onEnergyChanged: _emitUpdated()
  onEnergyCapacityChanged: _emitUpdated()
  onChangeRateChanged: _emitUpdated()
  onTimeToEmptyChanged: _emitUpdated()
  onTimeToFullChanged: _emitUpdated()
  onModelNameChanged: _emitUpdated()
  onHealthSupportedChanged: _emitUpdated()
  onHealthPercentageChanged: _emitUpdated()

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════
  Component.onCompleted: svc._findBattery()
}
