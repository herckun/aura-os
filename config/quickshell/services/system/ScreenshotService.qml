pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"
import "../"

Singleton {
  id: svc

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC STATE
  // ═══════════════════════════════════════════════════════════════

  property bool available: false
  property bool capturing: false

  signal captured()

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════

  function captureRegion(): void {
    _doCapture("area", "grimblast copy area")
  }

  function captureScreen(): void {
    _doCapture("screen", "grimblast copy screen")
  }

  function captureOutput(): void {
    _doCapture("output", "grimblast copy output")
  }

  function captureWindow(): void {
    capturing = true
    HyprlandService.hyprctlJson("activewindow", "ss-geom", function(d, r) {
      if (!d || d.at === undefined || d.size === undefined) {
        Logger.warn("screenshot", "Failed to get window geometry")
        capturing = false
        NotificationService.systemNotify("SCREENSHOT", "Failed to capture window", 2)
        return
      }
      var geom = d.at[0] + "," + d.at[1] + " " + d.size[0] + "x" + d.size[1]
      var path = _buildPath()
      var cmd = 'mkdir -p "$(dirname "' + path + '")" && grim -g "' + geom + '" "' + path + '"'
      _executeCapture("window", cmd, path)
    })
  }

  // ═══════════════════════════════════════════════════════════════
  //  INTERNAL STATE
  // ═══════════════════════════════════════════════════════════════

  readonly property string _picturesDir: Quickshell.env("XDG_PICTURES_DIR") || (Quickshell.env("HOME") + "/Pictures")

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════

  function _buildPath(): string {
    var d = new Date()
    var ts = d.getFullYear() + "" +
      String(d.getMonth() + 1).padStart(2, "0") +
      String(d.getDate()).padStart(2, "0") + "-" +
      String(d.getHours()).padStart(2, "0") +
      String(d.getMinutes()).padStart(2, "0") +
      String(d.getSeconds()).padStart(2, "0")
    return _picturesDir + "/screenshot-" + ts + ".png"
  }

  function _doCapture(type: string, grimblastCmd: string): void {
    capturing = true
    ProcessPool.runQueued("Screenshot " + type, grimblastCmd, {
      id: "screenshot-" + type,
      shell: true,
      silent: true,
      callback: function(r) {
        capturing = false
        if (r.exitCode === 0) {
          svc.captured()
          NotificationService.systemNotify("SCREENSHOT", "Screenshot saved to clipboard", 1)
        } else {
          NotificationService.systemNotify("SCREENSHOT", "Screenshot failed", 2)
        }
      }
    })
  }

  function _executeCapture(type: string, cmd: string, path: string): void {
    ProcessPool.runQueued("Screenshot " + type, cmd, {
      id: "screenshot-" + type,
      shell: true,
      silent: true,
      callback: function(r) {
        capturing = false
        if (r.exitCode === 0) {
          svc.captured()
          NotificationService.systemNotify("SCREENSHOT", "Screenshot saved: " + path, 1)
        } else {
          NotificationService.systemNotify("SCREENSHOT", "Screenshot failed", 2)
        }
      }
    })
  }

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════

  Component.onCompleted: {
    ProcessPool.runTracked("Screenshot check", "command -v grimblast >/dev/null 2>&1 && echo AVAILABLE || echo MISSING", {
      id: "ss-check",
      shell: true,
      callback: function(r) {
        svc.available = r.stdout.trim() === "AVAILABLE"
      }
    })
  }
}
