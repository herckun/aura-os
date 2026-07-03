pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../../../core"
import "../../../../services"

BasePlugin {
  id: root

  // ── Manifest ─────────────────────────────────────────────────────
  pluginId: "tldr"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "tldr",
    description: "Command cheat sheet — type '/tldr'",
    icon: "terminal",
    locations: [],
    icons: {},
    settings: []
  })

  // ── Public API ───────────────────────────────────────────────────
  readonly property var searchProvider: ({
    id: "tldr",
    priority: 18,
    command: { prefix: "tldr", args: "<command>", description: "Command cheat sheet", icon: "terminal" },
    query: function(text, qid) {
      var q = (text || "").trim()
      if (q.toLowerCase().indexOf("/tldr ") !== 0) return []
      var cmd = q.substring(6).trim()
      if (cmd.length < 1) return []

      ProcessPool.runTracked("search-tldr", ["sh", "-c",
        "command -v tldr >/dev/null 2>&1 && tldr \"$1\" 2>/dev/null", "--", cmd], {
        id: "search-tldr",
        callback: function(r) {
          var out = (r.stdout || "").replace(/\x1b\[[0-9;]*m/g, "").replace(/\s+/g, " ").trim()
          var rows = []
          if (out.length > 0) {
            rows.push({
              id: "tldr:" + cmd,
              label: cmd,
              sublabel: out.length > 300 ? out.slice(0, 299).trim() + "…" : out,
              icon: "terminal",
              iconKind: "symbolic",
              priority: 18,
              source: "tldr",
              groupLabel: "tldr",
              wrap: true,
              action: function() { ProcessPool.runDetached(["xdg-open", "https://man.archlinux.org/man/" + encodeURIComponent(cmd)]) }
            })
          }
          SearchService.submit(qid, "tldr", rows)
        }
      })
      return []
    }
  })
}
