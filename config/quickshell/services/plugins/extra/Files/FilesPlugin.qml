pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../../../core"
import "../../../../services"

BasePlugin {
  id: root

  // ── Manifest ─────────────────────────────────────────────────────
  pluginId: "files"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Files",
    description: "Find files by name — prefix with 'f '",
    icon: "file-search",
    locations: [],
    icons: {},
    settings: []
  })

  // ── Public API ───────────────────────────────────────────────────
  readonly property var searchProvider: ({
    id: "files",
    priority: 20,
    query: function(text, qid) {
      var q = (text || "").trim()
      if (q.toLowerCase().indexOf("f ") !== 0) return []
      var term = q.substring(2).trim()
      if (term.length < 2) return []

      // fd if present, else find; both capped and rooted at $HOME.
      var script = "if command -v fd >/dev/null 2>&1; then "
                 + "fd -t f --color never \"$1\" \"$HOME\" 2>/dev/null | head -15; else "
                 + "find \"$HOME\" -maxdepth 6 -type f -iname \"*$1*\" 2>/dev/null | head -15; fi"
      ProcessPool.runTracked("search-files", ["sh", "-c", script, "--", term], {
        id: "search-files",
        callback: function(r) {
          var lines = (r.stdout || "").trim().split("\n").filter(function(l) { return l.length > 0 })
          var rows = []
          for (var i = 0; i < lines.length; i++) {
            rows.push((function(path) {
              var parts = path.split("/")
              return {
                id: "file:" + path,
                label: parts[parts.length - 1],
                sublabel: parts.slice(0, -1).join("/"),
                icon: "file",
                iconKind: "symbolic",
                priority: 20,
                source: "files",
                groupLabel: "Files",
                action: function() { ProcessPool.runDetached(["xdg-open", path]) }
              }
            })(lines[i]))
          }
          SearchService.submit(qid, "files", rows)
        }
      })
      return []
    }
  })
}
