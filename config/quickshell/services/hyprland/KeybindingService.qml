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

  function updateBinding(id: string, updates: var): void {
    var copy = bindings.slice()
    for (var i = 0; i < copy.length; i++) {
      if (copy[i].id === id) {
        copy[i] = Object.assign({}, copy[i], updates)
        break
      }
    }
    bindings = copy
    _saveUserOverrides()
    _generateHyprConfig()
  }

  function addCustomBinding(binding: var): void {
    var copy = bindings.slice()
    copy.push(Object.assign({}, binding, { custom: true }))
    bindings = copy
    _saveUserOverrides()
    _generateHyprConfig()
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
    Store.set("keybindings.overrides", {})
    Store.set("keybindings.custom", [])
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
    var overrides = Store.getObject("keybindings.overrides", {})
    var custom = Store.getArray("keybindings.custom", [])
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

    Store.set("keybindings.overrides", overrides)
    Store.set("keybindings.custom", custom)
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

    var config = lines.join("\n")
    _writeConfig(config)
  }

  function _buildKeyExpr(mod: string, key: string): string {
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
        return "hl.dsp.focus({ direction = \"" + (args.direction || "left") + "\" })"
      case "movewindow":
        return "hl.dsp.window.move({ direction = \"" + (args.direction || "left") + "\" })"
      case "resizeactive":
        return "function() hl.exec_cmd(\"hyprctl dispatch resizeactive " + (args.params || "0 0") + "\") end"
      case "workspace":
        var wsArg = args.id
        if (wsArg === undefined || wsArg === null) wsArg = "1"
        if (typeof wsArg === "number" || !isNaN(wsArg)) return "hl.dsp.focus({ workspace = " + wsArg + " })"
        return "hl.dsp.focus({ workspace = \"" + wsArg + "\" })"
      case "movetoworkspace":
        var mwsArg = args.id
        if (mwsArg === undefined || mwsArg === null) mwsArg = "1"
        if (typeof mwsArg === "number" || !isNaN(mwsArg)) return "hl.dsp.window.move({ workspace = " + mwsArg + " })"
        return "hl.dsp.window.move({ workspace = \"" + mwsArg + "\" })"
      case "togglespecialworkspace":
        return "hl.dsp.workspace.toggle_special(\"" + (args.name || "magic") + "\")"
      case "exit":
        return "function() hl.exec_cmd(\"hyprctl dispatch exit\") end"
      case "exec":
        return "hl.dsp.exec_cmd(\"" + _escapeLua(args.cmd || "") + "\")"
      default:
        return "function() hl.exec_cmd(\"" + _escapeLua(action) + "\") end"
    }
  }

  function _escapeLua(str: string): string {
    return str.replace(/\\/g, "\\\\").replace(/"/g, "\\\"")
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

  Connections {
    target: AppInfo
    function onManifestChanged() {
      svc._loadDefaults()
      svc._generateHyprConfig()
    }
  }

  Component.onCompleted: {
    if (AppInfo.manifest && Object.keys(AppInfo.manifest).length > 0) {
      _loadDefaults()
      _generateHyprConfig()
    }
  }
}
