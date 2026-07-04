pragma Singleton
import QtQml
import Quickshell
import "../../core"

Singleton {
  id: svc

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC STATE
  // ═══════════════════════════════════════════════════════════════
  property bool loaded: false
  property var current: ({})
  property var candidates: ({})
  property var _detected: ({})
  property string _pendingLaunch: ""
  property bool _reconciled: false

  readonly property var categories: [
    { id: "terminal", label: "TERMINAL", icon: "terminal",
      description: "Used for shell keybind and terminal launches",
      detect: "terminal", match: { categories: ["TerminalEmulator"] }, strict: true,
      apply: ["terminalList"] },
    { id: "browser", label: "WEB BROWSER", icon: "world",
      description: "Used for links and the browser keybind",
      detect: "settings", match: { categories: ["WebBrowser"] }, strict: true,
      mimes: ["x-scheme-handler/http", "x-scheme-handler/https", "x-scheme-handler/about", "x-scheme-handler/unknown", "text/html"],
      apply: ["browserSettings", "mime"] },
    { id: "fileManager", label: "FILE MANAGER", icon: "folder",
      description: "Used for folders and the files keybind",
      detect: "mime", match: { categories: ["FileManager"] }, strict: true,
      mimes: ["inode/directory"],
      apply: ["mime", "fileManager1"] },
    { id: "editor", label: "TEXT EDITOR", icon: "code",
      description: "Used for plain text and config files",
      detect: "mime", match: { categories: ["TextEditor", "IDE"] },
      mimes: ["text/plain", "text/markdown"],
      apply: ["mime"] },
    { id: "imageViewer", label: "IMAGE VIEWER", icon: "photo",
      description: "Used for pictures and screenshots",
      detect: "mime", match: { mimes: true },
      mimes: ["image/png", "image/jpeg", "image/webp", "image/gif", "image/svg+xml", "image/bmp"],
      apply: ["mime"] },
    { id: "videoPlayer", label: "VIDEO PLAYER", icon: "player-play",
      description: "Used for video files",
      detect: "mime", match: { mimes: true },
      mimes: ["video/mp4", "video/x-matroska", "video/webm", "video/mpeg", "video/x-msvideo"],
      apply: ["mime"] },
    { id: "audioPlayer", label: "MUSIC PLAYER", icon: "music",
      description: "Used for audio files",
      detect: "mime", match: { mimes: true },
      mimes: ["audio/mpeg", "audio/flac", "audio/ogg", "audio/x-wav", "audio/mp4"],
      apply: ["mime"] },
    { id: "pdfViewer", label: "PDF VIEWER", icon: "book",
      description: "Used for PDF documents",
      detect: "mime", match: { mimes: true },
      mimes: ["application/pdf"],
      apply: ["mime"] },
    { id: "archiveManager", label: "ARCHIVES", icon: "package",
      description: "Used for zip, tar and other archives",
      detect: "mime", match: { mimes: true },
      mimes: ["application/zip", "application/x-tar", "application/x-compressed-tar", "application/x-7z-compressed", "application/vnd.rar", "application/gzip"],
      apply: ["mime"] }
  ]

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════
  function init(): void {}

  function appFor(category: string): var {
    var app = current[category]
    if (app && app.exec) return app
    return { id: "", name: "", exec: "" }
  }

  function execFor(category: string): string {
    return appFor(category).exec
  }

  function launch(category: string): void {
    if (!loaded) {
      svc._pendingLaunch = category
      return
    }
    var exec = execFor(category)
    if (!exec) return
    ProcessPool.runDetached(["sh", "-c", exec + " >/dev/null 2>&1"])
  }

  function runInTerminal(argv: var): void {
    var exec = execFor("terminal")
    if (!exec) exec = "kitty"
    var parts = exec.split(" ").filter(function(p) { return p !== "" })
    var bin = parts[0].split("/").pop()
    var flag = (bin === "kitty" || bin === "gnome-terminal") ? "--" : "-e"
    ProcessPool.runDetached(parts.concat([flag]).concat(argv))
  }

  function openUrl(url: string): void {
    if (url) ProcessPool.runDetached(["xdg-open", url])
    else launch("browser")
  }

  function openPath(path: string): void {
    var exec = execFor("fileManager")
    if (exec && path) ProcessPool.runDetached(["sh", "-c", exec + " \"$1\" >/dev/null 2>&1", "sh", path])
    else if (path) ProcessPool.runDetached(["xdg-open", path])
    else launch("fileManager")
  }

  function revealPath(path: string): void {
    var exec = execFor("fileManager")
    if (!exec) {
      ProcessPool.runDetached(["xdg-open", path])
      return
    }
    var bin = exec.split(" ")[0].split("/").pop()
    var target
    if (bin === "nautilus" || bin === "dolphin") target = exec + ' --select "$p"'
    else if (bin === "nemo") target = exec + ' "$p"'
    else target = exec + ' "$(dirname "$p")"'
    var script = 'p="$1"; if [ -d "$p" ]; then exec ' + exec + ' "$p" >/dev/null 2>&1; fi; exec ' + target + ' >/dev/null 2>&1'
    ProcessPool.runDetached(["sh", "-c", script, "sh", path])
  }

  function setDefault(category: string, item: var): void {
    var stored = Store.getObject("defaultApps", {})
    stored[category] = { id: item.id || "", name: item.name || "", exec: item.exec || "" }
    Store.set("defaultApps", stored)

    _applySystem(_categoryById(category), stored[category])

    var cur = {}
    for (var k in current) cur[k] = current[k]
    cur[category] = stored[category]
    current = cur
  }

  function refresh(): void {
    _scan()
  }

  // ═══════════════════════════════════════════════════════════════
  //  DETECTION / APPLY CHANNELS
  // ═══════════════════════════════════════════════════════════════
  readonly property var _detectSources: ({
    mime: function(cat) { return '$(xdg-mime query default ' + cat.mimes[0] + ' 2>/dev/null)' },
    settings: function(cat) { return '$(xdg-settings get default-web-browser 2>/dev/null)' },
    terminal: function(cat) { return '$(grep -m1 -ve "^#" -ve "^ *$" "${XDG_CONFIG_HOME:-$HOME/.config}/xdg-terminals.list" 2>/dev/null | cut -d: -f1 | tr -d " ")' }
  })

  readonly property var _appliers: ({
    mime: function(cat, item) {
      var esc = cat.mimes.map(function(m) { return m.replace(/[.+]/g, "\\$&") }).join("|")
      var script =
        'xdg-mime default "$1" ' + cat.mimes.join(" ") + '\n' +
        'for f in "${XDG_CONFIG_HOME:-$HOME/.config}"/*-mimeapps.list; do\n' +
        '  [ -e "$f" ] || continue\n' +
        '  t=$(mktemp); grep -vE "^(' + esc + ')=" "$f" > "$t"; mv "$t" "$f"\n' +
        'done\n' +
        'exit 0'
      ProcessPool.runQueued("Default apps: " + cat.id,
        ["sh", "-c", script, "sh", item.id], { id: "xdg-default-" + cat.id, silent: true })
    },
    browserSettings: function(cat, item) {
      ProcessPool.runQueued("Default apps: browser settings",
        ["xdg-settings", "set", "default-web-browser", item.id], { id: "xdg-settings-browser", silent: true })
    },
    fileManager1: function(cat, item) {
      svc._applyFileManager1(item)
    },
    terminalList: function(cat, item) {
      svc._applyTerminal(item)
    }
  })

  function _applySystem(cat: var, item: var): void {
    if (!cat || !item.id) return
    var channels = cat.apply || []
    for (var i = 0; i < channels.length; i++) {
      _appliers[channels[i]](cat, item)
    }
  }

  function _applyTerminal(item: var): void {
    var bin = (item.exec || "").split(" ")[0].split("/").pop()
    var script =
      'f="${XDG_CONFIG_HOME:-$HOME/.config}/xdg-terminals.list"\n' +
      't=$(mktemp)\n' +
      'printf "%s\\n" "$1" > "$t"\n' +
      '[ -f "$f" ] && grep -vx "$1" "$f" >> "$t"\n' +
      'mv "$t" "$f"\n' +
      '[ -n "$2" ] && gsettings set org.gnome.desktop.default-applications.terminal exec "$2" 2>/dev/null\n' +
      'exit 0'
    ProcessPool.runQueued("Default apps: terminal", ["sh", "-c", script, "sh", item.id, bin],
      { id: "xdg-default-terminal-list", silent: true })
  }

  function _applyFileManager1(item: var): void {
    var bin = (item.exec || "").split(" ")[0].split("/").pop()
    if (!bin) return
    var flags = { nautilus: "--gapplication-service", nemo: "--gapplication-service",
                  dolphin: "--daemon", thunar: "--daemon" }
    var flag = flags[bin] || ""
    var script =
      'p=$(command -v "$1") || exit 0\n' +
      'mkdir -p "$HOME/.local/share/dbus-1/services"\n' +
      'printf "[D-BUS Service]\\nName=org.freedesktop.FileManager1\\nExec=%s\\n" "$p${2:+ $2}" ' +
      '> "$HOME/.local/share/dbus-1/services/org.freedesktop.FileManager1.service"'
    ProcessPool.runQueued("Default apps: filemanager dbus", ["sh", "-c", script, "sh", bin, flag],
      { id: "xdg-default-fm-dbus", silent: true })
  }

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════
  function _categoryById(id: string): var {
    for (var i = 0; i < categories.length; i++) {
      if (categories[i].id === id) return categories[i]
    }
    return null
  }

  function _cleanExec(exec: string): string {
    return exec.replace(/%[fFuUick]/g, "").replace(/\s+/g, " ").trim()
  }

  function _matches(cat: var, app: var): bool {
    var m = cat.match || {}
    if (m.categories) {
      for (var i = 0; i < m.categories.length; i++) {
        if (app.cats.indexOf(m.categories[i]) !== -1) return true
      }
    }
    if (m.mimes && cat.mimes) {
      for (var j = 0; j < cat.mimes.length; j++) {
        if (app.mimes.indexOf(cat.mimes[j]) !== -1) return true
      }
    }
    return false
  }

  function _scan(): void {
    var script =
      'ml="${XDG_CONFIG_HOME:-$HOME/.config}/mimeapps.list"\n' +
      'if [ -f "$ml" ] && grep -qvE "^\\[.*\\]$|=|^#|^[[:space:]]*$" "$ml"; then\n' +
      '  t=$(mktemp); grep -E "^\\[.*\\]$|=|^#|^[[:space:]]*$" "$ml" > "$t" && mv "$t" "$ml"\n' +
      'fi\n' +
      'for d in /usr/share/applications "$HOME/.local/share/applications"; do\n' +
      '  [ -d "$d" ] || continue\n' +
      '  for f in "$d"/*.desktop; do\n' +
      '    [ -e "$f" ] || continue\n' +
      '    grep -qm1 "^NoDisplay=true" "$f" && continue\n' +
      '    printf "A|%s|%s|%s|%s|%s\\n" "$(basename "$f")" ' +
      '"$(grep -m1 "^Name=" "$f" | cut -d= -f2-)" ' +
      '"$(grep -m1 "^Categories=" "$f" | cut -d= -f2-)" ' +
      '"$(grep -m1 "^MimeType=" "$f" | cut -d= -f2-)" ' +
      '"$(grep -m1 "^Exec=" "$f" | cut -d= -f2-)"\n' +
      '  done\n' +
      'done\n' +
      'cur() {\n' +
      '  id="$2"; [ -n "$id" ] || { printf "D|%s|||\\n" "$1"; return; }\n' +
      '  for d in "$HOME/.local/share/applications" /usr/share/applications; do\n' +
      '    f="$d/$id"; [ -e "$f" ] || continue\n' +
      '    printf "D|%s|%s|%s|%s\\n" "$1" "$id" "$(grep -m1 "^Name=" "$f" | cut -d= -f2-)" "$(grep -m1 "^Exec=" "$f" | cut -d= -f2-)"\n' +
      '    return\n' +
      '  done\n' +
      '  printf "D|%s|%s||\\n" "$1" "$id"\n' +
      '}\n'
    for (var i = 0; i < categories.length; i++) {
      var cat = categories[i]
      script += 'cur ' + cat.id + ' "' + _detectSources[cat.detect || "mime"](cat) + '"\n'
    }

    ProcessPool.runTracked("Default apps scan", script, {
      id: "default-apps-scan",
      shell: true,
      callback: function(r) {
        svc._parseScan(r.stdout || "")
      }
    })
  }

  function _parseScan(out: string): void {
    var cands = {}
    for (var c = 0; c < categories.length; c++) cands[categories[c].id] = []
    var detected = {}
    var lines = out.split("\n")
    for (var i = 0; i < lines.length; i++) {
      var parts = lines[i].split("|")
      if (parts[0] === "A" && parts.length >= 6) {
        var app = {
          id: parts[1],
          name: parts[2],
          cats: parts[3].split(";"),
          mimes: parts[4].split(";"),
          exec: _cleanExec(parts.slice(5).join("|"))
        }
        if (!app.id || !app.exec) continue
        for (var c2 = 0; c2 < categories.length; c2++) {
          var cat = categories[c2]
          if (!_matches(cat, app)) continue
          var entry = { id: app.id, name: app.name, exec: app.exec }
          var replaced = false
          var list = cands[cat.id]
          for (var j = 0; j < list.length; j++) {
            if (list[j].id === entry.id) { list[j] = entry; replaced = true; break }
          }
          if (!replaced) list.push(entry)
        }
      } else if (parts[0] === "D" && parts.length >= 5) {
        var det = { id: parts[2], name: parts[3], exec: _cleanExec(parts.slice(4).join("|")) }
        if (det.id && det.exec) detected[parts[1]] = det
      }
    }
    candidates = cands
    svc._detected = detected
    Store.loadedLater(0, function() { svc._resolve() })
  }

  function _resolve(): void {
    var detected = svc._detected
    var stored = Store.getObject("defaultApps", {})
    var manifest = (AppInfo.manifest && AppInfo.manifest.defaultApps) || {}
    var cur = {}
    for (var i = 0; i < categories.length; i++) {
      var cat = categories[i]
      var pick = null
      var det = detected[cat.id]
      if (det && (!cat.strict || _isCandidate(cat.id, det.id))) pick = det
      if (!pick && stored[cat.id] && stored[cat.id].exec) pick = stored[cat.id]
      if (!pick && manifest[cat.id]) pick = _fromCommand(cat.id, manifest[cat.id])
      if (!pick && candidates[cat.id] && candidates[cat.id].length > 0) pick = candidates[cat.id][0]
      if (pick) {
        cur[cat.id] = pick
        if (!svc._reconciled) _applySystem(cat, pick)
      }
    }
    svc._reconciled = true
    current = cur
    loaded = true
    if (svc._pendingLaunch) {
      var pending = svc._pendingLaunch
      svc._pendingLaunch = ""
      launch(pending)
    }
  }

  function _isCandidate(category: string, id: string): bool {
    var list = candidates[category] || []
    for (var i = 0; i < list.length; i++) {
      if (list[i].id === id) return true
    }
    return false
  }

  function _fromCommand(category: string, cmd: string): var {
    var list = candidates[category] || []
    for (var i = 0; i < list.length; i++) {
      var bin = list[i].exec.split(" ")[0].split("/").pop()
      if (bin === cmd) return list[i]
    }
    if (list.length === 0) return { id: "", name: cmd, exec: cmd }
    return null
  }

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════
  Connections {
    target: AppInfo
    function onManifestChanged() {
      if (svc.loaded) Store.loadedLater(0, function() { svc._resolve() })
    }
  }

  Component.onCompleted: _scan()
}
