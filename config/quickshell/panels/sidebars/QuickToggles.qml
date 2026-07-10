import QtQuick
import QtQuick.Layouts
import "../../styles"
import "../../services"
import "../../components"

GridLayout {
  id: root

  readonly property int maxShown: 6
  property bool expanded: false
  property int _shownCount: 0

  width: parent ? parent.width : implicitWidth
  columns: _shownCount <= 0 ? 1
    : _shownCount <= 3 ? _shownCount
    : _shownCount === 4 ? 2
    : 3
  columnSpacing: Theme.spaceSm
  rowSpacing: Theme.spaceSm

  function relayout(): void {
    var avail = []
    for (var i = 0; i < children.length; i++) {
      var c = children[i]
      if (!c || c === moreTile || !c.hasOwnProperty("available")) continue
      if (c.available) avail.push(c)
      else c.visible = false
    }
    var overflow = avail.length > maxShown
    var cap = overflow && !expanded ? maxShown - 1 : avail.length
    for (var j = 0; j < avail.length; j++) avail[j].visible = j < cap
    moreTile.visible = overflow
    _shownCount = cap + (overflow ? 1 : 0)
  }

  onExpandedChanged: relayout()
  Component.onCompleted: relayout()

  Button {
    property bool available: NetworkService.hasWifi
    onAvailableChanged: root.relayout()
    shape: "tile"
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredHeight: tileContentHeight
    icon: "wifi"
    label: "WIFI"
    actionId: "wifi-toggle"
    active: NetworkService.wifiEnabled
    onClicked: NetworkService.toggleWifi()
  }

  Button {
    property bool available: BluetoothService.hasBluetooth
    onAvailableChanged: root.relayout()
    shape: "tile"
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredHeight: tileContentHeight
    icon: "bluetooth"
    label: "BT"
    actionId: "bt-toggle"
    active: BluetoothService.enabled && BluetoothService.devices.length > 0
    onClicked: BluetoothService.toggle()
  }

  Button {
    property bool available: VpnService.available
    onAvailableChanged: root.relayout()
    shape: "tile"
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredHeight: tileContentHeight
    icon: VpnService.activeProvider ? VpnService.activeProvider.icon : "shield"
    label: "VPN"
    sublabel: !VpnService.connected ? ""
      : VpnService.label !== "VPN" ? VpnService.label
      : VpnService.detail
    busy: VpnService.connecting
    active: VpnService.connected
    onClicked: VpnService.toggle()
  }

  Button {
    property bool available: true
    shape: "tile"
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredHeight: tileContentHeight
    icon: "palette"
    label: "MONO"
    active: Theme.monochrome
    onClicked: Theme.setMonochrome(!Theme.monochrome)
  }

  Button {
    property bool available: true
    shape: "tile"
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredHeight: tileContentHeight
    icon: "zap"
    label: "POWER"
    active: PerformanceService.profile === 0
    onClicked: PerformanceService.switchProfile(PerformanceService.profile === 0 ? 1 : 0)
  }

  Button {
    property bool available: true
    shape: "tile"
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredHeight: tileContentHeight
    icon: AudioService.muted ? "volume-mute" : "volume"
    label: "SOUND"
    active: !AudioService.muted
    onClicked: AudioService.toggleMute()
  }

  Button {
    property bool available: true
    shape: "tile"
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredHeight: tileContentHeight
    icon: LockService.autoLock ? "lock" : "lock-open"
    label: "AUTO LOCK"
    active: LockService.autoLock
    onClicked: LockService.toggleAutoLock()
  }

  Button {
    id: moreTile
    shape: "tile"
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredHeight: tileContentHeight
    visible: false
    icon: root.expanded ? "chevron.up" : "chevron.down"
    label: root.expanded ? "LESS" : "MORE"
    onClicked: root.expanded = !root.expanded
  }
}
