pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: store

  property bool freshInstall: false

  property alias appearance: adapter.appearance
  property alias theme: adapter.theme
  property alias shell: adapter.shell
  property alias performance: adapter.performance
  property alias wallpaper: adapter.wallpaper
  property alias media: adapter.media
  property alias network: adapter.network
  property alias sfx: adapter.sfx
  property alias hotareas: adapter.hotareas
  property alias keybindings: adapter.keybindings
  property alias apps: adapter.apps
  property alias search: adapter.search
  property alias plugins: adapter.plugins
  property alias desktop: adapter.desktop

  function mapSet(map: var, key: string, value: var): var {
    var m = Object.assign({}, map || {})
    m[key] = value
    return m
  }

  function mapPatch(map: var, key: string, patch: var): var {
    var m = Object.assign({}, map || {})
    m[key] = Object.assign({}, m[key] || {}, patch)
    return m
  }

  FileView {
    id: file
    path: AppInfo.configHome + "/" + AppInfo.name + "/settings.json"
    blockLoading: true
    watchChanges: true
    atomicWrites: true
    printErrors: true
    onFileChanged: reload()
    onAdapterUpdated: saveTimer.restart()
    onLoadFailed: (error) => {
      if (error === FileViewError.FileNotFound) {
        store.freshInstall = true
        mkdirProc.running = true
      }
    }
    onSaveFailed: (error) => {
      if (error === FileViewError.FileNotFound && !mkdirProc.running) mkdirProc.running = true
    }

    JsonAdapter {
      id: adapter

      property JsonObject appearance: JsonObject {
        property bool animations: true
        property bool blur: true
        property bool transparency: true
        property bool barFloating: false
      }

      property JsonObject theme: JsonObject {
        property string accent: "#D71921"
        property bool accentManual: false
        property bool monochrome: false
      }

      property JsonObject shell: JsonObject {
        property int mode: 0
      }

      property JsonObject performance: JsonObject {
        property int profile: 1
      }

      property JsonObject wallpaper: JsonObject {
        property bool autoCycle: false
        property int autoCycleMinutes: 30
        property var history: ([])
      }

      property JsonObject media: JsonObject {
        property string lastPlayerIdentity: ""
        property var excludePlayers: ([])
      }

      property JsonObject network: JsonObject {
        property string lastConnectionType: ""
        property string lastSsid: ""
        property string lastWiredName: ""
      }

      property JsonObject sfx: JsonObject {
        property bool enabled: true
      }

      property JsonObject hotareas: JsonObject {
        property var enabled: ({})
      }

      property JsonObject keybindings: JsonObject {
        property var overrides: ({})
        property var custom: ([])
      }

      property JsonObject apps: JsonObject {
        property var defaults: ({})
      }

      property JsonObject search: JsonObject {
        property var disabled: ([])
      }

      property JsonObject plugins: JsonObject {
        property var enabled: ({})
        property var order: ({})
        property var settings: ({})
      }

      property JsonObject desktop: JsonObject {
        property var widgets: ({})
      }
    }
  }

  Timer {
    id: saveTimer
    interval: 150
    repeat: false
    onTriggered: file.writeAdapter()
  }

  Process {
    id: mkdirProc
    command: ["mkdir", "-p", AppInfo.configHome + "/" + AppInfo.name]
    onExited: file.writeAdapter()
  }
}
