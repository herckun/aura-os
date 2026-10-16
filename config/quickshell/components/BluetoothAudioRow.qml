import QtQuick
import "../styles"
import "../services"
import "../components"

// Core Bluetooth-audio device row: any Bluetooth audio endpoint (headphones,
// earbuds, speakers, soundbars, headsets, mics, ...) reported by PipeWire.
DeviceRow {
  id: root

  readonly property int pct: AudioService.bluetoothBattery

  icon: "bluetooth"
  name: AudioService.bluetoothName !== "" ? AudioService.bluetoothName : "BLUETOOTH AUDIO"
  subtitle: AudioService.bluetoothActive ? "OUTPUT ACTIVE" : "CONNECTED"
  active: AudioService.bluetoothConnected
  tagLabel: _tagLabel()
  tagIcon: AudioService.bluetoothHasBattery ? _batIcon(pct) : ""
  tagTextColor: _batColor(pct)

  function _tagLabel(): string {
    if (!AudioService.bluetoothHasBattery) return ""
    if (AudioService.bluetoothSplitBattery)
      return "L:" + AudioService.bluetoothBatteryLeft + "% R:" + AudioService.bluetoothBatteryRight + "%"
    return pct + "%"
  }

  function _batIcon(p: int): string {
    if (p < 0) return ""
    if (p > 80) return "battery-full"
    if (p > 40) return "battery-medium"
    if (p > 15) return "battery-low"
    return "battery-empty"
  }

  function _batColor(p: int): color {
    if (p < 0) return Theme.textDisabled
    if (p < 20) return Theme.error
    if (p < 40) return Theme.warning
    return Theme.success
  }
}
