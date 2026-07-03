pragma Singleton
import QtQml
import QtQuick
import Quickshell
import Quickshell.Io
import "../styles"
import "./"

Singleton {
  id: store

  signal loaded()
  signal changed(string key, var value, var previous)

  property var _data: ({})
  property var _watchers: ({})
  property bool _dirReady: false
  property string _pendingJson: ""

  readonly property string _cfgDir: AppInfo.cacheHome

  function get(key: string, fallback: var): var {
    return _data.hasOwnProperty(key) ? _data[key] : fallback
  }

  function getString(key: string, fallback: string): string {
    var value = get(key, fallback)
    return typeof value === "string" ? value : fallback
  }

  function getInt(key: string, fallback: int): int {
    var value = get(key, fallback)
    return typeof value === "number" ? Math.floor(value) : fallback
  }

  function getBool(key: string, fallback: bool): bool {
    var value = get(key, fallback)
    return typeof value === "boolean" ? value : fallback
  }

  function getObject(key: string, fallback: var): var {
    var value = get(key, fallback)
    return value && typeof value === "object" && !Array.isArray(value) ? value : fallback
  }

  function getArray(key: string, fallback: var): var {
    var value = get(key, fallback)
    return Array.isArray(value) ? value : fallback
  }

  function getAll(): var {
    var out = ({})
    var keys = Object.keys(_data)
    for (var i = 0; i < keys.length; i++) out[keys[i]] = _data[keys[i]]
    return out
  }

  function watch(key: string, callback: var): var {
    if (!_watchers[key]) _watchers[key] = []
    _watchers[key].push(callback)
    return { key: key, callback: callback }
  }

  function unwatch(handle: var): void {
    if (!handle || !handle.key || !handle.callback) return
    var list = _watchers[handle.key]
    if (!list) return
    var idx = list.indexOf(handle.callback)
    if (idx >= 0) list.splice(idx, 1)
  }

  function loadedLater(delay: int, callback: var): void {
    var t = Qt.createQmlObject("import QtQuick; Timer { repeat: false }", store)
    t.interval = delay
    t.triggered.connect(function() { callback(); t.destroy() })
    if (_loaded) t.start()
    else loaded.connect(function() { t.start() })
  }

  property bool _loaded: false

  function _notify(key: string, value: var, previous: var): void {
    var watchers = _watchers[key]
    if (watchers) {
      for (var i = watchers.length - 1; i >= 0; i--) {
        try {
          watchers[i](key, value, previous)
        } catch (e) {
          watchers.splice(i, 1)
        }
      }
    }
    changed(key, value, previous)
  }

  function set(key: string, value: var): void {
    var previous = _data[key]
    if (_data[key] === value) return
    var copy = {}
    var keys = Object.keys(_data)
    for (var i = 0; i < keys.length; i++) copy[keys[i]] = _data[keys[i]]
    copy[key] = value
    _data = copy
    _notify(key, value, previous)
    _scheduleSave()
  }

  function setBatch(updates: var): void {
    var updateKeys = Object.keys(updates)
    var touched = false
    var copy = {}
    var existing = Object.keys(_data)
    for (var i = 0; i < existing.length; i++) copy[existing[i]] = _data[existing[i]]
    for (var j = 0; j < updateKeys.length; j++) {
      var key = updateKeys[j]
      var previous = _data[key]
      var next = updates[key]
      if (previous === next) continue
      copy[key] = next
      _notify(key, next, previous)
      touched = true
    }
    if (touched) {
      _data = copy
      _scheduleSave()
    }
  }

  Timer {
    id: saveDebounce
    interval: 50
    repeat: false
    onTriggered: store._flushSave()
  }

  function _scheduleSave(): void {
    saveDebounce.restart()
  }

  function _flushSave(): void {
    _pendingJson = JSON.stringify(_data)
    if (!_dirReady) {
      _dirReady = true
    }
    ProcessPool.runDetached([
      "sh", "-c",
      "mkdir -p \"$1\" && f=\"$1/config.json\" && tmp=\"$f.tmp\" && printf '%s' \"$2\" > \"$tmp\" && mv \"$tmp\" \"$f\"",
      "--", _cfgDir, _pendingJson
    ], { id: "store-flush", silent: true })
  }

  Process {
    id: loader
    stdout: StdioCollector { waitForEnd: true }
    stderr: StdioCollector { waitForEnd: true }
    onExited: function() {
      try {
        var parsed = JSON.parse(stdout.text || "{}")
        if (parsed && typeof parsed === "object") {
          var copy = {}
          var existing = Object.keys(_data)
          for (var i = 0; i < existing.length; i++) copy[existing[i]] = _data[existing[i]]
          var keys = Object.keys(parsed)
          for (var j = 0; j < keys.length; j++) copy[keys[j]] = parsed[keys[j]]
          _data = copy
        }
      } catch (e) {
      }
      
      _dirReady = true
      _loaded = true
      loaded()
    }
  }

  function _load(): void {
    if (loader.running) return
    var script = 'f="' + _cfgDir + '/config.json"; if [ -s "$f" ]; then cat "$f"; else echo "{}"; fi'
    loader.command = ["sh", "-c", script]
    loader.running = true
  }

  Component.onCompleted: _load()
}
