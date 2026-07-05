pragma ComponentBehavior: Bound
import QtQuick
import QtQml
import QtQuick.Layouts
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
    locations: ["controlcenter_row", "dashboard"],
    defaultLayout: { "controlcenter_row": { order: 10 }, "dashboard": { order: 40 } },
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
  property Component dashboardComponent: Card {
    title: "NOW PLAYING"
    visible: MediaService.hasPlayer

    ColumnLayout {
      width: parent.width
      spacing: Theme.spaceSm

      function fmtDuration(secs) {
        var h = Math.floor(secs / 3600)
        var m = Math.floor((secs % 3600) / 60)
        return h + "h " + m + "m"
      }

      RowLayout {
        spacing: Theme.spaceSm

        Rectangle {
          width: 44; height: 44
          radius: Theme.radiusSmall
          color: Theme.backgroundTertiary

          Image {
            id: dashArt
            anchors.fill: parent
            anchors.margins: 2
            source: MediaService.currentArtUrl
            fillMode: Image.PreserveAspectCrop
            visible: status === Image.Ready
          }
          Icon {
            anchors.centerIn: parent
            source: Icons.get("music")
            size: 18
            color: Theme.textDisabled
            visible: dashArt.status !== Image.Ready
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Theme.space2

          Text {
            text: MediaService.currentTitle
            color: Theme.textDisplay
            font.pixelSize: Theme.fontSizeBody
            font.family: Theme.fontFamilyMono
            elide: Text.ElideRight
            maximumLineCount: 1
            Layout.fillWidth: true
          }
          Text {
            text: MediaService.currentArtist
            color: Theme.textDisabled
            font.pixelSize: Theme.fontSizeCaption
            font.family: Theme.fontFamilyMono
            elide: Text.ElideRight
            maximumLineCount: 1
            Layout.fillWidth: true
          }
        }
      }

      ProgressBar {
        Layout.fillWidth: true
        visible: !MediaService._isStream
        value: MediaService.duration > 0 ? MediaService.position / MediaService.duration : 0
        barHeight: 3
      }

      RowLayout {
        Layout.fillWidth: true

        Text {
          text: MediaService._isStream ? "LIVE" : parent.parent.fmtDuration(MediaService.position)
          color: MediaService._isStream ? Theme.error : Theme.textDisabled
          font.pixelSize: Theme.fontSizeMicro
          font.family: Theme.fontFamilyMono
          font.weight: MediaService._isStream ? Font.Bold : Font.Normal
        }
        Item { Layout.fillWidth: true }
        Text {
          text: MediaService._isStream ? "" : parent.parent.fmtDuration(MediaService.duration)
          color: Theme.textDisabled
          font.pixelSize: Theme.fontSizeMicro
          font.family: Theme.fontFamilyMono
        }
      }
    }
  }

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
