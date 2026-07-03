import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../styles"
import "../../core"
import "../../services"
import "../../components"
import "../../overlays/osd"
import "../../overlays/battery"
import "../../overlays/toast"

PanelWindow {
  id: bar
  required property var modelData

  screen: modelData
  color: "transparent"
  anchors { top: true; left: true; right: true }

  readonly property int barH: Theme.barHeight
  readonly property int barHFloating: barH + Theme.spaceSm
  readonly property int exclusiveH: barH + Theme.spaceXs
  readonly property int exclusiveHFloating: barHFloating + Theme.spaceXs

  margins.top: AppearanceService.barFloating ? Theme.spaceSm : 0
  margins.left: AppearanceService.barFloating ? Theme.spaceSm : 0
  margins.right: AppearanceService.barFloating ? Theme.spaceSm : 0
  margins.bottom: 0

  implicitHeight: AppearanceService.barFloating ? barHFloating : barH
  exclusiveZone: AppearanceService.barFloating ? exclusiveHFloating : exclusiveH

  property var _busHandles: []

  function _syncBarGeometry(): void {
    var isFloating = AppearanceService.barFloating
    var h = isFloating ? barHFloating : barH
    var topMargin = isFloating ? Theme.spaceSm : 0
    BarService.updateBar(0, topMargin, bar.width > 0 ? bar.width : screen.width, h, isFloating, Theme.spaceXs)
  }

  Component.onCompleted: {
    bar._syncBarGeometry()
  }

  onVisibleChanged: {
    if (visible) {
      _barSyncTimer.restart()
    } else {
      BarService.updateBar(0, 0, 0, 0, AppearanceService.barFloating, Theme.spaceXs)
    }
  }

  Timer {
    id: _barSyncTimer
    interval: 50
    repeat: false
    onTriggered: bar._syncBarGeometry()
  }

  Component.onDestruction: {
  }

  Connections {
    target: IpcService
    function onBatteryToggle() { bar.toggleBatteryTooltip() }
  }

  Connections {
    target: AudioService
    function onVolumeChanged() {
      var icon = AudioService.muted ? "volume-mute" : "volume"
      osdOverlay.show(icon, AudioService.volume / 1.5, "")
    }
    function onMutedChanged() {
      var icon = AudioService.muted ? "volume-mute" : "volume"
      osdOverlay.show(icon, AudioService.volume / 1.5, "")
    }
  }

  Connections {
    target: BrightnessService
    function onBrightnessChanged() {
      osdOverlay.show("brightness", BrightnessService.brightness, "BRIGHTNESS " + BrightnessService.brightnessPct + "%")
    }
  }

  Connections {
    target: NotificationService
    function onNotificationsChanged() {
      var notif = NotificationService.notifications[0]
      if (notif) {
        var p = nextNotifPopup()
        p.show(notif.summary || "", notif.body || "", notif.icon || "", notif.appName || "", notif.urgency || 1, notif.actions || [])
      }
    }
  }

  onWidthChanged: bar._syncBarGeometry()
  onHeightChanged: bar._syncBarGeometry()

  Connections {
    target: AppearanceService
    function onBarFloatingChanged(): void {
      bar._syncBarGeometry()
    }
  }

  function toggleBatteryTooltip(): void {
    if (!batteryTooltipLoader.active) {
      batteryTooltipLoader.active = true
      Qt.callLater(bar.toggleBatteryTooltip)
      return
    }
    if (!batteryTooltipLoader.item) {
      Qt.callLater(bar.toggleBatteryTooltip)
      return
    }

    var tooltip = batteryTooltipLoader.item
    if (tooltip.visible) {
      tooltip.visible = false
    } else {
      tooltip.anchorItem = PopupAnchors.batteryWidget
      tooltip.visible = true
    }
  }

  Rectangle {
    visible: AppearanceService.barFloating
    anchors.fill: parent
    color: Theme.panelBackground
    radius: Theme.radiusUI
    border.width: Theme.borderWidth
    border.color: Theme.border
  }

  Rectangle {
    visible: !AppearanceService.barFloating
    anchors.fill: parent
    color: Theme.panelBackground

    Rectangle {
      anchors {
        left: parent.left
        right: parent.right
        bottom: parent.bottom
      }
      height: Theme.borderWidth
      color: Theme.border
    }
  }

  PluginHost {
    id: leftSection
    location: "bar_left"
    layout: "row"
    anchors { left: parent.left; leftMargin: Theme.spaceSm; verticalCenter: parent.verticalCenter }
  }

  PluginHost {
    id: centerSection
    location: "bar_center"
    layout: "row"
    anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
  }

  PluginHost {
    id: rightSection
    location: "bar_right"
    layout: "row"
    anchors { right: parent.right; rightMargin: Theme.spaceSm; verticalCenter: parent.verticalCenter }
  }

  OSD {
    id: osdOverlay
  }

  LazyLoader {
    id: batteryTooltipLoader
    active: false

    BatteryTooltip {
      id: batteryTooltip
      visible: false
      Component.onCompleted: PopupAnchors.batteryTooltip = batteryTooltip
      onVisibleChanged: { if (!visible) batteryTooltipLoader.active = false }
      Component.onDestruction: {
        if (PopupAnchors.batteryTooltip === batteryTooltip) PopupAnchors.batteryTooltip = null
      }
    }
  }

  Toast { id: toast0; slot: 0 }
  Toast { id: toast1; slot: 1 }
  Toast { id: toast2; slot: 2 }
  Toast { id: toast3; slot: 3 }

  function nextNotifPopup(): var {
    var popups = [toast0, toast1, toast2, toast3]
    for (var i = 0; i < popups.length; i++) {
      if (!popups[i].shown) return popups[i]
    }
    return popups[0]
  }
}
