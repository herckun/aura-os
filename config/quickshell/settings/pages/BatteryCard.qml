import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../styles"
import "../../core"
import "../../components"

Column {
  id: root

  property var battery: BatteryService
  property var resources: ResourceService

  width: parent.width
  spacing: Theme.spaceMd

  // ── Hero ──────────────────────────────────────────────
  Row {
    width: parent.width
    spacing: Theme.spaceMd

    Icon {
      source: Icons.get(root.battery.charging ? "bolt" : root.battery.percentage < 20 ? "alert" : "battery")
      size: 28
      color: root.battery.percentage < 20 ? Theme.warning : root.battery.charging ? Theme.success : Theme.accent
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      text: Math.round(root.battery.percentage) + "%"
      color: root.battery.percentage < 20 ? Theme.warning : Theme.textDisplay
      font.pixelSize: Theme.fontSizeDisplayLarge
      font.family: Theme.fontFamilyDisplay
      font.letterSpacing: -0.03
      font.weight: Font.DemiBold
      anchors.verticalCenter: parent.verticalCenter
    }

    Item { width: 1; height: 1; Layout.fillWidth: true }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      spacing: Theme.spaceXs

      Row {
        spacing: Theme.spaceSm

        Badge {
          text: root.battery.charging ? "CHARGING" : root.battery.discharging ? "DISCHARGING" : "FULL"
          variant: root.battery.charging ? "success" : root.battery.discharging ? "warning" : "default"
          size: "sm"
        }

        Badge {
          text: Math.floor(
            (root.battery.charging ? root.battery.timeToFull : root.battery.timeToEmpty) / 3600
          ) + "h " + Math.floor(
            ((root.battery.charging ? root.battery.timeToFull : root.battery.timeToEmpty) % 3600) / 60
          ) + "m"
          variant: "default"
          size: "sm"
          visible: (root.battery.charging && root.battery.timeToFull > 0) ||
                   (root.battery.discharging && root.battery.timeToEmpty > 0)
        }
      }

      Text {
        text: root.battery.modelName
        color: Theme.textDisabled
        font.pixelSize: Theme.fontSizeMicro
        font.family: Theme.fontFamilyMono
        visible: root.battery.modelName !== ""
      }
    }
  }

  // ── Charge bar ────────────────────────────────────────
  Rectangle {
    width: parent.width
    height: 28
    radius: Theme.radiusSmall
    antialiasing: true
    color: Theme.backgroundTertiary
    clip: true

    Rectangle {
      id: chargeFill
      width: parent.width * Math.min(1, Math.max(0, root.battery.percentage / 100))
      height: parent.height
      color: root.battery.percentage < 20 ? Theme.warning : Theme.accent
      radius: Theme.radiusSmall
      antialiasing: true

      Behavior on width {
        enabled: Theme.animationsEnabled
        NumberAnimation { duration: Theme.animationSlow; easing.type: Easing.OutCubic }
      }

      Rectangle {
        anchors.right: parent.right
        width: 60
        height: parent.height
        color: Qt.lighter(chargeFill.color, 1.3)
        radius: Theme.radiusSmall
        antialiasing: true
        visible: root.battery.charging

        SequentialAnimation on opacity {
          loops: Animation.Infinite
          PropertyAnimation { to: 0.6; duration: Theme.animationSlow; easing.type: Easing.InOutSine }
          PropertyAnimation { to: 0.0; duration: Theme.animationSlow; easing.type: Easing.InOutSine }
        }
      }
    }

    Repeater {
      model: [0.2, 0.8]
      delegate: Rectangle {
        x: parent.width * modelData - 1
        width: 2
        height: parent.height
        color: Qt.alpha(Theme.background, 0.35)
      }
    }

    Repeater {
      model: [20, 80]
      delegate: Text {
        x: (parent.width * modelData / 100) - 12
        y: parent.height + Theme.spaceXs
        text: modelData + "%"
        color: Theme.textDisabled
        font.pixelSize: Theme.fontSizeMicro
        font.family: Theme.fontFamilyMono
      }
    }
  }

  // ── Metrics ───────────────────────────────────────────
  RowLayout {
    width: parent.width
    spacing: Theme.spaceMd

    ColumnLayout { spacing: Theme.space2; Layout.alignment: Qt.AlignTop
      Text { text: "CAPACITY"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; font.letterSpacing: 0.08 }
      Text { text: root.battery.energyCapacity.toFixed(1) + " Wh"; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeCaption; font.family: Theme.fontFamilyMono }
    }

    ColumnLayout { spacing: Theme.space2; Layout.alignment: Qt.AlignTop
      Text { text: "RATE"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; font.letterSpacing: 0.08 }
      Row { spacing: Theme.spaceXs
        Text { text: root.battery.changeRate !== 0 ? Math.abs(root.battery.changeRate).toFixed(1) : "—"; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeCaption; font.family: Theme.fontFamilyMono }
        Text { text: "W"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeCaption; font.family: Theme.fontFamilyMono }
        Icon { source: Icons.get(root.battery.charging ? "arrow-up" : root.battery.discharging ? "arrow-down" : "minus"); size: 10; color: root.battery.charging ? Theme.success : Theme.textDisabled; anchors.verticalCenter: parent.verticalCenter }
      }
    }

    ColumnLayout { spacing: Theme.space2; Layout.alignment: Qt.AlignTop
      Text { text: "HEALTH"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; font.letterSpacing: 0.08 }
      Row { spacing: Theme.spaceXs; Layout.alignment: Qt.AlignVCenter
        Text { text: root.battery.healthSupported ? Math.round(root.battery.healthPercentage) + "%" : "—"; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeCaption; font.family: Theme.fontFamilyMono; anchors.verticalCenter: parent.verticalCenter }
        Badge { text: root.battery.healthSupported ? (root.battery.healthPercentage > 90 ? "OK" : root.battery.healthPercentage > 70 ? "FAIR" : "WEAK") : ""; variant: root.battery.healthPercentage > 90 ? "success" : root.battery.healthPercentage > 70 ? "warning" : "error"; size: "xxs"; visible: root.battery.healthSupported; anchors.verticalCenter: parent.verticalCenter }
      }
    }
  }

  // ── Draining ──────────────────────────────────────────
  Divider { width: parent.width }

  Column {
    width: parent.width
    spacing: Theme.spaceSm

    RowLayout {
      width: parent.width
      spacing: Theme.spaceSm

      Icon { source: Icons.get("bolt"); size: 12; color: Theme.error; Layout.alignment: Qt.AlignVCenter }

      Text {
        text: "DRAINING"
        color: Theme.textSecondary
        font.pixelSize: Theme.fontSizeMicro
        font.family: Theme.fontFamilyMono
        font.letterSpacing: 0.08
        Layout.fillWidth: true
      }

      Text {
        text: root.battery.discharging ? Math.abs(root.battery.changeRate).toFixed(1) + " W" : root.battery.charging ? "↑ " + Math.abs(root.battery.changeRate).toFixed(1) + " W" : ""
        color: root.battery.discharging ? Theme.error : Theme.success
        font.pixelSize: Theme.fontSizeMicro
        font.family: Theme.fontFamilyMono
      }
    }

    ProcessList {
      width: parent.width
      processes: root.resources.topCpuProcesses
      maxItems: 4
    }
  }
}
