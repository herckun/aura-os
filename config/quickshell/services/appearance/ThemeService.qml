pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"

Singleton {
  id: svc

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC STATE
  // ═══════════════════════════════════════════════════════════════
  property var themes: []
  readonly property string active: Store.theme.name || "aura"

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════
  function apply(themeId: string): void {
    var p = svc._find(themeId)
    if (!p) return
    Store.theme.name = themeId
    if (p.accent) {
      Store.theme.accent = p.accent
      Store.theme.accentManual = false
    }
  }

  function refresh(): void {
    _scanner.running = false
    _scanner.running = true
  }

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════
  function _find(themeId: string): var {
    for (var i = 0; i < svc.themes.length; i++)
      if (svc.themes[i].id === themeId) return svc.themes[i]
    return null
  }

  // ═══════════════════════════════════════════════════════════════
  //  SYSTEM INTEGRATION
  // ═══════════════════════════════════════════════════════════════
  Process {
    id: _scanner
    command: ["python3", "-c",
      "import json, glob, os, sys\n" +
      "out = []\n" +
      "for f in sorted(glob.glob(os.path.join(sys.argv[1], '*.json'))):\n" +
      "    try:\n" +
      "        p = json.load(open(f))\n" +
      "    except Exception:\n" +
      "        continue\n" +
      "    p['id'] = os.path.splitext(os.path.basename(f))[0]\n" +
      "    out.append(p)\n" +
      "print(json.dumps(out))",
      AppInfo.configHome + "/quickshell/styles/themes"]
    stdout: StdioCollector { waitForEnd: true }
    onExited: {
      try {
        svc.themes = JSON.parse(stdout.text)
      } catch(e) {
        svc.themes = []
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════
  Component.onCompleted: _scanner.running = true
}
