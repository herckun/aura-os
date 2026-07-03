pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  // ═══════════════════════════════════════════════════════════════
  //  APP INFO (loaded from manifest.json)
  // ═══════════════════════════════════════════════════════════════

  property string name: "aura-os"
  property string displayName: "AuraOS"
  property string version: "2.0"
  property string logo: "assets/logo.svg"
  property var credits: ([])

  // ═══════════════════════════════════════════════════════════════
  //  DIRECTORY PATHS (authoritative source)
  // ═══════════════════════════════════════════════════════════════

  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
  readonly property string cacheHome: Quickshell.env(_envPrefix + "_CACHE_DIR")
    || (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/" + name
  readonly property string picturesDir: Quickshell.env("XDG_PICTURES_DIR") || (Quickshell.env("HOME") + "/Pictures")

  readonly property string hyprDir: configHome + "/hypr"
  readonly property string featuresDir: configHome + "/features"
  readonly property string quickshellDir: configHome + "/quickshell"
  readonly property string wallpaperDir: picturesDir + "/wallpapers/" + name

  readonly property string manifestPath: Qt.resolvedUrl("../manifest.json").toString().replace("file://", "")

  // ═══════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════

  readonly property string _envPrefix: name.toUpperCase().replace(/-/g, "_")

  function logoPath(): string {
    return Qt.resolvedUrl("../" + root.logo).toString()
  }

  // ═══════════════════════════════════════════════════════════════
  //  MANIFEST LOADER
  // ═══════════════════════════════════════════════════════════════

  property var manifest: ({})

  Process {
    id: _loader
    command: ["cat", root.manifestPath]
    stdout: StdioCollector { waitForEnd: true }
    onExited: {
      try {
        var d = JSON.parse(stdout.text)
        root.manifest = d
        root.name = d.app.name || "aura-os"
        root.displayName = d.app.displayName || "AuraOS"
        root.version = d.app.version || "2.0"
        root.logo = d.app.logo || "assets/logo.svg"
        root.credits = d.credits || []
      } catch(e) {
      }
    }
  }
  Component.onCompleted: _loader.running = true
}
