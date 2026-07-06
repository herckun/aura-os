import QtQuick
import QtQuick.Layouts
import "../../styles"
import "../../services"
import "../../components"

GridLayout {
  id: root

  readonly property int _visibleCount: {
    var c = 0
    for (var i = 0; i < children.length; i++) if (children[i].visible) c++
    return c
  }

  width: parent ? parent.width : implicitWidth
  columns: Math.max(1, Math.min(3, _visibleCount))
  columnSpacing: Theme.spaceSm
  rowSpacing: Theme.spaceSm

  Button {
    shape: "tile"
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredHeight: tileContentHeight
    icon: "wifi"
    label: "WIFI"
    actionId: "wifi-toggle"
    visible: NetworkService.hasWifi
    active: NetworkService.wifiEnabled
    onClicked: NetworkService.toggleWifi()
  }

  Button {
    shape: "tile"
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredHeight: tileContentHeight
    icon: "bluetooth"
    label: "BT"
    actionId: "bt-toggle"
    visible: BluetoothService.hasBluetooth
    active: BluetoothService.enabled && BluetoothService.devices.length > 0
    onClicked: BluetoothService.toggle()
  }

  Button {
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
    visible: VpnService.available
    active: VpnService.connected
    onClicked: VpnService.toggle()
  }

  Button {
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
    shape: "tile"
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredHeight: tileContentHeight
    icon: "zap"
    label: "POWER"
    active: PerformanceService.profile === 0
    onClicked: PerformanceService.switchProfile(PerformanceService.profile === 0 ? 1 : 0)
  }
}
