pragma Singleton
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
  property string layout: ""

  // ═══════════════════════════════════════════════════════════════
  //  INTERNAL STATE
  // ═══════════════════════════════════════════════════════════════
  property var _pollHandle: null

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════
  function _pollLayout(): void {
    if (_pollHandle && ProcessPool.isRunning(_pollHandle)) return
    var script = "hyprctl devices -j 2>/dev/null | python3 -c \"\n" +
      "import sys,json\n" +
      "try:\n" +
      "  d=json.load(sys.stdin)\n" +
      "  for kb in d.get('keyboards',[]):\n" +
      "    if kb.get('name','')=='': continue\n" +
      "    print(kb.get('active_keymap','')+'||'+kb.get('keymap',[''])[0])\n" +
      "    break\n" +
      "except: print('||')\n" +
      "\" 2>/dev/null || echo '||'"
    _pollHandle = ProcessPool.runTracked("Keyboard layout", script, {
      id: "kb-layout",
      shell: true,
      callback: function(r) {
        _pollHandle = null
        var parts = r.stdout.trim().split("||")
        if (parts[0]) svc.layout = parts[0]
        svc._startSocket()
      }
    })
  }

  function _startSocket(): void {
    var his = Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")
    if (!his) return
    WatchService.register(
      "hypr-kb-events",
      "python3 " + AppInfo.configHome + "/features/hypr/hyprland-events.py",
      function(line) {
        line = line.trim()
        if (!line) return
        var parts = line.split(">>")
        if (parts.length < 2) return
        if (parts[0] !== "activelayout") return
        var dataParts = parts[1].split(",")
        if (dataParts.length > 1) svc.layout = dataParts.slice(1).join(",")
      }
    )
  }

  // ═══════════════════════════════════════════════════════════════
  //  TIMERS
  // ═══════════════════════════════════════════════════════════════
  Timer {
    id: startupTimer
    interval: 500
    running: true
    repeat: false
    onTriggered: svc._pollLayout()
  }
}
