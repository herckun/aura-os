pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../../../core"
import "../../../../services"

BasePlugin {
  id: root

  // ── Manifest ─────────────────────────────────────────────────────
  pluginId: "dictionary"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Dictionary",
    description: "Define a word — type '/define'",
    icon: "book-2",
    locations: [],
    icons: {},
    settings: []
  })

  // ── Public API ───────────────────────────────────────────────────
  readonly property var searchProvider: ({
    id: "dictionary",
    priority: 215,
    command: { prefix: "define", args: "<word>", description: "Define a word", icon: "book-2" },
    query: function(text, qid) {
      var q = (text || "").trim()
      if (q.toLowerCase().indexOf("/define ") !== 0) return []
      var word = q.substring(8).trim()
      if (word.length < 2) return []

      RequestService.get("https://api.dictionaryapi.dev/api/v2/entries/en/" + encodeURIComponent(word), function(resp) {
        var rows = []
        if (resp && resp.ok && resp.data && resp.data.length) {
          var entry = resp.data[0]
          var phon = ""
          for (var p = 0; p < (entry.phonetics || []).length; p++) { if (entry.phonetics[p].text) { phon = entry.phonetics[p].text; break } }
          var meanings = entry.meanings || []
          for (var i = 0; i < meanings.length && rows.length < 4; i++) {
            var mn = meanings[i]
            var def = (mn.definitions && mn.definitions[0]) ? mn.definitions[0].definition : ""
            if (!def) continue
            rows.push((function(pos, definition) {
              return {
                id: "def:" + rows.length + word,
                label: entry.word + (rows.length === 0 && phon ? "  " + phon : ""),
                sublabel: pos + " · " + definition,
                icon: "book-2",
                iconKind: "symbolic",
                priority: 215,
                source: "dictionary",
                groupLabel: "Dictionary",
                wrap: true,
                action: function() { ProcessPool.runDetached(["xdg-open", "https://en.wiktionary.org/wiki/" + encodeURIComponent(entry.word)]) }
              }
            })(mn.partOfSpeech || "", def))
          }
        }
        SearchService.submit(qid, "dictionary", rows)
      }, undefined)
      return []
    }
  })
}
