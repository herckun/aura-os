pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../../../core"
import "../../../../services"

BasePlugin {
  id: root

  // ── Manifest ─────────────────────────────────────────────────────
  pluginId: "power"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Power",
    description: "Lock, logout, suspend, reboot, shutdown",
    icon: "power",
    locations: [],
    icons: {},
    settings: []
  })

  // ── Internal state ───────────────────────────────────────────────
  readonly property var _actions: [
    { keys: ["lock", "screen"],            label: "Lock",     icon: "lock",         cmd: ["loginctl", "lock-session"] },
    { keys: ["logout", "log out", "exit"], label: "Log out",  icon: "logout",       cmd: ["hyprctl", "dispatch", "exit"] },
    { keys: ["suspend", "sleep"],          label: "Suspend",  icon: "moon",         cmd: ["systemctl", "suspend"] },
    { keys: ["hibernate"],                 label: "Hibernate", icon: "snowflake",   cmd: ["systemctl", "hibernate"] },
    { keys: ["reboot", "restart"],         label: "Reboot",   icon: "refresh",      cmd: ["systemctl", "reboot"] },
    { keys: ["shutdown", "power off", "poweroff"], label: "Shut down", icon: "power", cmd: ["systemctl", "poweroff"] }
  ]

  // ── Public API ───────────────────────────────────────────────────
  readonly property var searchProvider: ({
    id: "power",
    priority: 40,
    query: function(text, qid) {
      var q = (text || "").trim().toLowerCase()
      if (q.length < 2) return []

      var rows = []
      for (var i = 0; i < root._actions.length; i++) {
        var a = root._actions[i]
        var hit = false
        for (var k = 0; k < a.keys.length; k++) {
          if (a.keys[k].indexOf(q) === 0 || a.keys[k].indexOf(" " + q) >= 0) { hit = true; break }
        }
        if (!hit) continue
        rows.push((function(act) {
          return {
            id: "power:" + act.label,
            label: act.label,
            sublabel: act.cmd.join(" "),
            icon: act.icon,
            iconKind: "symbolic",
            priority: 40,
            source: "power",
            groupLabel: "Power",
            action: function() { ProcessPool.runDetached(act.cmd) }
          }
        })(a))
      }
      return rows
    }
  })
}
