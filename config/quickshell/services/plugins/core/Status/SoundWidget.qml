import QtQuick
import "../../../../styles"
import "../../../../core"
import "../../../../services"
import "../../../../components"

Item {
  id: root

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: soundTooltip.toggle()
    onWheel: (wheel) => {
      var d = wheel.angleDelta.y > 0 ? 0.05 : -0.05
      AudioService.setVolume(AudioService.volume + d)
    }
  }

  SoundTooltip {
    id: soundTooltip
    anchorItem: root
  }

  implicitWidth: row.width
  implicitHeight: 22

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.spaceXs

    Icon {
      source: Icons.get(AudioService.muted || AudioService.volume === 0 ? "volume-mute"
        : AudioService.volume > 0.5 ? "speaker-low" : "speaker-high")
      size: 13
      color: AudioService.muted ? Theme.textDisabled : Theme.textPrimary
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      text: AudioService.muted ? "MUTE" : Math.round(AudioService.volume * 100) + "%"
      color: AudioService.muted ? Theme.textDisabled : Theme.textPrimary
      font.pixelSize: Theme.fontSizeCaption
      font.family: Theme.fontFamilyMono
      font.letterSpacing: 0.04
      anchors.verticalCenter: parent.verticalCenter
    }
  }
}
