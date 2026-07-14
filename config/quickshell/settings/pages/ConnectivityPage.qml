import QtQuick
import QtQuick.Layouts
import "../../styles"
import "../../services"
import "../../components"
import "../../core"

Item {
  id: root
  width: parent.width
  implicitHeight: content.implicitHeight
  height: content.implicitHeight

  property string _pendingSsid: ""
  property bool _savedFailed: false

  readonly property var _vpnPluginProviders: VpnService.providers.filter(function(p) { return !p.builtin })

  readonly property var _wifiNetworks: {
    var nets = NetworkService.availableNetworks.slice()
    var saved = NetworkService.savedWifiNetworks
    var current = NetworkService.primarySsid
    nets.sort(function(a, b) {
      var aActive = a.ssid === current ? 1 : 0
      var bActive = b.ssid === current ? 1 : 0
      if (aActive !== bActive) return bActive - aActive
      var aKnown = saved.indexOf(a.ssid) !== -1 ? 1 : 0
      var bKnown = saved.indexOf(b.ssid) !== -1 ? 1 : 0
      if (aKnown !== bKnown) return bKnown - aKnown
      return b.signal - a.signal
    })
    return nets
  }

  readonly property var _savedOutOfRange: {
    var inRange = {}
    var nets = NetworkService.availableNetworks
    for (var i = 0; i < nets.length; i++) inRange[nets[i].ssid] = true
    var out = []
    var saved = NetworkService.savedWifiNetworks
    for (var j = 0; j < saved.length; j++) {
      if (!inRange[saved[j]]) out.push(saved[j])
    }
    return out
  }

  Connections {
    target: NetworkService
    function onNetworkConnected(ssid) {
      if (passwordModal.open) {
        passwordModal.close()
        pwdInput.input.text = ""
      }
    }
    function onNetworkFailed(msg) {
      if (passwordModal.open) {
        passwordError.text = msg
      }
    }
    function onPasswordRequired(ssid, savedFailed) {
      root._openPassword(ssid, savedFailed)
    }
  }

  Component.onCompleted: {
    if (NetworkService.hasWifi && NetworkService.wifiEnabled) NetworkService.scan()
  }

  Column {
    id: content
    width: parent.width
    spacing: Theme.spaceLg

    PageHeader { title: "CONNECTIVITY"; description: "Wi-Fi, Bluetooth and VPN" }

    RowLayout {
      width: parent.width
      spacing: Theme.spaceSm

      Rectangle {
        width: 8; height: 8; radius: 4
        color: NetworkService.online ? Theme.success : Theme.textDisabled
        Layout.alignment: Qt.AlignVCenter
      }

      Text {
        text: {
          if (!NetworkService.online) return "OFFLINE"
          var parts = []
          if (NetworkService.ethernetConnected) {
            parts.push("WIRED" + (NetworkService.ethernetDevice ? " (" + NetworkService.ethernetDevice + ")" : ""))
          }
          if (NetworkService.primarySsid !== "") {
            parts.push(NetworkService.primarySsid + " " + NetworkService.signalStrength + "%")
          }
          return parts.length > 0 ? "ONLINE · " + parts.join(" · ") : "ONLINE"
        }
        color: NetworkService.online ? Theme.success : Theme.textDisabled
        font.pixelSize: Theme.fontSizeCaption
        font.family: Theme.fontFamilyMono
        font.letterSpacing: 0.08
        elide: Text.ElideRight
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
      }

      Button {
        shape: "circle"
        icon: "refresh"
        size: 24
        iconSize: 10
        onClicked: NetworkService.poll()
        Layout.alignment: Qt.AlignVCenter
      }
    }

    // ── Wired ───────────────────────────────────────────────────────────
    Surface {
      width: parent.width
      height: wiredCol.implicitHeight + Theme.spaceLg * 2
      radius: Theme.radiusMedium
      antialiasing: true
      border.color: Theme.border
      padding: Theme.spaceLg
      visible: NetworkService.hasEthernet || NetworkService.wiredConnections.length > 0

      Column {
        id: wiredCol
        width: parent.width
        spacing: Theme.spaceMd

        RowLayout {
          width: parent.width
          spacing: Theme.spaceSm

          Surface {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            level: 2
            bordered: false
            radius: Theme.radiusMedium
            antialiasing: true

            Icon {
              anchors.centerIn: parent
              source: Icons.get("globe")
              size: 16
              color: NetworkService.ethernetConnected ? Theme.accent : Theme.textDisabled
            }
          }

          Column {
            Layout.fillWidth: true
            spacing: Theme.spaceXxs

            Text {
              width: parent.width
              text: "WIRED"
              color: Theme.textPrimary
              font.pixelSize: Theme.fontSizeLabel
              font.family: Theme.fontFamilyMono
              font.weight: Font.Bold
              font.letterSpacing: 0.08
            }

            Text {
              width: parent.width
              text: {
                if (NetworkService.ethernetConnected) {
                  return "Connected" + (NetworkService.ethernetDevice ? " (" + NetworkService.ethernetDevice + ")" : "")
                }
                if (NetworkService.lastWiredName !== "" && NetworkService.lastConnectionType === "wired") {
                  return "Last: " + NetworkService.lastWiredName
                }
                return "Not connected"
              }
              color: Theme.textDisabled
              font.pixelSize: Theme.fontSizeMicro
              font.family: Theme.fontFamilyMono
              elide: Text.ElideRight
            }
          }

          Button {
            text: "RECONNECT"
            size: "sm"
            visible: NetworkService.hasEthernet
              && NetworkService.lastWiredName !== ""
              && !NetworkService.ethernetConnected
              && NetworkService.lastConnectionType === "wired"
            onClicked: NetworkService.autoConnectLastWired()
          }
        }

        Column {
          width: parent.width
          spacing: Theme.space2
          visible: NetworkService.wiredConnections.length > 0

          SectionLabel { label: "PROFILES" }

          Repeater {
            model: NetworkService.wiredConnections

            DeviceRow {
              width: parent.width
              icon: "globe"
              name: modelData.name
              subtitle: modelData.device
              active: modelData.active
              showToggle: true
              toggleChecked: modelData.active
              onToggled: function(v) {
                var connName = modelData.name
                var device = modelData.device
                var conns = NetworkService.wiredConnections.slice()
                for (var i = 0; i < conns.length; i++) {
                  if (conns[i].name === connName) {
                    conns[i] = Object.assign({}, conns[i], { active: v })
                  }
                }
                NetworkService.wiredConnections = conns
                if (v) {
                  NetworkService.activateConnection(connName)
                } else {
                  NetworkService.deactivateDevice(device)
                }
              }
            }
          }
        }

        EmptyState {
          visible: NetworkService.wiredConnections.length === 0
          stateText: "NO WIRED PROFILES"
        }

        ErrorText { errorText: NetworkService.lastError }
      }
    }

    // ── Wi-Fi ─────────────────────────────────────────────────────────
    Surface {
      width: parent.width
      height: wifiCol.implicitHeight + Theme.spaceLg * 2
      radius: Theme.radiusMedium
      antialiasing: true
      border.color: Theme.border
      padding: Theme.spaceLg
      visible: NetworkService.hasWifi

      Column {
        id: wifiCol
        width: parent.width
        spacing: Theme.spaceMd

        RowLayout {
          width: parent.width
          spacing: Theme.spaceSm

          Surface {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            level: 2
            bordered: false
            radius: Theme.radiusMedium
            antialiasing: true

            Icon {
              anchors.centerIn: parent
              source: Icons.get(NetworkService.wifiEnabled ? "wifi" : "wifi-off")
              size: 16
              color: !NetworkService.wifiEnabled ? Theme.textDisabled
                : NetworkService.primarySsid !== "" ? Theme.accent
                : Theme.textSecondary
            }
          }

          Column {
            Layout.fillWidth: true
            spacing: Theme.spaceXxs

            Text {
              width: parent.width
              text: "WI-FI"
              color: Theme.textPrimary
              font.pixelSize: Theme.fontSizeLabel
              font.family: Theme.fontFamilyMono
              font.weight: Font.Bold
              font.letterSpacing: 0.08
            }

            Text {
              width: parent.width
              text: {
                if (!NetworkService.wifiEnabled) return "Disabled"
                if (NetworkService.connecting) {
                  return "Connecting to " + NetworkService.pendingConnectSsid + "..."
                }
                if (NetworkService.primarySsid !== "") {
                  return "Connected to " + NetworkService.primarySsid + " · " + NetworkService.signalStrength + "%"
                }
                if (NetworkService.scanning) return "Scanning..."
                if (NetworkService.availableNetworks.length > 0) {
                  return NetworkService.availableNetworks.length + " network(s) in range"
                }
                return "Not connected"
              }
              color: Theme.textDisabled
              font.pixelSize: Theme.fontSizeMicro
              font.family: Theme.fontFamilyMono
              elide: Text.ElideRight
            }
          }

          Button {
            text: "SCAN"
            size: "sm"
            icon: "refresh"
            visible: NetworkService.wifiEnabled
            enabled: !NetworkService.scanning
            busy: NetworkService.scanning
            onClicked: NetworkService.scan()
          }

          Toggle {
            toggleWidth: 38
            toggleHeight: 20
            checked: NetworkService.wifiEnabled
            onToggled: (v) => NetworkService.toggleWifi()
            Layout.alignment: Qt.AlignVCenter
          }
        }

        Column {
          width: parent.width
          spacing: Theme.space2
          visible: NetworkService.wifiEnabled && root._wifiNetworks.length > 0

          SectionLabel { label: "IN RANGE (" + root._wifiNetworks.length + ")" }

          Repeater {
            model: root._wifiNetworks

            DeviceRow {
              readonly property bool isActive: modelData.ssid === NetworkService.primarySsid
              readonly property bool isKnown: NetworkService.savedWifiNetworks.indexOf(modelData.ssid) !== -1

              width: parent.width
              icon: modelData.secured ? "lock" : "wifi"
              name: modelData.ssid
              subtitle: modelData.security !== "" ? modelData.security : "OPEN"
              active: isActive
              meter: modelData.signal
              tagLabel: isKnown && !isActive ? "SAVED" : ""
              busy: modelData.ssid === NetworkService.pendingConnectSsid && NetworkService.connecting
              showAction: !NetworkService.connecting
              actionLabel: isActive ? "DISCONNECT" : "CONNECT"
              showSecondaryAction: isKnown && !NetworkService.connecting
              secondaryActionLabel: "FORGET"
              onActionClicked: {
                if (isActive) {
                  NetworkService.disconnectNetwork()
                } else {
                  NetworkService.connectNetwork(modelData.ssid, modelData.secured)
                }
              }
              onSecondaryActionClicked: NetworkService.forgetNetwork(modelData.ssid)
            }
          }
        }

        Column {
          width: parent.width
          spacing: Theme.space2
          visible: NetworkService.wifiEnabled && root._savedOutOfRange.length > 0

          SectionLabel { label: "SAVED · OUT OF RANGE" }

          Repeater {
            model: root._savedOutOfRange

            DeviceRow {
              width: parent.width
              icon: "wifi-off"
              name: modelData
              showSecondaryAction: !NetworkService.connecting
              secondaryActionLabel: "FORGET"
              onSecondaryActionClicked: NetworkService.forgetNetwork(modelData)
            }
          }
        }

        EmptyState {
          visible: NetworkService.availableNetworks.length === 0
          icon: NetworkService.wifiEnabled ? "wifi" : "wifi-off"
          stateText: NetworkService.wifiEnabled
            ? (NetworkService.scanning ? "SCANNING..." : "NO NETWORKS FOUND")
            : "WI-FI IS DISABLED"
        }

        ErrorText { errorText: NetworkService.lastError }
      }
    }

    // ── Bluetooth ─────────────────────────────────────────────────────
    Surface {
      width: parent.width
      height: btCol.implicitHeight + Theme.spaceLg * 2
      radius: Theme.radiusMedium
      antialiasing: true
      border.color: Theme.border
      padding: Theme.spaceLg
      visible: BluetoothService.hasBluetooth

      Column {
        id: btCol
        width: parent.width
        spacing: Theme.spaceMd

        RowLayout {
          width: parent.width
          spacing: Theme.spaceSm

          Surface {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            level: 2
            bordered: false
            radius: Theme.radiusMedium
            antialiasing: true

            Icon {
              anchors.centerIn: parent
              source: Icons.get("bluetooth")
              size: 16
              color: BluetoothService.enabled ? Theme.accent : Theme.textDisabled
            }
          }

          Column {
            Layout.fillWidth: true
            spacing: Theme.spaceXxs

            Text {
              width: parent.width
              text: "BLUETOOTH"
              color: Theme.textPrimary
              font.pixelSize: Theme.fontSizeLabel
              font.family: Theme.fontFamilyMono
              font.weight: Font.Bold
              font.letterSpacing: 0.08
            }

            Text {
              width: parent.width
              text: BluetoothService.enabled
                ? BluetoothService.pairedDevices.length + " paired device(s)"
                : "Disabled"
              color: Theme.textDisabled
              font.pixelSize: Theme.fontSizeMicro
              font.family: Theme.fontFamilyMono
              elide: Text.ElideRight
            }
          }

          Button {
            text: "SCAN"
            size: "sm"
            icon: "refresh"
            visible: BluetoothService.enabled
            enabled: !BluetoothService.scanning
            busy: BluetoothService.scanning
            onClicked: BluetoothService.scan()
          }

          Toggle {
            toggleWidth: 38
            toggleHeight: 20
            checked: BluetoothService.enabled
            onToggled: BluetoothService.toggle()
            Layout.alignment: Qt.AlignVCenter
          }
        }

        Column {
          width: parent.width
          spacing: Theme.space2
          visible: BluetoothService.pairedDevices.length > 0

          SectionLabel { label: "PAIRED" }

          Repeater {
            model: BluetoothService.pairedDevices

            DeviceRow {
              width: parent.width
              icon: "bluetooth"
              name: modelData.name
              active: modelData.connected
              showAction: true
              actionLabel: modelData.connected ? "DISCONNECT" : "CONNECT"
              onActionClicked: {
                if (modelData.connected) {
                  BluetoothService.disconnectDevice(modelData.mac)
                } else {
                  BluetoothService.connectDevice(modelData.mac)
                }
              }
            }
          }
        }

        Column {
          width: parent.width
          spacing: Theme.space2
          visible: BluetoothService.enabled && BluetoothService.devices.length > 0

          SectionLabel { label: "DISCOVERED (" + BluetoothService.devices.length + ")" }

          Repeater {
            model: BluetoothService.devices

            DeviceRow {
              width: parent.width
              icon: "bluetooth"
              name: modelData.name
              subtitle: modelData.mac
              showAction: true
              actionLabel: "PAIR"
              onActionClicked: BluetoothService.pair(modelData.mac)
            }
          }
        }

        EmptyState {
          visible: BluetoothService.devices.length === 0 && BluetoothService.pairedDevices.length === 0
          icon: "bluetooth"
          stateText: BluetoothService.enabled
            ? (BluetoothService.scanning ? "SCANNING..." : "NO DEVICES FOUND")
            : "BLUETOOTH IS DISABLED"
        }

        ErrorText { errorText: BluetoothService.lastError }
      }
    }

    // ── VPN ───────────────────────────────────────────────────────────
    Surface {
      width: parent.width
      height: vpnCol.implicitHeight + Theme.spaceLg * 2
      radius: Theme.radiusMedium
      antialiasing: true
      border.color: Theme.border
      padding: Theme.spaceLg

      Column {
        id: vpnCol
        width: parent.width
        spacing: Theme.spaceMd

        RowLayout {
          width: parent.width
          spacing: Theme.spaceSm

          Surface {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            level: 2
            bordered: false
            radius: Theme.radiusMedium
            antialiasing: true

            Icon {
              anchors.centerIn: parent
              source: Icons.get("shield")
              size: 16
              color: VpnService.connected ? Theme.accent : Theme.textDisabled
            }
          }

          Column {
            Layout.fillWidth: true
            spacing: Theme.spaceXxs

            Text {
              width: parent.width
              text: "VPN"
              color: Theme.textPrimary
              font.pixelSize: Theme.fontSizeLabel
              font.family: Theme.fontFamilyMono
              font.weight: Font.Bold
              font.letterSpacing: 0.08
            }

            Text {
              width: parent.width
              text: VpnService.connecting ? "Connecting..."
                : VpnService.connected ? VpnService.label + (VpnService.detail !== "" && VpnService.detail !== VpnService.label ? "  " + VpnService.detail : "")
                : VpnService.available ? "Not connected"
                : "No providers"
              color: VpnService.connected ? Theme.success : Theme.textDisabled
              font.pixelSize: Theme.fontSizeMicro
              font.family: Theme.fontFamilyMono
              elide: Text.ElideRight
            }
          }

          Toggle {
            toggleWidth: 38
            toggleHeight: 20
            checked: VpnService.connected
            enabled: VpnService.available && !VpnService.connecting
            onToggled: VpnService.toggle()
            Layout.alignment: Qt.AlignVCenter
          }
        }

        Column {
          width: parent.width
          spacing: Theme.space2
          visible: NetworkService.vpnConnections.length > 0

          SectionLabel { label: "PROFILES" }

          Repeater {
            model: NetworkService.vpnConnections

            DeviceRow {
              width: parent.width
              icon: "shield"
              name: modelData.name
              subtitle: modelData.type
              active: modelData.active
              busy: VpnService.nmBusyName === modelData.name
              showToggle: true
              toggleChecked: modelData.active
              onToggled: function(v) {
                if (v) VpnService.nmConnect(modelData.name)
                else VpnService.nmDisconnect(modelData.name)
              }
            }
          }
        }

        Column {
          width: parent.width
          spacing: Theme.space2
          visible: root._vpnPluginProviders.length > 0

          SectionLabel { label: "PROVIDERS" }

          Repeater {
            model: root._vpnPluginProviders

            DeviceRow {
              width: parent.width
              icon: modelData.icon
              name: modelData.label
              subtitle: modelData.connected ? (modelData.detail || "Connected") : ""
              active: modelData.connected
              busy: modelData.connecting
              tagLabel: modelData.id === Store.vpn.provider && !modelData.connected ? "LAST USED" : ""
              showAction: true
              actionLabel: modelData.connected ? "DISCONNECT" : "CONNECT"
              onActionClicked: {
                if (modelData.connected) VpnService.disconnectProvider(modelData.id)
                else VpnService.connectProvider(modelData.id)
              }
            }
          }
        }

        EmptyState {
          visible: !VpnService.available
          icon: "shield"
          stateText: "NO VPN PROVIDERS"
        }
      }
    }

    PluginHost {
      location: "connectivity"
    }
  }

  // ── Password Modal ───────────────────────────────────────────────
  Modal {
    id: passwordModal
    title: "WI-FI PASSWORD"
    description: root._savedFailed
      ? "Saved password for " + root._pendingSsid + " was rejected. Enter a new one."
      : "Enter password for " + root._pendingSsid
    iconName: "lock"
    confirmLabel: "CONNECT"
    confirmIcon: "wifi"
    confirmVariant: "accent"
    busy: NetworkService.connecting
    closeOnConfirm: false
    dismissOnBackdrop: false
    content: [
      Input {
        id: pwdInput
        width: parent.width
        placeholder: "PASSWORD"
        iconName: "lock"
        showClearButton: false
        echoMode: TextInput.Password
        revealable: true
        onAccepted: passwordModal.confirm()
      },

      ErrorText {
        width: parent.width
        errorText: passwordError.text
      }
    ]

    onOpened: {
      passwordError.text = ""
      pwdInput.input.text = ""
      focusTimer.restart()
    }

    onConfirmed: {
      passwordError.text = ""
      NetworkService.submitPassword(root._pendingSsid, pwdInput.text)
    }

    onRejected: {
      pwdInput.input.text = ""
    }
  }

  QtObject {
    id: passwordError
    property string text: ""
  }

  Timer {
    id: focusTimer
    interval: 60
    repeat: false
    onTriggered: {
      if (passwordModal.open) pwdInput.input.forceActiveFocus()
    }
  }

  function _openPassword(ssid: string, savedFailed: bool): void {
    root._pendingSsid = ssid
    root._savedFailed = savedFailed
    if (!passwordModal.open) {
      passwordModal.openDialog()
    }
  }
}
