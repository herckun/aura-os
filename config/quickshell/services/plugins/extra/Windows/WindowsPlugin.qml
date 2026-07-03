pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../../../core"
import "../../../../services"

BasePlugin {
  id: root

  // ── Manifest ─────────────────────────────────────────────────────
  pluginId: "windows"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Windows",
    description: "Switch to an open window",
    icon: "layout-grid",
    locations: [],
    icons: {},
    settings: []
  })

  // ── Public API ───────────────────────────────────────────────────
  readonly property var searchProvider: ({
    id: "windows",
    priority: 60,
    query: function(text, qid) {
      var q = (text || "").trim().toLowerCase()
      if (q.length < 2 || q.indexOf("=") === 0 || /(?:^|\s)!\S/.test(q)) return []

      var rows = []
      var clients = HyprlandService.clients || []
      for (var i = 0; i < clients.length && rows.length < 8; i++) {
        var c = clients[i]
        if (!c || !c.address || c.mapped === false) continue
        var title = c.title || c["class"] || "Window"
        var cls = c["class"] || ""
        if (title.toLowerCase().indexOf(q) < 0 && cls.toLowerCase().indexOf(q) < 0) continue
        rows.push((function(addr, ti, cl, ws) {
          return {
            id: "win:" + addr,
            label: ti,
            sublabel: cl + (ws ? "  ·  ws " + ws : ""),
            icon: cl.toLowerCase(),
            iconKind: "app",
            iconFallback: "app-window",
            priority: 60,
            source: "windows",
            groupLabel: "Windows",
            action: function() { HyprlandService.focusWindow(addr) }
          }
        })(c.address, title, cls, (c.workspace && c.workspace.id) || 0))
      }
      return rows
    }
  })
}
