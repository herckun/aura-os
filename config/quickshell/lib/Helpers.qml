pragma Singleton
import QtQuick

QtObject {

  function formatDurationHm(secs: real): string {
    if (secs <= 0) return "\u2014"
    var h = Math.floor(secs / 3600)
    var m = Math.floor((secs % 3600) / 60)
    if (h > 0) return h + "H " + m + "M"
    return m + "M"
  }

  function formatTimeMs(secs: real): string {
    var s = Math.floor(secs)
    var m = Math.floor(s / 60)
    s = s % 60
    return (m < 10 ? "0" + m : "" + m) + ":" + (s < 10 ? "0" : "") + s
  }

  function formatWatts(watts: real): string {
    var abs = Math.abs(watts)
    if (abs >= 1) return abs.toFixed(1) + " W"
    return (abs * 1000).toFixed(0) + " mW"
  }

  function formatBytes(bytes: var): string {
    var num = parseInt(bytes) || 0
    if (num >= 1073741824) {
      return (num / 1073741824).toFixed(1) + " GB"
    }
    if (num >= 1048576) {
      return Math.round(num / 1048576) + " MB"
    }
    if (num > 0) {
      return Math.round(num / 1024) + " KB"
    }
    return "N/A"
  }

  function relativeTime(date: var): string {
    var diff = (new Date() - date) / 1000
    if (diff < 60) return "NOW"
    if (diff < 3600) return Math.floor(diff / 60) + "M"
    if (diff < 86400) return Math.floor(diff / 3600) + "H"
    return Math.floor(diff / 86400) + "D"
  }

  function batteryStatusLabel(charging: bool, discharging: bool): string {
    if (charging) return "CHARGING"
    if (discharging) return "DRAINING"
    return "FULL"
  }

  function batteryStatusColor(charging: bool, discharging: bool, theme: var): color {
    if (charging) return theme.success
    if (discharging) return theme.warning
    return theme.success
  }

  function networkIcon(online: bool, ethernet: bool, strength: int): string {
    if (!online) return "\u2298"
    if (ethernet) return "\u2291"
    if (strength > 75) return "\u2299"
    if (strength > 50) return "\u229A"
    if (strength > 25) return "\u25D0"
    return "\u25D1"
  }

  function easeInOutCubic(t: real): real {
    return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2
  }

  function colorToName(c: color, predefinedAccents: var): string {
    for (var i = 0; i < predefinedAccents.length; i++) {
      if (predefinedAccents[i].color.toUpperCase() === c.toString().toUpperCase())
        return predefinedAccents[i].name
    }
    return "CUSTOM"
  }
}
