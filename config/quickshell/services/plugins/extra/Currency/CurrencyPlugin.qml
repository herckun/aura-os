pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../../../core"
import "../../../../services"

BasePlugin {
  id: root

  // ── Manifest ─────────────────────────────────────────────────────
  pluginId: "currency"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Currency",
    description: "Convert currencies — e.g. '100 usd to eur'",
    icon: "cash",
    locations: [],
    icons: {},
    settings: []
  })

  // ── Public API ───────────────────────────────────────────────────
  readonly property var searchProvider: ({
    id: "currency",
    priority: 220,
    query: function(text, qid) {
      var m = (text || "").trim().match(/^([0-9]*\.?[0-9]+)?\s*([a-zA-Z]{3})\s+(?:to|in)\s+([a-zA-Z]{3})$/)
      if (!m) return []
      var amount = m[1] ? parseFloat(m[1]) : 1
      var from = m[2].toUpperCase(), to = m[3].toUpperCase()

      RequestService.get("https://api.frankfurter.dev/v1/latest?amount=" + amount
                       + "&base=" + from + "&symbols=" + to, function(resp) {
        var rows = []
        if (resp && resp.ok && resp.data && resp.data.rates && resp.data.rates[to] !== undefined) {
          var val = Math.round(resp.data.rates[to] * 100) / 100
          rows.push({
            id: "cur:" + from + to,
            label: val + " " + to,
            sublabel: amount + " " + from + " · " + (resp.data.date || "") + " — Enter to copy",
            icon: "cash",
            iconKind: "symbolic",
            priority: 220,
            source: "currency",
            groupLabel: "Currency",
            action: function() { ProcessPool.runDetached(["sh", "-c", "printf %s \"$1\" | wl-copy", "--", String(val)]) }
          })
        }
        SearchService.submit(qid, "currency", rows)
      }, undefined)
      return []
    }
  })
}
