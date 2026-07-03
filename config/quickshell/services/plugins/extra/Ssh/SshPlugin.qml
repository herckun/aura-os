pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../../../core"
import "../../../../services"

BasePlugin {
  id: root

  // ── Manifest ─────────────────────────────────────────────────────
  pluginId: "ssh"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "SSH",
    description: "Open an SSH host from ~/.ssh/config — prefix with 'ssh '",
    icon: "terminal",
    locations: [],
    icons: {},
    settings: []
  })

  // ── Public API ───────────────────────────────────────────────────
  readonly property var searchProvider: ({
    id: "ssh",
    priority: 20,
    query: function(text, qid) {
      var q = (text || "").trim()
      if (q.toLowerCase().indexOf("ssh ") !== 0) return []
      var term = q.substring(4).trim()

      var script = "awk 'tolower($1)==\"host\"{for(i=2;i<=NF;i++) print $i}' \"$HOME/.ssh/config\" 2>/dev/null"
                 + " | grep -v '[*?]' | sort -u | grep -i \"$1\" | head -12"
      ProcessPool.runTracked("search-ssh", ["sh", "-c", script, "--", term], {
        id: "search-ssh",
        callback: function(r) {
          var hosts = (r.stdout || "").trim().split("\n").filter(function(l) { return l.length > 0 })
          var rows = []
          for (var i = 0; i < hosts.length; i++) {
            rows.push((function(host) {
              return {
                id: "ssh:" + host,
                label: host,
                sublabel: "ssh " + host,
                icon: "terminal",
                iconKind: "symbolic",
                priority: 20,
                source: "ssh",
                groupLabel: "SSH",
                action: function() { ProcessPool.runDetached(["kitty", "--", "ssh", host]) }
              }
            })(hosts[i]))
          }
          SearchService.submit(qid, "ssh", rows)
        }
      })
      return []
    }
  })
}
