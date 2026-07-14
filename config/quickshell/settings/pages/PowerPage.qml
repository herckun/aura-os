import QtQuick
import QtQuick.Layouts
import "../../styles"
import "../../core"
import "../../services"
import "../../components"

Column {
  id: root
  spacing: Theme.spaceLg
  width: parent.width

  PageHeader { title: "POWER"; description: "Power profile, idle suspend and battery" }

  Card {
    width: parent.width
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

  Card {
    width: parent.width
    title: "IDLE"
    description: "Lock and suspend after inactivity"

    Column {
      width: parent.width
      spacing: 0

      SettingRow {
        width: parent.width
        label: "AUTO LOCK"
        description: "Lock the screen when idle"
        Toggle {
          toggleWidth: 38
          toggleHeight: 20
          checked: LockService.autoLock
          onToggled: (v) => LockService.setAutoLock(v)
        }
      }

      Divider {
        width: parent.width
        visible: LockService.autoLock
      }

      SettingRow {
        width: parent.width
        label: "LOCK AFTER"
        visible: LockService.autoLock
        SelectDropdown {
          width: 160
          placeholder: "Minutes..."
          items: [1, 2, 5, 10, 15, 30].map((m) => ({
            label: m + (m === 1 ? " MINUTE" : " MINUTES"),
            value: m
          }))
          value: LockService.autoLockMinutes
          onItemSelected: (item) => LockService.setAutoLockMinutes(item.value)
        }
      }

      Divider { width: parent.width }

      SettingRow {
        width: parent.width
        label: "AUTO SUSPEND"
        description: "Suspend the system when idle"
        Toggle {
          toggleWidth: 38
          toggleHeight: 20
          checked: PowerService.autoSuspend
          onToggled: (v) => PowerService.setAutoSuspend(v)
        }
      }

      Divider {
        width: parent.width
        visible: PowerService.autoSuspend
      }

      SettingRow {
        width: parent.width
        label: "SUSPEND AFTER"
        visible: PowerService.autoSuspend
        SelectDropdown {
          width: 160
          placeholder: "Minutes..."
          items: [5, 10, 15, 20, 30, 45, 60, 90, 120].map((m) => ({
            label: m >= 60 ? (m / 60) + (m === 60 ? " HOUR" : " HOURS") : m + " MINUTES",
            value: m
          }))
          value: PowerService.autoSuspendMinutes
          onItemSelected: (item) => PowerService.setAutoSuspendMinutes(item.value)
        }
      }

      Item {
        width: parent.width
        height: Theme.spaceSm
        visible: suspendHint.visible
      }

      Text {
        id: suspendHint
        width: parent.width
        visible: PowerService.autoSuspend && LockService.autoLock && PowerService.autoSuspendMinutes <= LockService.autoLockMinutes
        text: "Suspend will fire before the screen locks"
        color: Theme.warning
        font.pixelSize: Theme.fontSizeCaption
        font.family: Theme.fontFamilyMono
        wrapMode: Text.WordWrap
      }

    }
  }

  Card {
    width: parent.width
    title: "BATTERY"
    visible: BatteryService.hasBattery

    Column {
      width: parent.width
      spacing: Theme.spaceMd

      BatteryCard {
        battery: BatteryService
        resources: ResourceService
      }

      Divider { width: parent.width }

      Column {
        width: parent.width
        spacing: 0

        SettingRow {
          width: parent.width
          label: "AUTO BATTERY SAVER"
          description: "Switch to battery saver when the battery runs low, back when charging"
          Toggle {
            toggleWidth: 38
            toggleHeight: 20
            checked: PowerService.autoBatterySaver
            onToggled: (v) => PowerService.setAutoBatterySaver(v)
          }
        }

        Item {
          width: parent.width
          height: Theme.spaceSm
          visible: PowerService.autoBatterySaver
        }

        SliderControl {
          width: parent.width
          visible: PowerService.autoBatterySaver
          label: "ACTIVATE BELOW"
          from: 5
          to: 50
          stepSize: 5
          displayMin: 5
          displayMax: 50
          unit: "%"
          value: PowerService.autoBatterySaverThreshold
          onMoved: (v) => PowerService.setAutoBatterySaverThreshold(v)
        }
      }
    }
  }
}
