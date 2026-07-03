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
    description: "Find files by name — type '/find'",
    icon: "file-search",
    locations: [],
    icons: {},
    settings: []
  })

  // ── Public API ───────────────────────────────────────────────────
  readonly property var searchProvider: ({
    id: "files",
    priority: 20,
    command: { prefix: "find", args: "<name>", description: "Find files by name", icon: "file-search" },
    query: function(text, qid) {
      var q = (text || "").trim()
      if (q.toLowerCase().indexOf("/find ") !== 0) return []
      var term = q.substring(6).trim()
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
              var dir = parts.slice(0, -1).join("/") || "/"
              return {
                id: "file:" + path,
                label: parts[parts.length - 1],
                sublabel: dir,
                icon: "file",
                iconKind: "symbolic",
                priority: 20,
                source: "files",
                groupLabel: "Files",
                // Reveal in the GUI file manager with the file selected, via the
                // freedesktop FileManager1 interface — bypasses the inode/directory
                // mime handler, which is often a terminal (so xdg-open <dir> fails).
                action: function() {
                  var uri = "file://" + path.split("/").map(encodeURIComponent).join("/")
                  ProcessPool.runDetached(["gdbus", "call", "--session",
                    "--dest", "org.freedesktop.FileManager1",
                    "--object-path", "/org/freedesktop/FileManager1",
                    "--method", "org.freedesktop.FileManager1.ShowItems",
                    '["' + uri + '"]', ""])
                }
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
