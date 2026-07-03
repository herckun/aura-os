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
  }

  Component.onCompleted: {
    if (NetworkService.hasWifi && NetworkService.wifiEnabled) NetworkService.scan()
  }

  Column {
    id: content
    width: parent.width
    spacing: Theme.spaceLg

    PageHeader { title: "CONNECTIVITY" }

    RowLayout {
      width: parent.width
      spacing: Theme.spaceSm

      Rectangle {
        width: 8; height: 8; radius: 4
        color: NetworkService.online ? Theme.success : Theme.textDisabled
        Layout.alignment: Qt.AlignVCenter
      }

      Text {
        text: NetworkService.online
          ? (NetworkService.primarySsid !== "" ? "ONLINE · " + NetworkService.primarySsid : "ONLINE")
          : "OFFLINE"
        color: NetworkService.online ? Theme.success : Theme.textDisabled
        font.pixelSize: Theme.fontSizeCaption
        font.family: Theme.fontFamilyMono
        font.letterSpacing: 0.08
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
      }
    }

    // ── Wired ───────────────────────────────────────────────────────────
    Card {
      width: parent.width
      title: "WIRED"
      description: {
        if (NetworkService.ethernetConnected) {
          return "Connected" + (NetworkService.ethernetDevice ? " (" + NetworkService.ethernetDevice + ")" : "")
        }
        if (NetworkService.lastWiredName !== "" && NetworkService.lastConnectionType === "wired") {
          return "Last: " + NetworkService.lastWiredName
        }
        return NetworkService.hasEthernet ? "Not connected" : "No wired devices"
      }

      Column {
        width: parent.width
        spacing: Theme.spaceSm

        RowLayout {
          width: parent.width
          ButtonGroup {
            Button { shape: "circle";
              icon: "refresh"
              size: 24
              iconSize: 10
              onClicked: NetworkService.poll()
            }
          }

          Item { Layout.fillWidth: true }

          Button {
            text: "RECONNECT"
            size: "sm"
            visible: NetworkService.hasEthernet
              && NetworkService.lastWiredName !== ""
              && !NetworkService.ethernetConnected
              && NetworkService.lastConnectionType === "wired"
            onClicked: NetworkService.autoConnectLastWired()
            Layout.alignment: Qt.AlignVCenter
          }
        }

        Column {
          width: parent.width
          spacing: Theme.space2
          visible: NetworkService.wiredConnections.length > 0

          Divider {}

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
    Card {
      width: parent.width
      title: "WI-FI"
      description: {
        if (NetworkService.connecting) {
          return "Connecting to " + NetworkService.pendingConnectSsid + "..."
        }
        if (NetworkService.primarySsid !== "") {
          return "Connected to " + NetworkService.primarySsid + " · " + NetworkService.signalStrength + "%"
        }
        if (NetworkService.lastSsid !== "" && NetworkService.wifiEnabled && NetworkService.lastConnectionType === "wifi") {
          return "Last: " + NetworkService.lastSsid
        }
        return "Not connected"
      }
      visible: NetworkService.hasWifi

      Column {
        width: parent.width
        spacing: Theme.spaceSm

        SettingRow {
          label: "ENABLED"
          Toggle {
            toggleWidth: 38
            toggleHeight: 20
            checked: NetworkService.wifiEnabled
            onToggled: (v) => NetworkService.toggleWifi()
          }
        }

        RowLayout {
          width: parent.width
          spacing: Theme.spaceSm

          ButtonGroup {
            Button { shape: "circle";
              icon: "refresh"
              size: 24
              iconSize: 10
              enabled: NetworkService.wifiEnabled && !NetworkService.scanning
              busy: NetworkService.scanning
              onClicked: NetworkService.scan()
            }

            Button { shape: "circle";
              icon: "wifi-off"
              size: 24
              iconSize: 10
              visible: NetworkService.primarySsid !== ""
              onClicked: NetworkService.disconnectNetwork()
            }
          }

          Item { Layout.fillWidth: true }

          Text {
            visible: NetworkService.primarySsid !== ""
            text: NetworkService.signalStrength + "%"
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSizeCaption
            font.family: Theme.fontFamilyMono
            Layout.alignment: Qt.AlignVCenter
          }

          Button {
            text: "RECONNECT"
            size: "sm"
            visible: NetworkService.wifiEnabled
              && NetworkService.lastSsid !== ""
              && NetworkService.primarySsid === ""
              && !NetworkService.connecting
            onClicked: NetworkService.autoConnectLast()
            Layout.alignment: Qt.AlignVCenter
          }

          Button {
            text: "FORGET"
            shape: "link"
            size: "sm"
            visible: NetworkService.wifiEnabled
              && NetworkService.lastSsid !== ""
              && NetworkService.primarySsid === ""
              && !NetworkService.connecting
            onClicked: NetworkService.forgetNetwork(NetworkService.lastSsid)
            Layout.alignment: Qt.AlignVCenter
          }
        }

        Column {
          width: parent.width
          spacing: Theme.space2
          visible: NetworkService.availableNetworks.length > 0

          Divider {}

          Repeater {
            model: NetworkService.availableNetworks

            DeviceRow {
              width: parent.width
              icon: "wifi"
              name: modelData.ssid
              subtitle: (modelData.security !== "" ? modelData.security + " · " : "") + modelData.signal + "%"
              active: modelData.ssid === NetworkService.primarySsid
              busy: modelData.ssid === NetworkService.pendingConnectSsid && NetworkService.connecting
              showAction: modelData.ssid !== NetworkService.primarySsid
                && !(modelData.ssid === NetworkService.pendingConnectSsid && NetworkService.connecting)
              actionLabel: "CONNECT"
              onActionClicked: {
                if (modelData.security === "") {
                  NetworkService.connectNetwork(modelData.ssid, "")
                } else {
                  root._openPassword(modelData.ssid)
                }
              }
            }
          }
        }

        EmptyState {
          visible: NetworkService.availableNetworks.length === 0
          stateText: NetworkService.wifiEnabled
            ? (NetworkService.scanning ? "SCANNING..." : "NO NETWORKS FOUND")
            : "WI-FI IS DISABLED"
        }

        ErrorText { errorText: NetworkService.lastError }
      }
    }

    // ── Bluetooth ─────────────────────────────────────────────────────
    Card {
      width: parent.width
      title: "BLUETOOTH"
      description: BluetoothService.enabled ? BluetoothService.pairedDevices.length + " paired device(s)" : "Disabled"
      visible: BluetoothService.hasBluetooth

      Column {
        width: parent.width
        spacing: Theme.spaceSm

        SettingRow {
          label: "ENABLED"
          Toggle {
            toggleWidth: 38
            toggleHeight: 20
            checked: BluetoothService.enabled
            onToggled: BluetoothService.toggle()
          }
        }

        RowLayout {
          width: parent.width
          spacing: Theme.spaceSm
          visible: BluetoothService.enabled

          ButtonGroup {
            Button { shape: "circle";
              icon: "refresh"
              size: 24
              iconSize: 10
              enabled: !BluetoothService.scanning
              busy: BluetoothService.scanning
              onClicked: BluetoothService.scan()
            }
          }

          Item { Layout.fillWidth: true }

          Text {
            text: BluetoothService.devices.length + " FOUND"
            color: Theme.textDisabled
            font.pixelSize: Theme.fontSizeCaption
            font.family: Theme.fontFamilyMono
            Layout.alignment: Qt.AlignVCenter
          }
        }

        Column {
          width: parent.width
          spacing: Theme.space2
          visible: BluetoothService.pairedDevices.length > 0

          Divider {}

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

          Divider {}

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
          stateText: BluetoothService.enabled
            ? (BluetoothService.scanning ? "SCANNING..." : "NO DEVICES FOUND")
            : "BLUETOOTH IS DISABLED"
        }

        ErrorText { errorText: BluetoothService.lastError }
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
    description: "Enter password for " + root._pendingSsid
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
      NetworkService.connectNetwork(root._pendingSsid, pwdInput.text)
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

  function _openPassword(ssid: string): void {
    root._pendingSsid = ssid
    passwordModal.openDialog()
  }
}
