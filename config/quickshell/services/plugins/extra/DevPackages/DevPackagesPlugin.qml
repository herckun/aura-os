pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../../../core"
import "../../../../services"

BasePlugin {
  id: root

  // ── Manifest ─────────────────────────────────────────────────────
  pluginId: "devpackages"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Dev packages",
    description: "Search registries — '/npm', '/pip', '/crate'",
    icon: "package",
    locations: [],
    icons: {},
    settings: []
  })

  // ── Public API ───────────────────────────────────────────────────
  readonly property var searchProvider: ({
    id: "devpackages",
    priority: 14,
    command: [
      { prefix: "npm", args: "<name>", description: "Search the npm registry", icon: "package" },
      { prefix: "pip", args: "<name>", description: "Search PyPI", icon: "package" },
      { prefix: "crate", args: "<name>", description: "Search crates.io", icon: "package" }
    ],
    query: function(text, qid) {
      var q = (text || "").trim()
      var m = q.match(/^\/(npm|crate|crates|cargo|pip|pypi)\s+(.+)$/i)
      if (!m) return []
      var kind = m[1].toLowerCase()
      var term = m[2].trim()
      if (term.length < 2) return []

      if (kind === "npm") {
        RequestService.get("https://registry.npmjs.org/-/v1/search?size=6&text=" + encodeURIComponent(term), function(resp) {
          var rows = []
          var objs = (resp && resp.ok && resp.data && resp.data.objects) ? resp.data.objects : []
          for (var i = 0; i < objs.length; i++) {
            var p = objs[i].package
            rows.push(root._row("npm:" + p.name, p.name, p.version + " · npm", p.description || "",
                                "npmjs.com", "https://www.npmjs.com/package/" + p.name))
          }
          SearchService.submit(qid, "devpackages", rows)
        }, undefined)
      } else if (kind === "pip" || kind === "pypi") {
        RequestService.get("https://pypi.org/pypi/" + encodeURIComponent(term) + "/json", function(resp) {
          var rows = []
          if (resp && resp.ok && resp.data && resp.data.info) {
            var inf = resp.data.info
            rows.push(root._row("pypi:" + inf.name, inf.name, inf.version + " · PyPI", inf.summary || "",
                                "pypi.org", "https://pypi.org/project/" + inf.name))
          }
          SearchService.submit(qid, "devpackages", rows)
        }, undefined)
      } else {
        RequestService.get("https://crates.io/api/v1/crates?per_page=6&q=" + encodeURIComponent(term), function(resp) {
          var rows = []
          var cs = (resp && resp.ok && resp.data && resp.data.crates) ? resp.data.crates : []
          for (var i = 0; i < cs.length; i++) {
            var c = cs[i]
            rows.push(root._row("crate:" + c.name, c.name, c.max_version + " · crates.io", c.description || "",
                                "crates.io", "https://crates.io/crates/" + c.name))
          }
          SearchService.submit(qid, "devpackages", rows)
        }, ({ "User-Agent": "aura-os-shell (https://github.com/herckun/aura-os)" }))
      }
      return []
    }
  })

  // ── Helpers ──────────────────────────────────────────────────────
  function _row(id, name, meta, desc, host, page): var {
    return {
      id: id,
      label: name,
      sublabel: meta + (desc ? " — " + desc : ""),
      icon: "https://icons.duckduckgo.com/ip3/" + host + ".ico",
      iconKind: "image",
      iconFallback: "package",
      priority: 14,
      source: "devpackages",
      groupLabel: "Dev packages",
      action: function() { ProcessPool.runDetached(["xdg-open", page]) }
    }
  }
}
