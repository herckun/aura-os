pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../../../core"
import "../../../../services"

BasePlugin {
  id: root

  // ── Manifest ─────────────────────────────────────────────────────
  pluginId: "wikipedia"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Wikipedia",
    description: "Article summaries in the launcher",
    icon: "book",
    locations: [],
    icons: {},
    settings: []
  })

  // ── Internal state ───────────────────────────────────────────────
  readonly property string _favicon: "https://icons.duckduckgo.com/ip3/wikipedia.org.ico"
  // Wikimedia asks for a descriptive User-Agent (generic curl UAs get throttled).
  readonly property var _headers: ({ "User-Agent": "aura-os-shell (https://github.com/herckun/aura-os)" })

  // ── Public API ───────────────────────────────────────────────────
  readonly property var searchProvider: ({
    id: "wikipedia",
    priority: 10,
    query: function(text, qid) {
      var q = (text || "").trim()
      // Skip calc (=…) and bangs (!… anywhere); too-short queries won't match an article.
      if (q.length < 3 || q.indexOf("=") === 0 || /(?:^|\s)!\S/.test(q)) return []

      var url = "https://en.wikipedia.org/api/rest_v1/page/summary/"
              + encodeURIComponent(q) + "?redirect=true"
      RequestService.get(url, function(resp) {
        var rows = []
        if (resp && resp.ok && resp.data && resp.data.type === "standard" && resp.data.extract)
          rows.push(root._summaryRow(resp.data))
        SearchService.submit(qid, "wikipedia", rows)
      }, root._headers)

      return []
    }
  })

  // ── Helpers ──────────────────────────────────────────────────────
  function _trim(s, n): string {
    s = (s || "").replace(/\s+/g, " ").trim()
    return s.length > n ? s.slice(0, n - 1).trim() + "…" : s
  }

  function _summaryRow(d): var {
    var page = (d.content_urls && d.content_urls.desktop && d.content_urls.desktop.page)
             ? d.content_urls.desktop.page
             : "https://en.wikipedia.org/wiki/" + encodeURIComponent(d.title || "")
    return {
      id: "wiki:" + (d.title || page),
      label: d.title || "",
      sublabel: root._trim(d.extract, 320),
      wrap: true,
      icon: (d.thumbnail && d.thumbnail.source) ? d.thumbnail.source : root._favicon,
      iconKind: "image",
      iconFallback: "book",
      priority: 10,
      source: "wikipedia",
      groupLabel: "Wikipedia",
      action: function() { ProcessPool.runDetached(["xdg-open", page]) }
    }
  }
}
