import QtQuick
import QtQuick.Layouts
import "../../styles"
import "../../services"
import "../../components"

Column {
  id: root
  spacing: Theme.spaceLg
  width: parent.width

  PageHeader { title: "AUDIO" }

  // ── Output ─────────────────────────────────────────────────────────
  Card {
    width: parent.width
    title: "OUTPUT"
    description: AudioService.sinkName

    Column {
      width: parent.width
      spacing: Theme.spaceSm

      RowLayout {
        width: parent.width
        spacing: Theme.spaceSm

        Button {
          shape: "default"
          size: "sm"
          text: AudioService.muted ? "MUTED" : "ACTIVE"
          bgColor: AudioService.muted ? Theme.warning : Theme.success
          color: Theme.background
          onClicked: AudioService.toggleMute()
        }

        Item { Layout.fillWidth: true }
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
        visible: AudioService.outputDevices.length > 1
      }

      Column {
        width: parent.width
        spacing: Theme.space2
        visible: AudioService.outputDevices.length > 1

        Repeater {
          model: AudioService.outputDevices

          DeviceRow {
            width: parent.width
            icon: "speaker-high"
            name: modelData.name
            subtitle: modelData.isDefault ? "DEFAULT" : (modelData.isEasyEffects ? "EE" : "")
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

  // ── Input ──────────────────────────────────────────────────────────
  Card {
    width: parent.width
    title: "INPUT"
    description: AudioService.sourceName

    Column {
      width: parent.width
      spacing: Theme.spaceSm

      RowLayout {
        width: parent.width
        spacing: Theme.spaceSm

        Button {
          shape: "default"
          size: "sm"
          text: AudioService.micMuted ? "MUTED" : "ACTIVE"
          bgColor: AudioService.micMuted ? Theme.warning : Theme.success
          color: Theme.background
          onClicked: AudioService.toggleMicMute()
        }

        Item { Layout.fillWidth: true }
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
        visible: AudioService.inputDevices.length > 1
      }

      Column {
        width: parent.width
        spacing: Theme.space2
        visible: AudioService.inputDevices.length > 1

        Repeater {
          model: AudioService.inputDevices

          DeviceRow {
            width: parent.width
            icon: "phone"
            name: modelData.name
            subtitle: modelData.isDefault ? "DEFAULT" : ""
            active: modelData.isDefault
            onClicked: {
              if (!modelData.isDefault) {
                AudioService.setInputDevice(modelData.node)
              }
            }
          }
        }
      }
    }
  }

  // ── Plugin-hosted content ───────────────────────────────────────────
  PluginHost { location: "audio" }
}
