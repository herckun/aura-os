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

  property var categories: []
  property var shellActions: []
  property var hyprActions: []
  property var globalActions: []
  property var bindings: []
  property bool loaded: false

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════

  function getBindingsByCategory(categoryId: string): var {
    var result = []
    for (var i = 0; i < bindings.length; i++) {
      if (bindings[i].category === categoryId) result.push(bindings[i])
    }
    return result
  }

  function getConflicts(): var {
    var seen = {}
    var conflicts = []
    for (var i = 0; i < bindings.length; i++) {
      var b = bindings[i]
      var key = (b.mod || "") + "|" + (b.key || "")
      if (!key || key === "|") continue
      if (seen[key]) {
        conflicts.push({ key: key, bindings: [seen[key], b] })
      } else {
        seen[key] = b
      }
    }
    return conflicts
  }

  function updateBinding(id: string, updates: var): bool {
    var copy = bindings.slice()
    for (var i = 0; i < copy.length; i++) {
      if (copy[i].id === id) {
        var merged = Object.assign({}, copy[i], updates)
        if (validateBinding(merged) !== "") return false
        copy[i] = merged
        break
      }
    }
    bindings = copy
    _saveUserOverrides()
    _generateHyprConfig()
    return true
  }

  function addCustomBinding(binding: var): bool {
    if (validateBinding(binding) !== "") return false
    var copy = bindings.slice()
    copy.push(Object.assign({}, binding, { custom: true }))
    bindings = copy
    _saveUserOverrides()
    _generateHyprConfig()
    return true
  }

  property bool captureActive: false

  function beginCapture(): void {
    if (captureActive) return
    captureActive = true
    _captureFailsafe.restart()
    ProcessPool.runDetached(["hyprctl", "dispatch", "hl.dsp.submap(\"qs-capture\")"], { silent: true })
  }

  function endCapture(): void {
    if (!captureActive) return
    captureActive = false
    _captureFailsafe.stop()
    ProcessPool.runDetached(["hyprctl", "dispatch", "hl.dsp.submap(\"reset\")"], { silent: true })
  }

  property Timer _captureFailsafe: Timer {
    interval: 20000
    repeat: false
    onTriggered: svc.endCapture()
  }

  readonly property var validMods: ["SUPER", "CTRL", "SHIFT", "ALT"]

  function validateBinding(b: var): string {
    var mod = (b.mod || "").trim()
    if (mod !== "") {
      var parts = mod.toUpperCase().split(/[\s+]+/).filter(function(x) { return x !== "" })
      var seen = ({})
      for (var i = 0; i < parts.length; i++) {
        if (validMods.indexOf(parts[i]) < 0)
          return "Unknown modifier \"" + parts[i] + "\" — use SUPER, CTRL, SHIFT or ALT"
        if (seen[parts[i]]) return "Duplicate modifier \"" + parts[i] + "\""
        seen[parts[i]] = true
      }
    }
    var key = (b.key || "").trim()
    if (key === "") return "A key is required"
    if (!/^([A-Za-z0-9]|F([1-9]|1[0-9]|2[0-4])|Return|Enter|Space|Tab|BackSpace|Delete|Insert|Home|End|Prior|Next|Left|Right|Up|Down|Escape|Print|Menu|minus|equal|plus|comma|period|slash|question|backslash|semicolon|apostrophe|grave|bracketleft|bracketright|XF86[A-Za-z0-9]+|mouse:[0-9]+|mouse_(up|down|left|right)|code:[0-9]+)$/.test(key))
      return "\"" + key + "\" is not a recognised key name"
    var action = (b.action || "").trim()
    if (action === "") return "An action is required"
    if (/[\u0000-\u001F\u007F]/.test(action))
      return "The action can't contain control characters"
    if ((b.description || "") !== "" && /[\u0000-\u001F\u007F]/.test(b.description))
      return "The description can't contain control characters"
    if ((b.actionType || "") === "hypr") {
      var args = b.args || {}
      if ((action === "movefocus" || action === "movewindow")
          && args.direction !== undefined && String(args.direction) !== ""
          && ["left", "right", "up", "down"].indexOf(String(args.direction)) < 0)
        return "Direction must be left, right, up or down"
      if ((action === "workspace" || action === "movetoworkspace")
          && args.id !== undefined && args.id !== null && String(args.id) !== ""
          && !/^([0-9]+|[+-][0-9]+|e[+-][0-9]+|empty|previous|special(:[A-Za-z0-9_-]+)?|name:[A-Za-z0-9 _-]+)$/.test(String(args.id)))
        return "Workspace must be a number or a valid selector (e.g. 3, +1, special:magic)"
      if (action === "togglespecialworkspace"
          && args.name !== undefined && String(args.name) !== ""
          && !/^[A-Za-z0-9_-]+$/.test(String(args.name)))
        return "Special workspace names can only use letters, digits, - and _"
      if (action === "resizeactive"
          && args.params !== undefined && String(args.params) !== ""
          && !/^-?[0-9]+%? -?[0-9]+%?$/.test(String(args.params)))
        return "Resize parameters must look like \"20 0\" or \"10% 0\""
    }
    return ""
  }

  function removeBinding(id: string): void {
    var copy = []
    for (var i = 0; i < bindings.length; i++) {
      if (bindings[i].id !== id) copy.push(bindings[i])
    }
    bindings = copy
    _saveUserOverrides()
    _generateHyprConfig()
  }

  function resetToDefaults(): void {
    Store.keybindings.overrides = ({})
    Store.keybindings.custom = ([])
    _loadDefaults()
    _generateHyprConfig()
  }

  // ═══════════════════════════════════════════════════════════════
  //  INTERNAL STATE
  // ═══════════════════════════════════════════════════════════════

  property var _manifestDefaults: []
  property var _manifestCategories: []

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════

  function _loadDefaults(): void {
    var kb = AppInfo.manifest.keybindings || {}
    _manifestCategories = kb.categories || []
    _manifestDefaults = kb.defaults || []
    shellActions = kb.shellActions || []
    hyprActions = kb.hyprActions || []
    globalActions = kb.globalActions || []
    categories = _manifestCategories
    _mergeBindings()
  }

  function _mergeBindings(): void {
    var overrides = Store.toObject(Store.keybindings.overrides)
    var custom = Store.toArray(Store.keybindings.custom)
    var merged = []

    for (var i = 0; i < _manifestDefaults.length; i++) {
      var def = _manifestDefaults[i]
      var override = overrides[def.id]
      if (override) {
        merged.push(Object.assign({}, def, override, { id: def.id, category: def.category }))
      } else {
        merged.push(Object.assign({}, def))
      }
    }

    for (var j = 0; j < custom.length; j++) {
      merged.push(Object.assign({}, custom[j], { custom: true }))
    }

    bindings = merged
    loaded = true
  }

  function _saveUserOverrides(): void {
    var overrides = {}
    var custom = []

    for (var i = 0; i < bindings.length; i++) {
      var b = bindings[i]
      if (b.custom) {
        custom.push(b)
      } else {
        var def = null
        for (var j = 0; j < _manifestDefaults.length; j++) {
          if (_manifestDefaults[j].id === b.id) { def = _manifestDefaults[j]; break }
        }
        if (def) {
          var changed = false
          var override = {}
          if (b.mod !== def.mod) { override.mod = b.mod; changed = true }
          if (b.key !== def.key) { override.key = b.key; changed = true }
          if (b.actionType !== def.actionType) { override.actionType = b.actionType; changed = true }
          if (b.action !== def.action) { override.action = b.action; changed = true }
          if (JSON.stringify(b.args) !== JSON.stringify(def.args)) { override.args = b.args; changed = true }
          if (b.description !== def.description) { override.description = b.description; changed = true }
          if (changed) overrides[b.id] = override
        }
      }
    }

    Store.keybindings.overrides = overrides
    Store.keybindings.custom = custom
  }

  function _generateHyprConfig(): void {
    var lines = []
    lines.push("local mainMod = \"SUPER\"")
    lines.push("")
    lines.push("-------------------")
    lines.push("---- BINDS -------")
    lines.push("-------------------")

    var currentCategory = ""
    var bindCount = 0

    for (var i = 0; i < bindings.length; i++) {
      var b = bindings[i]

      if (b.category !== currentCategory) {
        currentCategory = b.category
        var catLabel = currentCategory
        for (var c = 0; c < categories.length; c++) {
          if (categories[c].id === currentCategory) { catLabel = categories[c].label; break }
        }
        lines.push("")
        lines.push("-- " + catLabel)
      }

      var mod = b.mod || ""
      var key = b.key || ""

      var keyExpr = _buildKeyExpr(mod, key)

      var dispatcherExpr = _buildDispatcherExpr(b)

      var flags = ""
      if (b.locked) flags += "locked = true, "
      if (b.repeating) flags += "repeating = true, "
      if (flags.length > 0) flags = flags.substring(0, flags.length - 2)

      if (flags !== "") {
        lines.push("hl.bind(" + keyExpr + ", " + dispatcherExpr + ", { " + flags + " })")
      } else {
        lines.push("hl.bind(" + keyExpr + ", " + dispatcherExpr + ")")
      }
      bindCount++
    }

    lines.push("")
    lines.push("-- Mouse bindings")
    lines.push("hl.bind(mainMod .. \" + mouse:272\", hl.dsp.window.drag(),   { mouse = true })")
    lines.push("hl.bind(mainMod .. \" + mouse:273\", hl.dsp.window.resize(), { mouse = true })")
    lines.push("")
    lines.push("-- Keybind capture guard (settings editor parks here while recording)")
    lines.push("hl.define_submap(\"qs-capture\", function()")
    lines.push("  hl.bind(\"CTRL + ALT + Escape\", hl.dsp.submap(\"reset\"))")
    lines.push("end)")

    var config = lines.join("\n")
    _writeConfig(config)
  }

  function _safeDirection(dir: var): string {
    return ["left", "right", "up", "down"].indexOf(String(dir)) >= 0 ? String(dir) : "left"
  }

  function _buildKeyExpr(mod: string, key: string): string {
    key = _escapeLua(key)
    mod = _escapeLua(mod)
    if (mod === "") return "\"" + key + "\""

    if (mod === "SUPER") {
      return "mainMod .. \" + " + key + "\""
    }
    if (mod.startsWith("SUPER ")) {
      var extra = mod.substring(6)
      return "mainMod .. \" + " + extra.replace(/ /g, " + ") + " + " + key + "\""
    }

    return "\"" + mod.replace(/ /g, " + ") + " + " + key + "\""
  }

  function _buildDispatcherExpr(b: var): string {
    var actionType = b.actionType || "custom"
    var action = b.action || ""
    var args = b.args || {}

    switch (actionType) {
      case "shell":
        return _buildShellExpr(action)
      case "hypr":
        return _buildHyprExpr(action, args)
      case "global":
        return "hl.dsp.global(\"quickshell:" + action + "\")"
      case "custom":
      default:
        return "function() hl.exec_cmd(\"" + _escapeLua(action) + "\") end"
    }
  }

  function _buildShellExpr(action: string): string {
    var parts = action.split(".")
    if (parts.length === 2) {
      return "function() hl.exec_cmd(\"qs ipc call " + parts[0] + " " + parts[1] + "\") end"
    }
    return "function() hl.exec_cmd(\"" + _escapeLua(action) + "\") end"
  }

  function _buildHyprExpr(action: string, args: var): string {
    switch (action) {
      case "closewindow":
        return "hl.dsp.window.close()"
      case "fullscreen":
        return "hl.dsp.window.fullscreen()"
      case "pseudo":
        return "hl.dsp.window.pseudo()"
      case "togglefloating":
        return "hl.dsp.window.float({ action = \"toggle\" })"
      case "movefocus":
        return "hl.dsp.focus({ direction = \"" + _safeDirection(args.direction) + "\" })"
      case "movewindow":
        return "hl.dsp.window.move({ direction = \"" + _safeDirection(args.direction) + "\" })"
      case "resizeactive":
        var rzParams = /^-?[0-9]+%? -?[0-9]+%?$/.test(String(args.params || "")) ? String(args.params) : "0 0"
        return "function() hl.exec_cmd(\"hyprctl dispatch resizeactive " + rzParams + "\") end"
      case "workspace":
        var wsArg = args.id
        if (wsArg === undefined || wsArg === null) wsArg = "1"
        if (typeof wsArg === "number" || !isNaN(wsArg)) return "hl.dsp.focus({ workspace = " + parseInt(wsArg) + " })"
        return "hl.dsp.focus({ workspace = \"" + _escapeLua(wsArg) + "\" })"
      case "movetoworkspace":
        var mwsArg = args.id
        if (mwsArg === undefined || mwsArg === null) mwsArg = "1"
        if (typeof mwsArg === "number" || !isNaN(mwsArg)) return "hl.dsp.window.move({ workspace = " + parseInt(mwsArg) + " })"
        return "hl.dsp.window.move({ workspace = \"" + _escapeLua(mwsArg) + "\" })"
      case "togglespecialworkspace":
        var spName = String(args.name || "magic").replace(/[^A-Za-z0-9_-]/g, "")
        return "hl.dsp.workspace.toggle_special(\"" + (spName || "magic") + "\")"
      case "exit":
        return "function() hl.exec_cmd(\"hyprctl dispatch exit\") end"
      case "exec":
        return "hl.dsp.exec_cmd(\"" + _escapeLua(args.cmd || "") + "\")"
      default:
        return "function() hl.exec_cmd(\"" + _escapeLua(action) + "\") end"
    }
  }

  function _escapeLua(str: string): string {
    return String(str)
      .replace(/[\r\n\t]/g, " ")
      .replace(/[\u0000-\u001F\u007F]/g, "")
      .replace(/\\/g, "\\\\")
      .replace(/"/g, "\\\"")
  }

  function _writeConfig(content: string): void {
    var path = AppInfo.hyprDir + "/keybinds.lua"
    HyprlandService.writeAndReload(path, content, function(r) {
      if (r.exitCode !== 0)
        Logger.warn("keybinds", "Failed to write keybinds.lua: " + (r.stderr || ""))
    })
  }

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════

  function _regenerate(): void {
    svc._mergeBindings()
    svc._generateHyprConfig()
  }

  Connections {
    target: AppInfo
    function onManifestChanged() {
      svc._loadDefaults()
      svc._regenerate()
    }
  }

  Component.onCompleted: {
    if (AppInfo.manifest && Object.keys(AppInfo.manifest).length > 0) {
      _loadDefaults()
      _regenerate()
    }
  }
}
