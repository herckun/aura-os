import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../styles"
import "../../services"
import "../../components"
import "../../core"

Item {
  id: root

  property var extraToggles: []

  readonly property var _builtin: [
    { icon: "wifi", label: "WIFI", actionId: "wifi-toggle", toggle: function() { NetworkService.toggleWifi() }, visible: NetworkService.hasWifi },
    { icon: "bluetooth", label: "BT", actionId: "bt-toggle", toggle: function() { BluetoothService.toggle() }, visible: BluetoothService.hasBluetooth },
    { icon: "palette", label: "MONO", toggle: function() { Theme.setMonochrome(!Theme.monochrome) } },
    { icon: "zap", label: "POWER", toggle: function() { PerformanceService.switchProfile(PerformanceService.profile === 0 ? 1 : 0) } }
  ]

  readonly property var _extra: _builtin.concat(extraToggles)
  readonly property int _visibleCount: {
    var c = 0
    var items = host.items
    for (var i = 0; i < items.length; i++) if (items[i].visible !== false) c++
    return c
  }

  width: parent ? parent.width : implicitWidth
  implicitHeight: host.implicitHeight

  PluginHost {
    id: host
    width: parent.width
    location: "controlcenter_toggle"
    mode: "data"
    layout: "grid"
    columns: Math.max(1, Math.min(3, root._visibleCount))
    extraItems: root._extra

    delegate: Button {
      required property var modelData
      shape: "tile"
      Layout.fillWidth: true
      Layout.preferredHeight: 60
      icon: modelData.icon
      label: modelData.label
      visible: modelData.visible !== false
      actionId: modelData.actionId || ""
      active: modelData.plugin ? (modelData.plugin.isActiveToggle !== undefined
                              ? modelData.plugin.isActiveToggle
                              : !!modelData.plugin[modelData.activeKey]) :
              modelData.label === "WIFI" ? NetworkService.wifiEnabled :
              modelData.label === "BT" ? (BluetoothService.enabled && BluetoothService.devices.length > 0) :
              modelData.label === "MONO" ? Theme.monochrome :
              modelData.label === "EE" ? AudioService.effectsActive :
              modelData.label === "POWER" ? PerformanceService.profile === 0 :
              modelData.active !== undefined ? modelData.active : false
      onClicked: modelData.toggle()
    }
  }
}
