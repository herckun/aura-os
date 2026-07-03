pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  readonly property string iconDir: AppInfo.quickshellDir + "/icons"

  property var _map: ({})

  function iconPath(name: string): string {
    return "file://" + iconDir + "/" + name + ".svg"
  }

  function get(name: string): string {
    if (!name || name.length === 0) return ""
    return iconPath(name)
  }

  function _loadFromManifest(): void {
    var m = AppInfo.manifest
    if (m && m.icons && m.icons.map) {
      root._map = m.icons.map
    }
  }

  Connections {
    target: AppInfo
    function onManifestChanged() { root._loadFromManifest() }
  }

  Component.onCompleted: _loadFromManifest()
}
