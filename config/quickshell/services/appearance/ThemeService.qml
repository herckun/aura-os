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
  property var presets: []
  readonly property string active: Store.theme.preset || "aura"

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════
  function apply(presetId: string): void {
    var p = svc._find(presetId)
    if (!p) return
    Store.theme.preset = presetId
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
  function _find(presetId: string): var {
    for (var i = 0; i < svc.presets.length; i++)
      if (svc.presets[i].id === presetId) return svc.presets[i]
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
      AppInfo.configHome + "/quickshell/styles/presets"]
    stdout: StdioCollector { waitForEnd: true }
    onExited: {
      try {
        svc.presets = JSON.parse(stdout.text)
      } catch(e) {
        svc.presets = []
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════
  Component.onCompleted: _scanner.running = true
}
