pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../../../core"
import "../../../../services"

BasePlugin {
  id: root

  // ── Manifest ─────────────────────────────────────────────────────
  pluginId: "duckduckgo"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "DuckDuckGo",
    description: "Web search results in the launcher",
    icon: "search",
    locations: [],
    icons: {},
    settings: []
  })

  // ── Public state ─────────────────────────────────────────────────

  // ── Internal state ───────────────────────────────────────────────

  // ── Signal handlers ──────────────────────────────────────────────

  // ── Public API ───────────────────────────────────────────────────
  readonly property var searchProvider: ({
    id: "duckduckgo",
    priority: -10,
    query: function(text, qid) {
      var q = (text || "").trim()
      if (q.length < 2 || q.indexOf("=") === 0) return []

      var url = "https://api.duckduckgo.com/?q=" + encodeURIComponent(q)
              + "&format=json&no_html=1&no_redirect=1&skip_disambig=1"
      RequestService.get(url, function(resp) {
        var rows = []
        if (resp && resp.ok && resp.data && typeof resp.data === "object") {
          var d = resp.data
          if (d.AbstractText && d.AbstractURL)
            rows.push(root._webRow(d.Heading || q, d.AbstractText, d.AbstractURL))
          var topics = d.RelatedTopics || []
          for (var i = 0; i < topics.length && rows.length < 5; i++) {
            var t = topics[i]
            if (t && t.Text && t.FirstURL) rows.push(root._webRow(t.Text, "", t.FirstURL))
          }
        }
        rows.push(root._searchRow(q))
        SearchService.submit(qid, "duckduckgo", rows)
      }, undefined)

      return [root._searchRow(q)]
    }
  })

  // ── Helpers ──────────────────────────────────────────────────────
  function _open(url: string): void {
    ProcessPool.runDetached(["xdg-open", url])
  }

  function _webRow(label, sublabel, url): var {
    return {
      id: "ddg:" + url,
      label: label,
      sublabel: sublabel,
      icon: "world",
      iconKind: "symbolic",
      priority: -10,
      source: "duckduckgo",
      groupLabel: "DuckDuckGo",
      action: function() { root._open(url) }
    }
  }

  function _searchRow(q): var {
    return {
      id: "ddg:search",
      label: "Search DuckDuckGo for \"" + q + "\"",
      sublabel: "",
      icon: "search",
      iconKind: "symbolic",
      priority: -20,
      source: "duckduckgo",
      groupLabel: "DuckDuckGo",
      action: function() { root._open("https://duckduckgo.com/?q=" + encodeURIComponent(q)) }
    }
  }

  // ── Timers ───────────────────────────────────────────────────────

  // ── Lifecycle ────────────────────────────────────────────────────
}
