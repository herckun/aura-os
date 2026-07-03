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
  property bool hasDevice: false
  property real brightness: 0.7
  property int brightnessPct: 70
  property string brightnessPath: ""

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════
  function poll(): void {
    ProcessPool.runQueued("Brightness detect", ["ls", "/sys/class/backlight/"], {
      id: "brightness-detect",
      silent: true,
      callback: function(r) {
        var text = r.stdout.trim()
        if (text.length > 0) {
          svc.hasDevice = true
          var dev = text.split("\n")[0].trim()
          svc.brightnessPath = "/sys/class/backlight/" + dev + "/brightness"
          ProcessPool.runQueued("Brightness read", "b=$(brightnessctl g 2>/dev/null); m=$(brightnessctl m 2>/dev/null); echo \"$b $m\"", {
            id: "brightness-read",
            shell: true,
            silent: true,
            callback: function(r2) {
              var parts = r2.stdout.trim().split(" ")
              if (parts.length >= 2) {
                var b = parseFloat(parts[0])
                var m = parseFloat(parts[1])
                if (m > 1) {
                  svc.brightness = Math.round(b / m * 100) / 100
                  svc.brightnessPct = Math.round(svc.brightness * 100)
                }
              }
            }
          })
        } else {
          svc.hasDevice = false
        }
      }
    })
  }

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════
  function setBrightness(val: real): void {
    if (!svc.hasDevice) return
    var pct = Math.round(Math.max(5, Math.min(100, val * 100)))
    svc.brightness = val
    svc.brightnessPct = pct
    ProcessPool.runDetached(["brightnessctl", "set", pct + "%"])
  }

  function brighter(): void {
    svc.setBrightness(Math.min(1, svc.brightness + 0.05))
  }

  function dimmer(): void {
    svc.setBrightness(Math.max(0.05, svc.brightness - 0.05))
  }

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════
  Component.onCompleted: svc.poll()
}
