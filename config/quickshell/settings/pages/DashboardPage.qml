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

  function formatDuration(secs: real): string {
    var h = Math.floor(secs / 3600)
    var m = Math.floor((secs % 3600) / 60)
    return h + "h " + m + "m"
  }

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
            font.family: Theme.fontFamilyDisplay
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
            font.family: Theme.fontFamilyDisplay
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
            font.family: Theme.fontFamilyDisplay
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

  // ── Disk ───────────────────────────────────────────────
  Card {
    Layout.fillWidth: true
    title: "DISK"
    visible: ResourceService.diskTotal !== ""

    ColumnLayout {
      width: parent.width
      spacing: Theme.spaceSm

      RowLayout {
        Text {
          id: diskUsed
          text: ResourceService.diskUsed
          color: Theme.textDisplay
          font.pixelSize: Theme.fontSizeTitle
          font.family: Theme.fontFamilyDisplay
        }
        Text {
          text: "/ " + ResourceService.diskTotal
          color: Theme.textDisabled
          font.pixelSize: Theme.fontSizeCaption
          font.family: Theme.fontFamilyMono
          Layout.alignment: Qt.AlignBottom
          Layout.bottomMargin: Theme.space2
        }
        Item { Layout.fillWidth: true }
        Text {
          text: ResourceService.diskFree + " free"
          color: Theme.textDisabled
          font.pixelSize: Theme.fontSizeCaption
          font.family: Theme.fontFamilyMono
          Layout.alignment: Qt.AlignBottom
          Layout.bottomMargin: Theme.space2
        }
      }

      ProgressBar {
        Layout.fillWidth: true
        value: {
          var t = parseFloat(ResourceService.diskTotal)
          var u = parseFloat(ResourceService.diskUsed)
          return (t > 0 && !isNaN(t) && !isNaN(u)) ? u / t : 0
        }
        barHeight: 4
      }
    }
  }

  // ── Weather + Now Playing ──────────────────────────────
  GridLayout {
    Layout.fillWidth: true
    columns: 2
    columnSpacing: Theme.spaceMd
    visible: WeatherService.hasData || MediaService.hasPlayer

    Card {
      Layout.fillWidth: true
      title: "WEATHER"
      visible: WeatherService.hasData

      GridLayout {
        width: parent.width
        columns: 2
        columnSpacing: Theme.spaceMd
        rowSpacing: 2

        Text {
          text: WeatherService.wmoIcon(WeatherService.weatherCode)
          color: Theme.textDisplay
          font.pixelSize: Theme.fontSizeHeading
          Layout.rowSpan: 2
          Layout.alignment: Qt.AlignTop
        }
        Text {
          text: WeatherService.temp
          color: Theme.textDisplay
          font.pixelSize: Theme.fontSizeTitle2
          font.family: Theme.fontFamilyDisplay
          Layout.rowSpan: 2
          Layout.alignment: Qt.AlignTop
        }

        Text { text: WeatherService.weather; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeCaption; font.family: Theme.fontFamilyMono; Layout.columnSpan: 2 }
        Text { text: "FEELS  " + WeatherService.feelsLike; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono }
        Text { text: "HUMIDITY  " + WeatherService.humidity; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono }
        Text { text: "WIND  " + WeatherService.windSpeed + " " + WeatherService.windDir; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; elide: Text.ElideRight; maximumLineCount: 1; Layout.fillWidth: true }
        Text { text: "PRESSURE  " + WeatherService.pressure; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono }
        Text { text: "UV  " + WeatherService.uvIndex; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono }
        Text { text: "SUNRISE  " + WeatherService.sunrise; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono }
        Text { text: "SUNSET  " + WeatherService.sunset; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono }
      }
    }

    Card {
      Layout.fillWidth: true
      Layout.fillHeight: true
      title: "NOW PLAYING"
      visible: MediaService.hasPlayer

      ColumnLayout {
        width: parent.width
        spacing: Theme.spaceSm

        RowLayout {
          spacing: Theme.spaceSm

          Rectangle {
            width: 44; height: 44
            radius: Theme.radiusSmall
            color: Theme.backgroundTertiary

            Image {
              id: artImage
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
              visible: artImage.status !== Image.Ready
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
            text: MediaService._isStream ? "LIVE" : formatDuration(MediaService.position)
            color: MediaService._isStream ? Theme.error : Theme.textDisabled
            font.pixelSize: Theme.fontSizeMicro
            font.family: Theme.fontFamilyMono
            font.weight: MediaService._isStream ? Font.Bold : Font.Normal
          }
          Item { Layout.fillWidth: true }
          Text {
            text: MediaService._isStream ? "" : formatDuration(MediaService.duration)
            color: Theme.textDisabled
            font.pixelSize: Theme.fontSizeMicro
            font.family: Theme.fontFamilyMono
          }
        }
      }
    }
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
