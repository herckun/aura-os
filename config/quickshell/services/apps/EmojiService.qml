pragma Singleton
pragma ComponentBehavior: Bound
import QtQml
import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"

Singleton {
  id: svc

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC STATE
  // ═══════════════════════════════════════════════════════════════

  property var emojis: ([])
  property var filtered: ([])
  property bool loaded: false

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════

  function search(query: string): void {
    if (!svc.loaded) {
      svc._pendingQuery = query
      svc.filtered = []
      svc._load()
      return
    }

    var q = query.toLowerCase()
    
    if (q === "") {
      svc.filtered = svc.emojis.slice(0, svc._maxResults)
      return
    }

    var results = []
    for (var i = 0; i < svc.emojis.length && results.length < svc._maxResults; i++) {
      var e = svc.emojis[i]
      if (e.name.indexOf(q) >= 0 || e.category.indexOf(q) >= 0) {
        results.push(e)
      }
    }
    
    svc.filtered = results
  }

  // ═══════════════════════════════════════════════════════════════
  //  INTERNAL STATE
  // ═══════════════════════════════════════════════════════════════

  property bool _loading: false
  property string _pendingQuery: ""

  readonly property int _maxResults: 50
  readonly property int _maxEmojis: 2000

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════

  function _parseEmojis(stdout: string): var {
    try {
      return JSON.parse(stdout)
    } catch (e) {
      Logger.warn("emoji", "Failed to parse emoji data")
      return null
    }
  }

  function _load(): void {
    if (svc.loaded || svc._loading) return
    svc._loading = true

    var script = "python3 -c \"" +
      "import json, sys; " +
      "try: " +
        "import emoji; " +
        "emojis = [{'emoji': e, 'name': emoji.demojize(e).strip(':'), 'category': ''} " +
        "for e in list(emoji.EMOJI_DATA.keys())[:" + svc._maxEmojis + "]]; " +
        "print(json.dumps(emojis)) " +
      "except: " +
        "print('[]') " +
      "\" 2>/dev/null || echo '[]'"

    ProcessPool.runTracked("Load emojis", script, {
      id: "load-emojis",
      shell: true,
      callback: function(r) {
        svc._loading = false

        var parsed = _parseEmojis(r.stdout.trim())
        svc.emojis = parsed || []
        
        if (!parsed) {
          svc.filtered = []
        }

        svc.loaded = true
        svc.search(svc._pendingQuery)
        svc._pendingQuery = ""
      }
    })
  }

  // ═══════════════════════════════════════════════════════════════
  //  SYSTEM INTEGRATION
  // ═══════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════
  //  SIGNAL CONNECTIONS
  // ═══════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════
  //  TIMERS
  // ═══════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════

}