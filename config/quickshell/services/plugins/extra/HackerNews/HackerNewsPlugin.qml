pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../../../core"
import "../../../../services"

BasePlugin {
  id: root

  // ── Manifest ─────────────────────────────────────────────────────
  pluginId: "hackernews"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Hacker News",
    description: "Search HN stories — type '/hn'",
    icon: "brand-ycombinator",
    locations: [],
    icons: {},
    settings: []
  })

  readonly property string _favicon: "https://icons.duckduckgo.com/ip3/news.ycombinator.com.ico"

  // ── Public API ───────────────────────────────────────────────────
  readonly property var searchProvider: ({
    id: "hackernews",
    priority: 15,
    command: { prefix: "hn", args: "<query>", description: "Search Hacker News stories", icon: "brand-ycombinator" },
    query: function(text, qid) {
      var q = (text || "").trim()
      if (q.toLowerCase().indexOf("/hn ") !== 0) return []
      var term = q.substring(4).trim()
      if (term.length < 2) return []

      RequestService.get("https://hn.algolia.com/api/v1/search?tags=story&hitsPerPage=6&query="
                       + encodeURIComponent(term), function(resp) {
        var rows = []
        var hits = (resp && resp.ok && resp.data && resp.data.hits) ? resp.data.hits : []
        for (var i = 0; i < hits.length; i++) {
          rows.push((function(h) {
            var url = h.url || ("https://news.ycombinator.com/item?id=" + h.objectID)
            return {
              id: "hn:" + h.objectID,
              label: h.title || "(untitled)",
              sublabel: (h.points || 0) + " points · " + (h.num_comments || 0) + " comments",
              icon: root._favicon,
              iconKind: "image",
              iconFallback: "brand-ycombinator",
              priority: 15,
              source: "hackernews",
              groupLabel: "Hacker News",
              action: function() { ProcessPool.runDetached(["xdg-open", url]) }
            }
          })(hits[i]))
        }
        SearchService.submit(qid, "hackernews", rows)
      }, undefined)
      return []
    }
  })
}
