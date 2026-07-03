import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../../../styles"
import "../../../../core"
import "../../../../lib"
import "../../../../services"
import "../../../../components"

PanelWindow {
  id: batteryPopup

  implicitWidth: 260
  implicitHeight: contentCol.implicitHeight + 24

  anchors { top: true; left: true }
  margins.top: PopupPositioner.belowBar()
  margins.left: popupX
  exclusiveZone: 0
  color: "transparent"
  visible: false

  mask: Region { item: bg }

  property Item anchorItem: null
  property real popupX: PopupPositioner.anchorRightX(anchorItem, batteryPopup.width, batteryPopup.screen ? batteryPopup.screen.width : 0)

  function _recalcPopupX() {
    popupX = PopupPositioner.anchorRightX(anchorItem, batteryPopup.width, batteryPopup.screen ? batteryPopup.screen.width : 0)
  }

  onWidthChanged: _recalcPopupX()
  onScreenChanged: _recalcPopupX()

  onVisibleChanged: {
    if (visible) { _recalcPopupX(); animFrame = 0; chargeAnim.start() }
    else chargeAnim.stop()
  }

  property real animFrame: 0

  NumberAnimation on animFrame {
    id: chargeAnim
    from: 0; to: 1; duration: Theme.animationSlow; loops: Animation.Infinite
    running: false
  }

  HyprlandFocusGrab {
    windows: [batteryPopup]
    active: batteryPopup.visible
    onCleared: batteryPopup.visible = false
  }

  function toggle(): void {
    visible = !visible
  }

  Timer {
    id: leaveTimer
    interval: 2000
    onTriggered: batteryPopup.visible = false
  }

  HoverHandler {
    onHoveredChanged: {
      if (hovered) leaveTimer.stop()
      else if (batteryPopup.visible) leaveTimer.restart()
    }
  }

  Rectangle {
    id: bg
    anchors.fill: parent
    radius: Theme.radiusLarge
    color: Theme.backgroundSecondary
    border.width: Theme.borderWidth
    border.color: Theme.border

    Column {
      id: contentCol
      anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: Theme.spaceMd }
      anchors.topMargin: Theme.spaceMd + 4
      spacing: Theme.spaceSm

      // ── Hero: percentage + status ──────────────────
      RowLayout {
        width: parent.width
        spacing: Theme.spaceSm

        Text {
          text: Math.round(BatteryService.percentage)
          color: Theme.textDisplay
          font.pixelSize: Theme.fontSizeDisplay
          font.family: Theme.fontFamilyDisplay
          font.weight: Font.Bold
        }

        Column {
          Layout.alignment: Qt.AlignBottom
          Layout.bottomMargin: Theme.spaceXs
          spacing: Theme.space2

          Text {
            text: "%"
            color: Theme.textDisabled
            font.pixelSize: Theme.fontSizeBody
            font.family: Theme.fontFamilyMono
          }
        }

        Item { Layout.fillWidth: true }
      }

      // ── Battery canvas ─────────────────────────────
      Canvas {
        id: battCanvas
        width: parent.width
        height: 40
        property real pct: BatteryService.percentage / 100
        property bool charging: BatteryService.charging
        property real anim: batteryPopup.animFrame

        onAnimChanged: requestPaint()

        onPaint: {
          var ctx = getContext("2d")
          ctx.reset()
          var w = width, h = height

          var bx = 0
          var by = 4
          var bw = w - 10
          var bh = 28
          var br = 4
          var nubW = 5
          var nubH = 12

          ctx.beginPath()
          ctx.roundedRect(bx + bw, by + (bh - nubH) / 2, nubW, nubH, 2, 2)
          ctx.fillStyle = Theme.borderVisible
          ctx.fill()

          ctx.beginPath()
          ctx.roundedRect(bx, by, bw, bh, br, br)
          ctx.lineWidth = 1
          ctx.strokeStyle = Theme.borderVisible
          ctx.stroke()

          var inset = 2
          var fw = (bw - inset * 2) * pct
          var fh = bh - inset * 2
          var fillColor = pct < 0.2 ? Theme.error : pct < 0.5 ? Theme.warning : Theme.success

          if (charging) {
            ctx.save()
            ctx.beginPath()
            ctx.roundedRect(bx + inset, by + inset, bw - inset * 2, fh, br - 1, br - 1)
            ctx.clip()

            ctx.beginPath()
            ctx.roundedRect(bx + inset, by + inset, fw, fh, 2, 2)
            ctx.fillStyle = fillColor
            ctx.fill()

            var lx = bx + bw / 2
            var ly = by + bh / 2
            ctx.beginPath()
            ctx.moveTo(lx + 1, ly - 8)
            ctx.lineTo(lx - 3, ly + 1)
            ctx.lineTo(lx + 1, ly + 1)
            ctx.lineTo(lx - 1, ly + 8)
            ctx.lineTo(lx + 3, ly - 1)
            ctx.lineTo(lx - 1, ly - 1)
            ctx.closePath()
            ctx.fillStyle = Theme.textDisplay
            ctx.globalAlpha = 0.9
            ctx.fill()
            ctx.globalAlpha = 1.0

            ctx.restore()
          } else {
            ctx.beginPath()
            ctx.roundedRect(bx + inset, by + inset, fw, fh, 2, 2)
            ctx.fillStyle = fillColor
            ctx.fill()
          }
        }

        Connections {
          target: BatteryService
          function onPercentageChanged() { battCanvas.requestPaint() }
          function onChargingChanged() { battCanvas.requestPaint() }
        }

        Component.onCompleted: {
          battCanvas.requestPaint()
        }
      }

      // ── Stats grid ────────────────────────────────
      GridLayout {
        width: parent.width
        columns: 2
        columnSpacing: Theme.spaceSm
        rowSpacing: Theme.spaceXs

        StatCell { label: "TIME"; value: Helpers.formatDurationHm(BatteryService.discharging ? BatteryService.timeToEmpty : BatteryService.timeToFull) }
        StatCell { label: "TIME AVG"; value: BatteryService.avgTimeToEmpty > 0 ? Helpers.formatDurationHm(BatteryService.avgTimeToEmpty) : "—" }
        StatCell { label: "POWER"; value: (BatteryService.discharging || BatteryService.charging) ? Helpers.formatWatts(BatteryService.changeRate) : "—" }
        StatCell { label: "POWER AVG"; value: BatteryService.avgPowerRate > 0 ? Helpers.formatWatts(BatteryService.avgPowerRate) : "—" }
        StatCell { label: "CAPACITY"; value: BatteryService.energyCapacity > 0 ? BatteryService.energy.toFixed(0) + " / " + BatteryService.energyCapacity.toFixed(0) + " Wh" : "—" }
        StatCell { label: "HEALTH"; value: BatteryService.healthSupported ? BatteryService.healthPercentage.toFixed(0) + "%" : "—" }
      }

      // ── Model name ─────────────────────────────────
      Text {
        width: parent.width
        text: (BatteryService.modelName || "").toUpperCase()
        color: Theme.textDisabled
        font.pixelSize: Theme.fontSizeMicro
        font.family: Theme.fontFamilyMono
        font.letterSpacing: 0.06
        elide: Text.ElideRight
        maximumLineCount: 1
        visible: BatteryService.modelName !== ""
        horizontalAlignment: Text.AlignHCenter
      }
    }
  }

  component StatCell: Column {
    property string label: ""
    property string value: ""
    Layout.fillWidth: true
    spacing: Theme.space2

    Text {
      text: label
      color: Theme.textDisabled
      font.pixelSize: Theme.fontSizeMicro
      font.family: Theme.fontFamilyMono
      font.letterSpacing: 0.08
    }

    Text {
      text: value
      color: Theme.textPrimary
      font.pixelSize: Theme.fontSizeCaption
      font.family: Theme.fontFamilyMono
      font.weight: Font.DemiBold
    }
  }
}
