import QtQuick
import QtQuick.Layouts
import "../../styles"
import "../../services"
import "../../components"

Column {
  id: root

  readonly property int maxShown: 6
  readonly property int maxColumns: 3
  property bool expanded: false

  readonly property var toggleModel: [
    {
      label: "WIFI",
      actionId: "wifi-toggle",
      settingsPage: "connectivity",
      icon: function () { return "wifi" },
      available: function () { return NetworkService.hasWifi },
      isActive: function () { return NetworkService.wifiEnabled },
      toggle: function () { NetworkService.toggleWifi() }
    },
    {
      label: "BT",
      actionId: "bt-toggle",
      settingsPage: "connectivity",
      icon: function () { return "bluetooth" },
      available: function () { return BluetoothService.hasBluetooth },
      isActive: function () { return BluetoothService.enabled && BluetoothService.devices.length > 0 },
      toggle: function () { BluetoothService.toggle() }
    },
    {
      label: "SOUND",
      settingsPage: "audio",
      icon: function () { return AudioService.muted ? "volume-mute" : "volume" },
      isActive: function () { return !AudioService.muted },
      toggle: function () { AudioService.toggleMute() }
    },
    {
      label: "VPN",
      settingsPage: "connectivity",
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
      label: "POWER",
      settingsPage: "power",
      icon: function () { return "zap" },
      isActive: function () { return PerformanceService.profile === 0 },
      toggle: function () { PerformanceService.switchProfile(PerformanceService.profile === 0 ? 1 : 0) }
    },
    {
      label: "AUTO LOCK",
      icon: function () { return LockService.autoLock ? "lock" : "lock-open" },
      isActive: function () { return LockService.autoLock },
      toggle: function () { LockService.toggleAutoLock() }
    },
    {
      label: "MONO",
      settingsPage: "appearance",
      icon: function () { return "palette" },
      isActive: function () { return Theme.monochrome },
      toggle: function () { Theme.setMonochrome(!Theme.monochrome) }
    }
  ]

  readonly property var _availableToggles: toggleModel.filter(function (t) {
    return t.available ? t.available() : true
  })
  readonly property bool _overflow: _availableToggles.length > maxShown

  readonly property var _rows: {
    var tiles = _availableToggles
      .slice(0, _overflow && !expanded ? maxShown - 1 : _availableToggles.length)
      .map(function (t) { return { kind: "toggle", toggle: t } })
    if (_overflow)
      tiles.push({ kind: "more" })
    var n = tiles.length
    if (n === 0)
      return []
    var rowCount = Math.ceil(n / maxColumns)
    var base = Math.floor(n / rowCount)
    var extra = n % rowCount
    var rows = []
    var idx = 0
    for (var r = 0; r < rowCount; r++) {
      var size = base + (r < extra ? 1 : 0)
      rows.push(tiles.slice(idx, idx + size))
      idx += size
    }
    return rows
  }

  spacing: Theme.spaceSm

  Repeater {
    model: root._rows

    delegate: RowLayout {
      id: rowItem
      required property var modelData
      width: root.width
      spacing: Theme.spaceSm

      Repeater {
        model: rowItem.modelData

        delegate: Button {
          id: tile
          required property var modelData
          readonly property var t: modelData.toggle || null
          readonly property bool isMore: modelData.kind === "more"
          shape: "tile"
          Layout.fillWidth: true
          Layout.fillHeight: true
          Layout.preferredHeight: tileContentHeight
          icon: isMore ? (root.expanded ? "chevron.up" : "chevron.down") : t.icon()
          label: isMore ? (root.expanded ? "LESS" : "MORE") : t.label
          sublabel: !isMore && t.sublabel ? t.sublabel() : ""
          busy: !isMore && t.busy ? t.busy() : false
          actionId: !isMore && t.actionId ? t.actionId : ""
          active: !isMore && t.isActive()
          onClicked: isMore ? root.expanded = !root.expanded : t.toggle()
          onRightClicked: {
            if (!isMore && t.settingsPage) {
              ControlCenterService.visible = false
              IpcService.navigatePanel("settings", t.settingsPage)
            }
          }
        }
      }
    }
  }
}
