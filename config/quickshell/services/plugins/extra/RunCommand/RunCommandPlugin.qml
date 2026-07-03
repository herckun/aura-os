pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../../../core"
import "../../../../services"

BasePlugin {
  id: root

  // ── Manifest ─────────────────────────────────────────────────────
  pluginId: "runcommand"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Run command",
    description: "Run a shell command — prefix with '>'",
    icon: "terminal-2",
    locations: [],
    icons: {},
    settings: []
  })

  // ── Public API ───────────────────────────────────────────────────
  readonly property var searchProvider: ({
    id: "runcommand",
    priority: 250,
    query: function(text, qid) {
      var raw = text || ""
      if (raw.indexOf(">") !== 0) return []
      var cmd = raw.substring(1).trim()
      if (cmd.length === 0) return []
      return [{
        id: "run:" + cmd,
        label: cmd,
        sublabel: "run in a terminal",
        icon: "terminal-2",
        iconKind: "symbolic",
        priority: 250,
        source: "run",
        groupLabel: "Run command",
        // Keep the terminal open after the command so output stays visible.
        action: function() { ProcessPool.runDetached(["kitty", "--", "sh", "-c", cmd + "; exec $SHELL"]) }
      }]
    }
  })
}
