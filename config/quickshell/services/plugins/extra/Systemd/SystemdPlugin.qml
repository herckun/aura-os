pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../../../core"
import "../../../../services"

BasePlugin {
  id: root

  // ── Manifest ─────────────────────────────────────────────────────
  pluginId: "systemd"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Systemd (user)",
    description: "Restart a user service — type '/service'",
    icon: "settings-automation",
    locations: [],
    icons: {},
    settings: []
  })

  // ── Public API ───────────────────────────────────────────────────
  readonly property var searchProvider: ({
    id: "systemd",
    priority: 20,
    command: { prefix: "service", args: "<unit>", description: "Restart a user service", icon: "settings-automation" },
    query: function(text, qid) {
      var q = (text || "").trim()
      if (q.toLowerCase().indexOf("/service ") !== 0) return []
      var term = q.substring(9).trim()
      if (term.length < 2) return []

      var script = "systemctl --user list-units --type=service --all --no-legend --plain 2>/dev/null"
                 + " | awk '{print $1\"\\t\"$3}' | grep -i \"$1\" | head -12"
      ProcessPool.runTracked("search-systemd", ["sh", "-c", script, "--", term], {
        id: "search-systemd",
        callback: function(r) {
          var lines = (r.stdout || "").trim().split("\n").filter(function(l) { return l.length > 0 })
          var rows = []
          for (var i = 0; i < lines.length; i++) {
            rows.push((function(line) {
              var f = line.split("\t")
              var unit = f[0]
              return {
                id: "unit:" + unit,
                label: unit,
                sublabel: (f[1] || "") + " — Enter to restart",
                icon: "settings-automation",
                iconKind: "symbolic",
                priority: 20,
                source: "systemd",
                groupLabel: "Systemd (user)",
                action: function() { ProcessPool.runDetached(["systemctl", "--user", "restart", unit]) }
              }
            })(lines[i]))
          }
          SearchService.submit(qid, "systemd", rows)
        }
      })
      return []
    }
  })
}
