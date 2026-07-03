pragma ComponentBehavior: Bound
import QtQuick
import QtQml
import "../../../../styles"
import "../../../../components"
import "../../../../core"
import "../../../"

BasePlugin {
  id: root

  // ── Manifest ────────────────────────────────────────────────────
  pluginId: "media"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Media",
    description: "Now playing controls",
    icon: "music",
    locations: ["controlcenter_row"],
    settings: []
  })

  // ── Public state ─────────────────────────────────────────────────

  // ── Internal state ───────────────────────────────────────────────

  // ── Signal handlers ──────────────────────────────────────────────

  // ── Public API ───────────────────────────────────────────────────

  // ── Helpers ──────────────────────────────────────────────────────

  // ── Timers ───────────────────────────────────────────────────────

  // ── Lifecycle ────────────────────────────────────────────────────

  // ── UI components ────────────────────────────────────────────────
  property Component controlCenterComponent: Column {
    width: parent.width
    spacing: Theme.spaceSm

    SectionLabel {
      label: "MEDIA"
    }

    Text {
      text: MediaService.hasPlayer ? "" : "NO MEDIA PLAYING"
      color: Theme.textDisabled
      font.pixelSize: Theme.fontSizeCaption
      font.family: Theme.fontFamilyMono
      visible: !MediaService.hasPlayer
    }

    Column {
      width: parent.width
      spacing: Theme.space2
      visible: MediaService.hasPlayer

      Text {
        text: MediaService.currentTitle
        color: Theme.textPrimary
        font.pixelSize: Theme.fontSizeLabel
        font.family: Theme.fontFamilyMono
        elide: Text.ElideRight
        width: parent.width
      }

      Text {
        text: MediaService.currentArtist || "Unknown Artist"
        color: Theme.textSecondary
        font.pixelSize: Theme.fontSizeCaption
        font.family: Theme.fontFamilyMono
      }

      Row {
        spacing: Theme.spaceMd
        anchors.horizontalCenter: parent.horizontalCenter

        Button { shape: "circle"; 
          icon: "skip-back"
          size: 28
          iconSize: 11
          onClicked: MediaService.previous()
        }

        Button { shape: "circle"; 
          icon: MediaService.playbackStatus === "Playing" ? "pause" : "play"
          size: 28
          iconSize: 11
          bgColor: Theme.textDisplay
          iconColor: Theme.background
          onClicked: MediaService.playPause()
        }

        Button { shape: "circle"; 
          icon: "skip-forward"
          size: 28
          iconSize: 11
          onClicked: MediaService.next()
        }
      }
    }
  }
}
