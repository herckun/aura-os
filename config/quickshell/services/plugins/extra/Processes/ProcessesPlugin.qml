pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../../../core"
import "../../../../services"

BasePlugin {
  id: root

  // ── Manifest ─────────────────────────────────────────────────────
  pluginId: "processes"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Processes",
    description: "Find and kill a process — prefix with 'kill '",
    icon: "square-x",
    locations: [],
    icons: {},
    settings: []
  })

  // ── Public API ───────────────────────────────────────────────────
  readonly property var searchProvider: ({
    id: "processes",
    priority: 20,
    query: function(text, qid) {
      var q = (text || "").trim()
      if (q.toLowerCase().indexOf("kill ") !== 0) return []
      var term = q.substring(5).trim()
      if (term.length < 2) return []

      ProcessPool.runTracked("search-proc", ["sh", "-c",
        "ps -eo pid=,comm= | grep -i \"$1\" | grep -v ' grep' | head -12", "--", term], {
        id: "search-proc",
        callback: function(r) {
          var lines = (r.stdout || "").trim().split("\n").filter(function(l) { return l.trim().length > 0 })
          var rows = []
          for (var i = 0; i < lines.length; i++) {
            rows.push((function(line) {
              var m = line.trim().match(/^(\d+)\s+(.*)$/)
              if (!m) return null
              var pid = m[1], comm = m[2]
              return {
                id: "proc:" + pid,
                label: comm,
                sublabel: "pid " + pid + " — Enter to kill",
                icon: "square-x",
                iconKind: "symbolic",
                priority: 20,
                source: "processes",
                groupLabel: "Processes",
                action: function() { ProcessPool.runDetached(["kill", pid]) }
              }
            })(lines[i]))
          }
          SearchService.submit(qid, "processes", rows.filter(function(x) { return x !== null }))
        }
      })
      return []
    }
  })
}
