pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../../../core"
import "../../../../services"

BasePlugin {
  id: root

  // ── Manifest ─────────────────────────────────────────────────────
  pluginId: "archpackages"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Arch packages",
    description: "Search repo + AUR — prefix with 'pkg '",
    icon: "package",
    locations: [],
    icons: {},
    settings: []
  })

  // ── Public API ───────────────────────────────────────────────────
  readonly property var searchProvider: ({
    id: "archpackages",
    priority: 12,
    query: function(text, qid) {
      var q = (text || "").trim()
      if (q.toLowerCase().indexOf("pkg ") !== 0) return []
      var term = q.substring(4).trim()
      if (term.length < 2) return []

      var acc = ({ repo: [], aur: [] })
      function flush() { SearchService.submit(qid, "archpackages", acc.repo.concat(acc.aur)) }

      ProcessPool.runTracked("search-pacman", ["sh", "-c", "pacman -Ss \"$1\" 2>/dev/null | head -24", "--", term], {
        id: "search-pacman",
        callback: function(r) { acc.repo = root._parsePacman(r.stdout || ""); flush() }
      })

      RequestService.get("https://aur.archlinux.org/rpc/v5/search/" + encodeURIComponent(term) + "?by=name", function(resp) {
        var rows = []
        var results = (resp && resp.ok && resp.data && resp.data.results) ? resp.data.results : []
        for (var i = 0; i < results.length && rows.length < 8; i++) {
          var p = results[i]
          rows.push(root._row(p.Name, p.Version + " · AUR", p.Description || "", true))
        }
        acc.aur = rows
        flush()
      }, undefined)
      return []
    }
  })

  // ── Helpers ──────────────────────────────────────────────────────
  function _parsePacman(out): var {
    var lines = out.split("\n")
    var rows = []
    for (var i = 0; i < lines.length && rows.length < 8; i++) {
      var m = lines[i].match(/^(\S+)\/(\S+)\s+(\S+)/)
      if (!m) continue
      var desc = (lines[i + 1] || "").trim()
      rows.push(root._row(m[2], m[3] + " · " + m[1], desc, false))
    }
    return rows
  }

  function _row(name, meta, desc, aur): var {
    var host = aur ? "aur.archlinux.org" : "archlinux.org"
    var page = aur ? "https://aur.archlinux.org/packages/" + name
                   : "https://archlinux.org/packages/?name=" + encodeURIComponent(name)
    return {
      id: (aur ? "aur:" : "pac:") + name,
      label: name,
      sublabel: meta + (desc ? " — " + desc : ""),
      icon: "https://icons.duckduckgo.com/ip3/" + host + ".ico",
      iconKind: "image",
      iconFallback: "package",
      priority: aur ? 9 : 11,
      source: aur ? "aur" : "arch",
      groupLabel: aur ? "AUR" : "Arch repo",
      action: function() { ProcessPool.runDetached(["xdg-open", page]) }
    }
  }
}
