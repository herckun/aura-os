import QtQuick
import QtQuick.Layouts
import "../../styles"
import "../../core"
import "../../services"
import "../../components"

ColumnLayout {
  id: root
  spacing: Theme.spaceLg
  width: parent.width

  // ── Header ─────────────────────────────────────────────
  Column {
    spacing: Theme.space2

    PageHeader { title: "DASHBOARD" }
    Text {
      text: [ResourceService.hostname, ResourceService.kernel, ResourceService.uptime].filter(function(s){ return s !== "" }).join("  •  ")
      color: Theme.textDisabled
      font.pixelSize: Theme.fontSizeCaption
      font.family: Theme.fontFamilyMono
      elide: Text.ElideRight
      maximumLineCount: 1
    }
  }

  // ── Power Profile ──────────────────────────────────────
  Card {
    Layout.fillWidth: true
    title: "POWER PROFILE"
    description: "System power and performance balance"

    Column {
      width: parent.width
      spacing: Theme.spaceMd

      OptionSwitcher {
        width: parent.width
        variant: "accent"
        options: ["PERFORMANCE", "BALANCED", "BATTERY SAVER"]
        currentIndex: PerformanceService.profile
        onSelected: (idx) => PerformanceService.switchProfile(idx)
      }

      RowLayout {
        width: parent.width
        spacing: Theme.spaceSm

        Text {
          text: {
            switch (PerformanceService.profile) {
              case 0: return "Max performance, higher power draw"
              case 1: return "Balanced performance and battery life"
              case 2: return "Max battery life, reduced performance"
              default: return ""
            }
          }
          color: Theme.textSecondary
          font.pixelSize: Theme.fontSizeCaption
          font.family: Theme.fontFamilyMono
          elide: Text.ElideRight
          Layout.fillWidth: true
        }

        Badge {
          text: BatteryService.charging ? "CHARGING" : BatteryService.discharging ? "BATTERY" : "AC"
          variant: BatteryService.charging ? "success" : "default"
          size: "sm"
          visible: BatteryService.hasBattery
        }
      }
    }
  }

  // ── Battery ───────────────────────────────────────────
  Card {
    Layout.fillWidth: true
    title: "BATTERY"
    visible: BatteryService.hasBattery

    BatteryCard {
      battery: BatteryService
      resources: ResourceService
    }
  }

  // ── CPU + Memory ───────────────────────────────────────
  GridLayout {
    Layout.fillWidth: true
    Layout.preferredHeight: 240
    columns: 2
    columnSpacing: Theme.spaceMd

    Card {
      Layout.fillWidth: true
      Layout.fillHeight: true
      title: "PROCESSOR"

      ColumnLayout {
        width: parent.width
        spacing: Theme.spaceSm

        RowLayout {
          Text {
            id: cpuVal
            text: ResourceService.cpuUsage
            color: Theme.textDisplay
            font.pixelSize: Theme.fontSizeDisplay
            font.family: Theme.fontFamilyDeco
          }
          Text {
            text: "%"
            color: Theme.textDisabled
            font.pixelSize: Theme.fontSizeTitle
            font.family: Theme.fontFamilyMono
            Layout.alignment: Qt.AlignBottom
            Layout.bottomMargin: Theme.spaceXs
          }
          Item { Layout.fillWidth: true }
          Text {
            text: ResourceService.cpuTemp !== "" ? ResourceService.cpuTemp + "°" : ""
            color: Theme.warning
            font.pixelSize: Theme.fontSizeTitle
            font.family: Theme.fontFamilyDeco
            Layout.alignment: Qt.AlignBottom
            Layout.bottomMargin: Theme.spaceXs
          }
        }

        ProgressBar {
          Layout.fillWidth: true
          value: ResourceService.cpuUsage / 100
          barHeight: 4
        }

        ProcessList {
          Layout.fillWidth: true
          Layout.fillHeight: true
          processes: ResourceService.topCpuProcesses
        }
      }
    }

    Card {
      Layout.fillWidth: true
      Layout.fillHeight: true
      title: "MEMORY"

      ColumnLayout {
        width: parent.width
        spacing: Theme.spaceSm

        RowLayout {
          Text {
            id: memVal
            text: ResourceService.memUsed
            color: Theme.textDisplay
            font.pixelSize: Theme.fontSizeDisplay
            font.family: Theme.fontFamilyDeco
          }
          Text {
            text: "MB"
            color: Theme.textDisabled
            font.pixelSize: Theme.fontSizeCaption
            font.family: Theme.fontFamilyMono
            Layout.alignment: Qt.AlignBottom
            Layout.bottomMargin: Theme.spaceXs
          }
          Text {
            text: "/ " + ResourceService.memTotal
            color: Theme.textDisabled
            font.pixelSize: Theme.fontSizeCaption
            font.family: Theme.fontFamilyMono
            Layout.alignment: Qt.AlignBottom
            Layout.bottomMargin: Theme.spaceXs
          }
        }

        ProgressBar {
          Layout.fillWidth: true
          value: ResourceService.memPct / 100
          barHeight: 4
        }

        ProcessList {
          Layout.fillWidth: true
          Layout.fillHeight: true
          processes: ResourceService.topMemProcesses
          unit: "MB"
        }
      }
    }
  }

  // ── Status Row ─────────────────────────────────────────
  GridLayout {
    Layout.fillWidth: true
    Layout.preferredHeight: 80
    columns: 3
    columnSpacing: Theme.spaceSm

    StatCard {
      Layout.fillWidth: true
      Layout.fillHeight: true
      label: "NETWORK"
      value: NetworkService.online ? (NetworkService.primarySsid || "ETH") : "OFFLINE"
      barValue: NetworkService.signalStrength / 100
      barColor: Theme.accent
    }

    StatCard {
      Layout.fillWidth: true
      Layout.fillHeight: true
      label: "AUDIO"
      value: AudioService.muted ? "MUTED" : Math.round(AudioService.volume * 100) + "%"
      barValue: AudioService.muted ? 0 : AudioService.volume
      barColor: AudioService.muted ? Theme.warning : Theme.accent
    }

    StatCard {
      Layout.fillWidth: true
      Layout.fillHeight: true
      label: "BRIGHTNESS"
      value: BrightnessService.brightnessPct + "%"
      barValue: BrightnessService.brightness
      barColor: Theme.accent
      visible: BrightnessService.hasDevice
    }
  }

  // ── Hardware ───────────────────────────────────────────
  PluginHost {
    Layout.fillWidth: true
    location: "dashboard"
  }

  // ── System Info ────────────────────────────────────────
  GridLayout {
    Layout.fillWidth: true
    Layout.preferredHeight: 40
    columns: 3
    columnSpacing: Theme.spaceSm

    Repeater {
      model: [
        { label: "BT", value: BluetoothService.enabled ? (BluetoothService.devices.length > 0 ? BluetoothService.devices[0].name : "ON") : "OFF", active: BluetoothService.enabled, visible: BluetoothService.hasBluetooth },
        { label: "UPD", value: UpdatesService.hasUpdates ? UpdatesService.pendingUpdates + " PKGS" : "UP TO DATE", active: UpdatesService.hasUpdates },
        { label: "PLG", value: PluginService.getPluginsForLocation("settings").length + " ACTIVE", active: true }
      ]

      delegate: InfoCard {
        Layout.fillWidth: true
        Layout.fillHeight: true
        label: modelData.label
        infoValue: modelData.value
        active: modelData.active
        visible: modelData.visible !== false
      }
    }
  }

  Item { Layout.fillHeight: true }
}
