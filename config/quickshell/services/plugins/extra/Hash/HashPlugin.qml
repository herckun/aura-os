pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../../../core"
import "../../../../services"

BasePlugin {
  id: root

  // ── Manifest ─────────────────────────────────────────────────────
  pluginId: "hash"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Encode / hash",
    description: "base64, sha256, md5, sha1, hex, uuid",
    icon: "hash",
    locations: [],
    icons: {},
    settings: []
  })

  // ── Public API ───────────────────────────────────────────────────
  readonly property var searchProvider: ({
    id: "hash",
    priority: 210,
    query: function(text, qid) {
      var q = (text || "").trim()
      var sp = q.indexOf(" ")
      var op = (sp < 0 ? q : q.substring(0, sp)).toLowerCase()
      var input = sp < 0 ? "" : q.substring(sp + 1)

      var cmd = root._cmdFor(op, input)
      if (!cmd) return []

      ProcessPool.runTracked("search-hash", cmd, {
        id: "search-hash",
        callback: function(r) {
          var out = (r.stdout || "").trim()
          if (r.exitCode !== 0 || !out || out.length > 400) { SearchService.submit(qid, "hash", []); return }
          SearchService.submit(qid, "hash", [{
            id: "hash:result",
            label: out,
            sublabel: op + " — Enter to copy",
            icon: "hash",
            iconKind: "symbolic",
            priority: 210,
            source: "hash",
            groupLabel: "Encode / hash",
            wrap: true,
            action: function() { ProcessPool.runDetached(["sh", "-c", "printf %s \"$1\" | wl-copy", "--", out]) }
          }])
        }
      })
      return []
    }
  })

  // ── Helpers ──────────────────────────────────────────────────────
  function _cmdFor(op, input): var {
    if (op === "uuid") return ["uuidgen"]
    if (!input) return null
    var pipes = ({
      "base64": "base64 -w0", "b64": "base64 -w0",
      "base64d": "base64 -d", "b64d": "base64 -d",
      "sha256": "sha256sum | cut -d' ' -f1",
      "sha1": "sha1sum | cut -d' ' -f1",
      "md5": "md5sum | cut -d' ' -f1",
      "hex": "xxd -p | tr -d '\\n'"
    })
    var pipe = pipes[op]
    if (!pipe) return null
    return ["sh", "-c", "printf %s \"$1\" | " + pipe, "--", input]
  }
}
