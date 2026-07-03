import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "../../styles"
import "../../core"
import "../../services"
import "../../components"

Column {
  id: root
  spacing: Theme.spaceLg
  width: parent.width

  PageHeader { title: "AUDIO" }

  // ── Output ─────────────────────────────────────────────────────────
  Surface {
    width: parent.width
    height: outputCol.implicitHeight + Theme.spaceLg * 2
    radius: Theme.radiusMedium
    border.color: Theme.border
    padding: Theme.spaceLg

    Column {
      id: outputCol
      width: parent.width
      spacing: Theme.spaceMd

      RowLayout {
        width: parent.width
        spacing: Theme.spaceSm

        Surface {
          Layout.preferredWidth: 36
          Layout.preferredHeight: 36
          level: 2
          bordered: false
          radius: Theme.radiusMedium

          Icon {
            anchors.centerIn: parent
            source: Icons.get(AudioService.muted ? "volume-mute" : "speaker-high")
            size: 16
            color: AudioService.muted ? Theme.warning : Theme.accent
          }
        }

        Column {
          Layout.fillWidth: true
          spacing: Theme.spaceXxs

          Text {
            width: parent.width
            text: "OUTPUT"
            color: Theme.textPrimary
            font.pixelSize: Theme.fontSizeLabel
            font.family: Theme.fontFamilyMono
            font.weight: Font.Bold
            font.letterSpacing: 0.08
          }

          Text {
            width: parent.width
            text: AudioService.sinkName
            color: Theme.textDisabled
            font.pixelSize: Theme.fontSizeMicro
            font.family: Theme.fontFamilyMono
            elide: Text.ElideRight
          }
        }

        Button {
          text: AudioService.muted ? "UNMUTE" : "MUTE"
          size: "sm"
          icon: AudioService.muted ? "volume" : "volume-mute"
          variant: AudioService.muted ? "accent" : "default"
          onClicked: AudioService.toggleMute()
        }
      }

      SliderControl {
        width: parent.width
        label: "VOLUME"
        from: 0
        to: 1.5
        value: AudioService.volume
        displayMin: 0
        displayMax: 100
        unit: "%"
        dangerThreshold: 0.67
        criticalThreshold: 1.0
        onMoved: (v) => AudioService.setVolume(v)
      }

      SectionLabel {
        label: "DEVICES"
        visible: AudioService.outputDevices.length > 0
      }

      Column {
        width: parent.width
        spacing: Theme.space2

        Repeater {
          model: AudioService.outputDevices

          DeviceRow {
            width: parent.width
            icon: "speaker-high"
            name: modelData.name
            subtitle: modelData.isDefault ? "DEFAULT" : (modelData.isVirtual ? "VIRTUAL" : "")
            active: modelData.isDefault
            onClicked: {
              if (!modelData.isDefault) {
                AudioService.setOutputDevice(modelData.node)
              }
            }
          }
        }
      }
    }
  }

  // ── Mixer ──────────────────────────────────────────────────────────
  Surface {
    width: parent.width
    height: mixerCol.implicitHeight + Theme.spaceLg * 2
    radius: Theme.radiusMedium
    border.color: Theme.border
    padding: Theme.spaceLg
    visible: AudioService.playbackStreams.length > 0

    Column {
      id: mixerCol
      width: parent.width
      spacing: Theme.spaceMd

      RowLayout {
        width: parent.width
        spacing: Theme.spaceSm

        Surface {
          Layout.preferredWidth: 36
          Layout.preferredHeight: 36
          level: 2
          bordered: false
          radius: Theme.radiusMedium

          Icon {
            anchors.centerIn: parent
            source: Icons.get("music-note")
            size: 16
            color: Theme.accent
          }
        }

        Column {
          Layout.fillWidth: true
          spacing: Theme.spaceXxs

          Text {
            text: "MIXER"
            color: Theme.textPrimary
            font.pixelSize: Theme.fontSizeLabel
            font.family: Theme.fontFamilyMono
            font.weight: Font.Bold
            font.letterSpacing: 0.08
          }

          Text {
            text: "Per-application volume"
            color: Theme.textDisabled
            font.pixelSize: Theme.fontSizeMicro
            font.family: Theme.fontFamilyMono
          }
        }

        Badge {
          text: AudioService.playbackStreams.length + " STREAM" + (AudioService.playbackStreams.length !== 1 ? "S" : "")
          size: "sm"
        }
      }

      Repeater {
        model: AudioService.playbackStreams

        Column {
          id: streamRow
          width: parent.width

          property var streamNode: modelData.node
          readonly property real streamVolume: streamNode && streamNode.audio ? streamNode.audio.volume : 0
          readonly property bool streamMuted: streamNode && streamNode.audio ? streamNode.audio.muted : false

          PwObjectTracker { objects: streamRow.streamNode ? [streamRow.streamNode] : [] }

          SliderControl {
            width: parent.width
            label: modelData.name.toUpperCase() + (modelData.media !== "" && modelData.media !== modelData.name ? "  ·  " + modelData.media : "")
            iconName: streamRow.streamMuted ? "volume-mute" : "volume"
            iconColor: streamRow.streamMuted ? Theme.warning : Theme.textSecondary
            onIconClicked: AudioService.toggleNodeMute(streamRow.streamNode)
            from: 0
            to: 1
            value: streamRow.streamVolume
            displayMin: 0
            displayMax: 100
            unit: "%"
            onMoved: (v) => AudioService.setNodeVolume(streamRow.streamNode, v)
          }
        }
      }
    }
  }

  // ── Input ──────────────────────────────────────────────────────────
  Surface {
    width: parent.width
    height: inputCol.implicitHeight + Theme.spaceLg * 2
    radius: Theme.radiusMedium
    border.color: Theme.border
    padding: Theme.spaceLg

    Column {
      id: inputCol
      width: parent.width
      spacing: Theme.spaceMd

      RowLayout {
        width: parent.width
        spacing: Theme.spaceSm

        Surface {
          Layout.preferredWidth: 36
          Layout.preferredHeight: 36
          level: 2
          bordered: false
          radius: Theme.radiusMedium

          Icon {
            anchors.centerIn: parent
            source: Icons.get("phone")
            size: 16
            color: AudioService.micMuted ? Theme.warning : Theme.accent
          }
        }

        Column {
          Layout.fillWidth: true
          spacing: Theme.spaceXxs

          Text {
            width: parent.width
            text: "INPUT"
            color: Theme.textPrimary
            font.pixelSize: Theme.fontSizeLabel
            font.family: Theme.fontFamilyMono
            font.weight: Font.Bold
            font.letterSpacing: 0.08
          }

          Text {
            width: parent.width
            text: AudioService.sourceName
            color: Theme.textDisabled
            font.pixelSize: Theme.fontSizeMicro
            font.family: Theme.fontFamilyMono
            elide: Text.ElideRight
          }
        }

        Badge {
          text: "IN USE"
          variant: "accent"
          size: "sm"
          visible: AudioService.recordingStreams.length > 0
        }

        Button {
          text: AudioService.micMuted ? "UNMUTE" : "MUTE"
          size: "sm"
          icon: AudioService.micMuted ? "volume" : "volume-mute"
          variant: AudioService.micMuted ? "accent" : "default"
          onClicked: AudioService.toggleMicMute()
        }
      }

      SliderControl {
        width: parent.width
        label: "INPUT LEVEL"
        from: 0
        to: 1.5
        value: AudioService.micVolume
        displayMin: 0
        displayMax: 100
        unit: "%"
        onMoved: (v) => AudioService.setMicVolume(v)
      }

      SectionLabel {
        label: "DEVICES"
        visible: AudioService.inputDevices.length > 0
      }

      Column {
        width: parent.width
        spacing: Theme.space2

        Repeater {
          model: AudioService.inputDevices

          DeviceRow {
            width: parent.width
            icon: "phone"
            name: modelData.name
            subtitle: modelData.isDefault ? "DEFAULT" : (modelData.isVirtual ? "VIRTUAL" : "")
            active: modelData.isDefault
            onClicked: {
              if (!modelData.isDefault) {
                AudioService.setInputDevice(modelData.node)
              }
            }
          }
        }
      }

      SectionLabel {
        label: "IN USE BY"
        visible: AudioService.recordingStreams.length > 0
      }

      Column {
        width: parent.width
        spacing: Theme.space2
        visible: AudioService.recordingStreams.length > 0

        Repeater {
          model: AudioService.recordingStreams

          Rectangle {
            id: recRow
            width: parent.width
            height: Theme.controlHeight + Theme.spaceSm
            radius: Theme.radiusSmall
            color: recHover.containsMouse ? Theme.controlBackgroundHover : "transparent"

            property var streamNode: modelData.node
            readonly property bool streamMuted: streamNode && streamNode.audio ? streamNode.audio.muted : false

            PwObjectTracker { objects: recRow.streamNode ? [recRow.streamNode] : [] }

            MouseArea {
              id: recHover
              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.NoButton
              z: -1
            }

            RowLayout {
              anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: Theme.spaceSm }
              spacing: Theme.spaceSm

              Rectangle {
                width: 6
                height: 6
                radius: 3
                color: recRow.streamMuted ? Theme.textDisabled : Theme.error
              }

              Text {
                Layout.fillWidth: true
                text: modelData.name.toUpperCase()
                color: recRow.streamMuted ? Theme.textDisabled : Theme.textPrimary
                font.pixelSize: Theme.fontSizeCaption
                font.family: Theme.fontFamilyMono
                font.letterSpacing: 0.04
                elide: Text.ElideRight
              }

              Button {
                text: recRow.streamMuted ? "UNMUTE" : "MUTE"
                size: "sm"
                onClicked: AudioService.toggleNodeMute(recRow.streamNode)
              }
            }
          }
        }
      }
    }
  }

  // ── Sound effects ────────────────────────────────────────────────────
  Surface {
    width: parent.width
    height: sfxRow.height + Theme.spaceLg * 2
    radius: Theme.radiusMedium
    border.color: Theme.border
    padding: Theme.spaceLg

    SettingRow {
      id: sfxRow
      label: "SOUND EFFECTS"
      description: "System sounds for volume, notifications, battery, devices and more"

      Toggle {
        toggleWidth: 38
        toggleHeight: 20
        checked: SfxService.enabled
        onToggled: (v) => SfxService.setEnabled(v)
      }
    }
  }

  // ── Plugin-hosted content ───────────────────────────────────────────
  PluginHost { location: "audio" }
}
