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
    version: "1.1",
    shellVersion: "2.0",
    name: "DuckDuckGo",
    description: "Web search, site favicons and !bangs in the launcher",
    icon: "search",
    locations: [],
    icons: {},
    settings: []
  })

  // ── Internal state ───────────────────────────────────────────────
  readonly property string _ddgIcon: "https://icons.duckduckgo.com/ip3/duckduckgo.com.ico"

  // Curated bangs — only for a friendly label + favicon; the redirect itself
  // is handled by DuckDuckGo, which knows all 13k+ bangs.
  readonly property var _bangs: ({
    g:      { d: "google.com",            n: "Google" },
    ddg:    { d: "duckduckgo.com",        n: "DuckDuckGo" },
    w:      { d: "wikipedia.org",         n: "Wikipedia" },
    gh:     { d: "github.com",            n: "GitHub" },
    gl:     { d: "gitlab.com",            n: "GitLab" },
    yt:     { d: "youtube.com",           n: "YouTube" },
    so:     { d: "stackoverflow.com",     n: "Stack Overflow" },
    r:      { d: "reddit.com",            n: "Reddit" },
    a:      { d: "amazon.com",            n: "Amazon" },
    aur:    { d: "aur.archlinux.org",     n: "AUR" },
    aw:     { d: "wiki.archlinux.org",    n: "Arch Wiki" },
    npm:    { d: "npmjs.com",             n: "npm" },
    crates: { d: "crates.io",             n: "crates.io" },
    mdn:    { d: "developer.mozilla.org", n: "MDN" },
    maps:   { d: "maps.google.com",       n: "Google Maps" },
    x:      { d: "x.com",                 n: "X" }
  })

  // ── Public API ───────────────────────────────────────────────────
  readonly property var searchProvider: ({
    id: "duckduckgo",
    priority: -10,
    query: function(text, qid) {
      var q = (text || "").trim()
      if (q.length < 2 || q.indexOf("=") === 0) return []

      // Typing a bang ("!" + partial, no search terms yet) → suggest bangs.
      if (/^![A-Za-z0-9.+_-]*$/.test(q)) {
        var sugg = root._bangSuggestions(q.slice(1).toLowerCase())
        return sugg.length ? sugg : [root._bangRow({ key: q.slice(1).toLowerCase(), terms: "" }, q)]
      }

      // A bang with terms ("!gh quickshell") → a single redirect row, no API.
      var bang = root._parseBang(q)
      if (bang) return [root._bangRow(bang, q)]

      // Plain query → instant answers (sparse) merged with autocomplete
      // suggestions (reliable), then the catch-all. Both are async.
      var acc = ({ info: [], sugg: [] })
      function flush() {
        SearchService.submit(qid, "duckduckgo", acc.info.concat(acc.sugg).concat([root._searchRow(q)]))
      }

      RequestService.get("https://api.duckduckgo.com/?q=" + encodeURIComponent(q)
                       + "&format=json&no_html=1&no_redirect=1&skip_disambig=1",
        function(resp) { acc.info = root._parseInstant(resp, q); flush() }, undefined)

      RequestService.get("https://duckduckgo.com/ac/?q=" + encodeURIComponent(q) + "&type=list",
        function(resp) { acc.sugg = root._parseSuggestions(resp, q); flush() }, undefined)

      return [root._searchRow(q)]
    }
  })

  // ── Helpers ──────────────────────────────────────────────────────
  function _open(url: string): void {
    ProcessPool.runDetached(["xdg-open", url])
  }

  function _hostOf(url: string): string {
    var m = (url || "").match(/^[a-z]+:\/\/([^\/]+)/i)
    return m ? m[1].replace(/^www\./, "") : ""
  }

  function _favicon(host: string): string {
    return host ? "https://icons.duckduckgo.com/ip3/" + host + ".ico" : root._ddgIcon
  }

  function _parseBang(q: string): var {
    var m = q.match(/(?:^|\s)!([A-Za-z0-9.+_-]+)/)
    if (!m) return null
    return { key: m[1].toLowerCase(), terms: q.replace(m[0], " ").trim() }
  }

  function _webRow(label, sublabel, url): var {
    var host = root._hostOf(url)
    return {
      id: "ddg:" + url,
      label: label,
      sublabel: sublabel || host,
      icon: root._favicon(host),
      iconKind: "image",
      iconFallback: "world",
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
      icon: root._ddgIcon,
      iconKind: "image",
      iconFallback: "search",
      priority: -20,
      source: "duckduckgo",
      groupLabel: "DuckDuckGo",
      action: function() { root._open("https://duckduckgo.com/?q=" + encodeURIComponent(q)) }
    }
  }

  function _flattenTopics(list): var {
    var out = []
    for (var i = 0; i < list.length; i++) {
      var t = list[i]
      if (t && t.Topics) out = out.concat(t.Topics)
      else if (t) out.push(t)
    }
    return out
  }

  function _parseInstant(resp, q): var {
    var rows = []
    if (!(resp && resp.ok && resp.data && typeof resp.data === "object")) return rows
    var d = resp.data
    if (d.Answer)
      rows.push(root._answerRow(String(d.Answer), d.AnswerType || "answer",
                                d.AbstractURL || "https://duckduckgo.com/?q=" + encodeURIComponent(q)))
    if (d.Definition && d.DefinitionURL)
      rows.push(root._webRow(d.Definition, d.DefinitionSource || "Definition", d.DefinitionURL))
    if (d.AbstractText && d.AbstractURL)
      rows.push(root._webRow(d.Heading || q, d.AbstractText, d.AbstractURL))
    var topics = root._flattenTopics(d.RelatedTopics || [])
    for (var i = 0; i < topics.length && rows.length < 5; i++) {
      var t = topics[i]
      if (t && t.Text && t.FirstURL) rows.push(root._webRow(t.Text, "", t.FirstURL))
    }
    return rows
  }

  function _parseSuggestions(resp, q): var {
    var rows = []
    var list = (resp && resp.ok && resp.data && resp.data.length > 1) ? resp.data[1] : []
    var ql = q.toLowerCase()
    for (var i = 0; i < list.length && rows.length < 6; i++) {
      var s = list[i]
      if (!s || s.toLowerCase() === ql) continue
      rows.push((function(term) {
        return {
          id: "ddg:ac:" + term,
          label: term,
          sublabel: "",
          icon: "search",
          iconKind: "symbolic",
          priority: -15,
          source: "duckduckgo",
          groupLabel: "DuckDuckGo suggestions",
          action: function() { root._open("https://duckduckgo.com/?q=" + encodeURIComponent(term)) }
        }
      })(s))
    }
    return rows
  }

  function _answerRow(text, type, url): var {
    return {
      id: "ddg:answer",
      label: text,
      sublabel: type,
      icon: root._ddgIcon,
      iconKind: "image",
      iconFallback: "search",
      priority: 60,
      source: "duckduckgo",
      groupLabel: "DuckDuckGo",
      action: function() { root._open(url) }
    }
  }

  function _bangRow(bang, fullQuery): var {
    var info = root._bangs[bang.key]
    var name = info ? info.n : "!" + bang.key
    var host = info ? info.d : "duckduckgo.com"
    return {
      id: "ddg:bang:" + bang.key,
      label: bang.terms.length ? "Search " + name + " for \"" + bang.terms + "\"" : "Open " + name,
      sublabel: "!" + bang.key + " bang",
      icon: root._favicon(host),
      iconKind: "image",
      iconFallback: "search",
      priority: 50,
      source: "duckduckgo",
      groupLabel: "DuckDuckGo",
      action: function() { root._open("https://duckduckgo.com/?q=" + encodeURIComponent(fullQuery)) }
    }
  }

  function _bangSuggestions(prefix): var {
    var out = []
    var keys = Object.keys(root._bangs)
    for (var i = 0; i < keys.length && out.length < 8; i++) {
      var k = keys[i]
      if (prefix.length !== 0 && k.indexOf(prefix) !== 0) continue
      out.push((function(bk) {
        var info = root._bangs[bk]
        return {
          id: "ddg:bangsug:" + bk,
          label: "!" + bk + " — " + info.n,
          sublabel: info.d,
          icon: root._favicon(info.d),
          iconKind: "image",
          iconFallback: "search",
          priority: -5,
          source: "duckduckgo",
          groupLabel: "DuckDuckGo bangs",
          action: function() { root._open("https://duckduckgo.com/?q=!" + bk) }
        }
      })(k))
    }
    return out
  }
}
