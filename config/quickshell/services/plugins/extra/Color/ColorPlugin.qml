pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../../../core"
import "../../../../services"

BasePlugin {
  id: root

  // ── Manifest ─────────────────────────────────────────────────────
  pluginId: "color"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Color",
    description: "Convert and copy hex / rgb / hsl colors",
    icon: "palette",
    locations: [],
    icons: {},
    settings: []
  })

  // ── Public API ───────────────────────────────────────────────────
  readonly property var searchProvider: ({
    id: "color",
    priority: 200,
    query: function(text, qid) {
      var q = (text || "").trim()
      var rgb = root._parse(q)
      if (!rgb) return []

      var hex = root._hex(rgb)
      var swatch = "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='18' height='18'>"
                 + "<rect width='18' height='18' rx='4' fill='%23" + hex + "'/></svg>"
      var forms = [
        "#" + hex,
        "rgb(" + rgb[0] + ", " + rgb[1] + ", " + rgb[2] + ")",
        root._hsl(rgb)
      ]
      var rows = []
      for (var i = 0; i < forms.length; i++) {
        rows.push((function(val) {
          return {
            id: "color:" + val,
            label: val,
            sublabel: "copy",
            icon: swatch,
            iconKind: "image",
            iconFallback: "palette",
            priority: 200,
            source: "color",
            groupLabel: "Color",
            action: function() { root._copy(val) }
          }
        })(forms[i]))
      }
      return rows
    }
  })

  // ── Helpers ──────────────────────────────────────────────────────
  function _parse(q): var {
    var m = q.match(/^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$/)
    if (m) {
      var h = m[1]
      if (h.length === 3) h = h[0] + h[0] + h[1] + h[1] + h[2] + h[2]
      return [parseInt(h.substr(0, 2), 16), parseInt(h.substr(2, 2), 16), parseInt(h.substr(4, 2), 16)]
    }
    var r = q.match(/^rgb\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*\)$/i)
    if (r) {
      var v = [parseInt(r[1]), parseInt(r[2]), parseInt(r[3])]
      if (v[0] <= 255 && v[1] <= 255 && v[2] <= 255) return v
    }
    return null
  }

  function _hex(rgb): string {
    function h(n) { var s = n.toString(16); return s.length === 1 ? "0" + s : s }
    return (h(rgb[0]) + h(rgb[1]) + h(rgb[2])).toUpperCase()
  }

  function _hsl(rgb): string {
    var r = rgb[0] / 255, g = rgb[1] / 255, b = rgb[2] / 255
    var mx = Math.max(r, g, b), mn = Math.min(r, g, b), h, s, l = (mx + mn) / 2
    if (mx === mn) { h = 0; s = 0 }
    else {
      var d = mx - mn
      s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn)
      if (mx === r) h = (g - b) / d + (g < b ? 6 : 0)
      else if (mx === g) h = (b - r) / d + 2
      else h = (r - g) / d + 4
      h /= 6
    }
    return "hsl(" + Math.round(h * 360) + ", " + Math.round(s * 100) + "%, " + Math.round(l * 100) + "%)"
  }

  function _copy(val: string): void {
    ProcessPool.runDetached(["sh", "-c", "printf %s \"$1\" | wl-copy", "--", val])
  }
}
