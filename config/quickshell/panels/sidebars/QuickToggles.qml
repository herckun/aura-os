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

  readonly property var toggleModel: [
    {
      label: "WIFI",
      actionId: "wifi-toggle",
      icon: function () { return "wifi" },
      available: function () { return NetworkService.hasWifi },
      isActive: function () { return NetworkService.wifiEnabled },
      toggle: function () { NetworkService.toggleWifi() }
    },
    {
      label: "BT",
      actionId: "bt-toggle",
      icon: function () { return "bluetooth" },
      available: function () { return BluetoothService.hasBluetooth },
      isActive: function () { return BluetoothService.enabled && BluetoothService.devices.length > 0 },
      toggle: function () { BluetoothService.toggle() }
    },
    {
      label: "VPN",
      icon: function () { return VpnService.activeProvider ? VpnService.activeProvider.icon : "shield" },
      sublabel: function () {
        return !VpnService.connected ? ""
          : VpnService.label !== "VPN" ? VpnService.label
          : VpnService.detail
      },
      busy: function () { return VpnService.connecting },
      available: function () { return VpnService.available },
      isActive: function () { return VpnService.connected },
      toggle: function () { VpnService.toggle() }
    },
    {
      label: "MONO",
      icon: function () { return "palette" },
      isActive: function () { return Theme.monochrome },
      toggle: function () { Theme.setMonochrome(!Theme.monochrome) }
    },
    {
      label: "POWER",
      icon: function () { return "zap" },
      isActive: function () { return PerformanceService.profile === 0 },
      toggle: function () { PerformanceService.switchProfile(PerformanceService.profile === 0 ? 1 : 0) }
    },
    {
      label: "SOUND",
      icon: function () { return AudioService.muted ? "volume-mute" : "volume" },
      isActive: function () { return !AudioService.muted },
      toggle: function () { AudioService.toggleMute() }
    },
    {
      label: "AUTO LOCK",
      icon: function () { return LockService.autoLock ? "lock" : "lock-open" },
      isActive: function () { return LockService.autoLock },
      toggle: function () { LockService.toggleAutoLock() }
    }
  ]

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

  Repeater {
    model: root.toggleModel

    delegate: Button {
      required property var modelData
      property bool available: modelData.available ? modelData.available() : true
      onAvailableChanged: root.relayout()
      shape: "tile"
      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.preferredHeight: tileContentHeight
      icon: modelData.icon()
      label: modelData.label
      sublabel: modelData.sublabel ? modelData.sublabel() : ""
      busy: modelData.busy ? modelData.busy() : false
      actionId: modelData.actionId || ""
      active: modelData.isActive()
      onClicked: modelData.toggle()
    }
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
