pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../../../core"
import "../../../../services"

BasePlugin {
  id: root

  // ── Manifest ─────────────────────────────────────────────────────
  pluginId: "httpstatus"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "HTTP status",
    description: "Look up an HTTP status code",
    icon: "world",
    locations: [],
    icons: {},
    settings: []
  })

  // ── Internal state ───────────────────────────────────────────────
  readonly property var _codes: ({
    "100": "Continue", "101": "Switching Protocols",
    "200": "OK", "201": "Created", "202": "Accepted", "204": "No Content", "206": "Partial Content",
    "301": "Moved Permanently", "302": "Found", "303": "See Other", "304": "Not Modified", "307": "Temporary Redirect", "308": "Permanent Redirect",
    "400": "Bad Request", "401": "Unauthorized", "403": "Forbidden", "404": "Not Found", "405": "Method Not Allowed",
    "408": "Request Timeout", "409": "Conflict", "410": "Gone", "418": "I'm a teapot", "422": "Unprocessable Entity", "429": "Too Many Requests",
    "500": "Internal Server Error", "501": "Not Implemented", "502": "Bad Gateway", "503": "Service Unavailable", "504": "Gateway Timeout"
  })

  // ── Public API ───────────────────────────────────────────────────
  readonly property var searchProvider: ({
    id: "httpstatus",
    priority: 205,
    query: function(text, qid) {
      var q = (text || "").trim()
      if (!/^[1-5]\d\d$/.test(q)) return []
      var name = root._codes[q]
      var cat = ({ "1": "Informational", "2": "Success", "3": "Redirection", "4": "Client Error", "5": "Server Error" })[q[0]]
      return [{
        id: "http:" + q,
        label: q + (name ? " " + name : ""),
        sublabel: q[0] + "xx · " + cat,
        icon: "world",
        iconKind: "symbolic",
        priority: 205,
        source: "http",
        groupLabel: "HTTP status",
        action: function() {
          ProcessPool.runDetached(["xdg-open", "https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/" + q])
        }
      }]
    }
  })
}
