pragma Singleton
import QtQml
import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"
import "../system"

Singleton {
  id: svc

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC STATE
  // ═══════════════════════════════════════════════════════════════
  property var clients: ([])
  property var workspaces: ([])
  property var activeWorkspace: null
  property var activeClient: null
  property int activeWsId: 1

  // ═══════════════════════════════════════════════════════════════
  //  INTERNAL STATE
  // ═══════════════════════════════════════════════════════════════
  property string _his: ""
  property var _pollHandle: null

  readonly property int _basePollInterval: 30000

  readonly property int _pollInterval: PerformanceService.scaleInterval(_basePollInterval)

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════
  function poll(): void {
    if (_pollHandle && ProcessPool.isRunning(_pollHandle)) return
    var script = "C=$(hyprctl clients -j 2>/dev/null || echo '[]'); " +
      "W=$(hyprctl workspaces -j 2>/dev/null || echo '[]'); " +
      "A=$(hyprctl activeworkspace -j 2>/dev/null || echo 'null'); " +
      "printf '{\"clients\":%s,\"workspaces\":%s,\"active\":%s}' \"$C\" \"$W\" \"$A\""
    _pollHandle = ProcessPool.runTracked("Hyprland poll", script, {
      id: "hypr-poll",
      shell: true,
      callback: function(r) {
        svc._pollHandle = null
        var text = r.stdout
        if (!text || !text.trim()) return
        try {
          var data = JSON.parse(text.trim())
          if (Array.isArray(data.clients)) svc.clients = data.clients
          if (Array.isArray(data.workspaces)) svc.workspaces = data.workspaces.sort((a, b) => a.id - b.id)
          svc.activeWorkspace = data.active || null
          if (svc.activeWorkspace) svc.activeWsId = svc.activeWorkspace.id
        } catch (e) {
        }
      }
    })
  }

  function setWorkspace(id: int): void {
    ProcessPool.runDetached(["sh", "-c", "hyprctl dispatch 'hl.dsp.focus({workspace=\"" + String(id) + "\"})'"])
  }

  function focusWindow(address: string): void {
    ProcessPool.runDetached(["sh", "-c", "hyprctl dispatch 'hl.dsp.focus({window=\"address:" + address + "\"})'"])
  }

  function closeWindow(address: string): void {
    ProcessPool.runDetached(["sh", "-c", "hyprctl dispatch 'hl.dsp.window.close({window=\"address:" + address + "\"})'"])
  }

  function hyprctlJson(query: string, id: string, callback: var): void {
    ProcessPool.runTracked("hyprctl " + query, ["hyprctl", "-j", query], {
      id: id,
      callback: function(r) {
        var data = null
        if (r.exitCode === 0) {
          try {
            data = JSON.parse((r.stdout || "").trim())
          } catch (e) {}
        }
        if (callback) callback(data, r)
      }
    })
  }

  // ═══════════════════════════════════════════════════════════════
  //  CONFIG WRITE API
  // ═══════════════════════════════════════════════════════════════

  function writeConfig(path: string, content: string, callback: var): void {
    ProcessPool.runQueued("Write config", [
      "sh", "-c",
      "tmp=\"$1.tmp\" && printf '%s' \"$2\" > \"$tmp\" && mv \"$tmp\" \"$1\"",
      "--", path, content
    ], {
      id: "config-write",
      silent: true,
      callback: function(r) {
        if (r.exitCode !== 0) {
          Logger.warn("hyprland", "Failed to write " + path + ": " + (r.stderr || ""))
        }
        if (callback) callback(r)
      }
    })
  }

  function reload(callback: var): void {
    ProcessPool.runQueued("Hyprland reload", ["hyprctl", "reload"], {
      id: "hypr-reload",
      silent: true,
      callback: function(r) {
        if (callback) callback(r)
      }
    })
  }

  function writeAndReload(path: string, content: string, callback: var): void {
    writeConfig(path, content, function(r) {
      if (r.exitCode === 0) {
        reload(callback)
      } else {
        if (callback) callback(r)
      }
    })
  }

  function modifyConfig(path: string, replacements: var, callback: var): void {
    ProcessPool.runQueued("Read config", ["cat", path], {
      id: "config-read-" + path,
      silent: true,
      callback: function(r) {
        if (r.exitCode !== 0) {
          Logger.warn("hyprland", "Failed to read " + path)
          if (callback) callback(r)
          return
        }
        var content = r.stdout || ""
        for (var i = 0; i < replacements.length; i++) {
          var sub = replacements[i]
          content = content.replace(sub.pattern, sub.replacement)
        }
        writeAndReload(path, content, callback)
      }
    })
  }

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════
  function _startSocket(): void {
    var his = Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")
    if (!his) return
    WatchService.register("hypr-events",
      "python3 " + AppInfo.configHome + "/features/hypr/hyprland-events.py",
      function(line) {
        line = line.trim()
        if (!line) return

        var parts = line.split(">>")
        if (parts.length < 2) return
        var event = parts[0]
        var data = parts.slice(1).join(">>")

        switch (event) {
          case "workspace":
            var id = parseInt(data)
            if (!isNaN(id)) svc.activeWsId = id
            svc.poll()
            break
          case "focusedmon":
            var monParts = data.split(",")
            if (monParts.length > 1) {
              var wsId = parseInt(monParts[1].trim())
              if (!isNaN(wsId)) svc.activeWsId = wsId
            }
            svc.poll()
            break
          case "activewindow":
            var winParts = data.split(",")
            if (winParts.length > 0) {
              svc.activeClient = { "class": winParts[0], "title": winParts.slice(1).join(",") }
            }
            svc.poll()
            break
          case "openwindow":
          case "closewindow":
          case "movewindow":
          case "changefloatingmode":
          case "fullscreen":
            svc.poll()
            break
          default:
            break
        }
      })
  }

  // ═══════════════════════════════════════════════════════════════
  //  SIGNAL CONNECTIONS
  // ═══════════════════════════════════════════════════════════════
  onActiveWsIdChanged: {
  }

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════
  Component.onCompleted: {
    var his = Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")
    if (!his) {
      var xdg = Quickshell.env("XDG_RUNTIME_DIR") || ("/run/user/" + Quickshell.env("UID"))
      his = xdg + "/hypr/*"
    }
    svc._his = his
    svc.poll()
    svc._startSocket()
  }

  // ═══════════════════════════════════════════════════════════════
  //  TIMERS
  // ═══════════════════════════════════════════════════════════════
  Timer {
    interval: svc._pollInterval
    running: true
    repeat: true
    onTriggered: svc.poll()
  }
}
