import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../../../styles"
import "../../../../core"
import "../../../../services"
import "../../../../components"

PanelWindow {
  id: netPopup

  implicitWidth: 280
  implicitHeight: contentCol.implicitHeight + Theme.spaceMd * 2

  anchors { top: true; left: true }
  margins.top: PopupPositioner.belowBar()
  margins.left: popupX
  exclusiveZone: 0
  color: "transparent"
  visible: false

  mask: Region { item: bg }

  property Item anchorItem: null
  property real popupX: PopupPositioner.anchorRightX(anchorItem, netPopup.width, netPopup.screen ? netPopup.screen.width : 0)
  property bool switching: false

  function _recalcPopupX() {
    popupX = PopupPositioner.anchorRightX(anchorItem, netPopup.width, netPopup.screen ? netPopup.screen.width : 0)
  }

  onWidthChanged: _recalcPopupX()
  onScreenChanged: _recalcPopupX()

  onVisibleChanged: {
    NetworkService.liveStatsEnabled = visible
    if (visible) _recalcPopupX()
    else switching = false
  }

  onSwitchingChanged: {
    if (switching && NetworkService.hasWifi && NetworkService.wifiEnabled)
      NetworkService.scan()
  }

  function toggle(): void {
    visible = !visible
  }

  function _openSettings(): void {
    netPopup.visible = false
    IpcService.navigatePanel("settings", "connectivity")
  }

  function _fmtRate(v: real): string {
    if (v < 0) return "…"
    if (v >= 1048576) return (v / 1048576).toFixed(1) + " MB/S"
    if (v >= 1024) return Math.round(v / 1024) + " KB/S"
    return Math.round(v) + " B/S"
  }

  Connections {
    target: NetworkService
    function onPasswordRequired(ssid, savedFailed) {
      if (netPopup.visible)
        netPopup._openSettings()
    }
  }

  HyprlandFocusGrab {
    windows: [netPopup]
    active: netPopup.visible
    onCleared: netPopup.visible = false
  }

  Timer {
    id: leaveTimer
    interval: 2000
    onTriggered: netPopup.visible = false
  }

  HoverHandler {
    onHoveredChanged: {
      if (hovered) leaveTimer.stop()
      else if (netPopup.visible && !netPopup.switching) leaveTimer.restart()
    }
  }

  Surface {
    id: bg
    anchors.fill: parent
    radius: Theme.radiusLarge

    Column {
      id: contentCol
      anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: Theme.spaceMd }
      spacing: Theme.spaceSm

      // ── Title row ──────────────────────────────────
      Item {
        width: parent.width
        height: settingsBtn.height

        Text {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: "NETWORK"
          color: Theme.textDisabled
          font.pixelSize: Theme.fontSizeMicro
          font.family: Theme.fontFamilyMono
          font.letterSpacing: 0.08
        }

        Button {
          id: settingsBtn
          anchors.right: parent.right
          shape: "icon"
          icon: "gear"
          size: "xs"
          showBackground: false
          onClicked: netPopup._openSettings()
        }
      }

      // ── Current connection ─────────────────────────
      CollapsibleHeader {
        width: parent.width
        expanded: netPopup.switching
        onToggled: netPopup.switching = !netPopup.switching

        Icon {
          Layout.alignment: Qt.AlignVCenter
          source: Icons.get(NetworkService.online
            ? (NetworkService.ethernetConnected ? "globe" : "wifi-high") : "wifi-off")
          size: 16
          color: NetworkService.online ? Theme.textPrimary : Theme.textDisabled
        }

        Column {
          Layout.fillWidth: true
          spacing: Theme.space2

          Text {
            width: parent.width
            text: NetworkService.online
              ? (NetworkService.ethernetConnected
                  ? (NetworkService.ethernetConnection || "WIRED").toUpperCase()
                  : (NetworkService.primarySsid || "WI-FI").toUpperCase())
              : "OFFLINE"
            color: NetworkService.online ? Theme.textPrimary : Theme.textDisabled
            font.pixelSize: Theme.fontSizeCaption
            font.family: Theme.fontFamilyMono
            font.weight: Font.DemiBold
            font.letterSpacing: 0.04
            elide: Text.ElideRight
          }

          Text {
            width: parent.width
            text: NetworkService.online
              ? (NetworkService.ethernetConnected
                  ? "ETHERNET  ·  CONNECTED"
                  : "WIRELESS  ·  " + NetworkService.signalStrength + "% SIGNAL")
              : "NO ACTIVE CONNECTION"
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSizeMicro
            font.family: Theme.fontFamilyMono
            font.letterSpacing: 0.06
            elide: Text.ElideRight
          }
        }

        Rectangle {
          Layout.alignment: Qt.AlignVCenter
          width: 7
          height: 7
          radius: 3.5
          color: NetworkService.online ? Theme.success : Theme.textDisabled
        }
      }

      // ── Signal bar (wifi) ──────────────────────────
      ProgressBar {
        width: parent.width
        value: NetworkService.signalStrength / 100
        barHeight: 3
        visible: NetworkService.online && !NetworkService.ethernetConnected
      }

      // ── Network switcher ───────────────────────────
      Collapsible {
        expanded: netPopup.switching
        animated: false

        Column {
          width: parent.width
          spacing: Theme.spaceXs
          bottomPadding: Theme.spaceXs

          Text {
            text: "WIRED"
            visible: NetworkService.wiredConnections.length > 0
            color: Theme.textDisabled
            font.pixelSize: Theme.fontSizeMicro
            font.family: Theme.fontFamilyMono
            font.letterSpacing: 0.08
          }

          Repeater {
            model: NetworkService.wiredConnections

            delegate: NetRow {
              required property var modelData
              name: (modelData.name || "").toUpperCase()
              detail: modelData.active ? "ACTIVE" : (modelData.device || "")
              activeRow: modelData.active === true
              onRowClicked: {
                if (!modelData.active)
                  NetworkService.activateConnection(modelData.name)
              }
            }
          }

          RowLayout {
            width: parent.width
            visible: NetworkService.hasWifi

            Text {
              Layout.fillWidth: true
              text: NetworkService.wifiEnabled ? "WI-FI" : "WI-FI  ·  RADIO OFF"
              color: Theme.textDisabled
              font.pixelSize: Theme.fontSizeMicro
              font.family: Theme.fontFamilyMono
              font.letterSpacing: 0.08
            }

            Spinner {
              spinnerSize: 12
              visible: NetworkService.scanning
            }

            Button {
              shape: "icon"
              icon: "refresh"
              size: "xs"
              showBackground: false
              tooltip: "RESCAN"
              visible: NetworkService.wifiEnabled && !NetworkService.scanning
              onClicked: NetworkService.scan()
            }
          }

          Repeater {
            model: NetworkService.hasWifi && NetworkService.wifiEnabled
              ? NetworkService.availableNetworks.slice(0, 8) : []

            delegate: NetRow {
              required property var modelData
              name: modelData.ssid
              detail: modelData.ssid === NetworkService.primarySsid
                ? "ACTIVE"
                : (NetworkService.connecting && NetworkService.pendingConnectSsid === modelData.ssid
                    ? "…" : modelData.signal + "%")
              activeRow: modelData.ssid === NetworkService.primarySsid
              secured: modelData.secured === true
              onRowClicked: {
                if (modelData.ssid !== NetworkService.primarySsid)
                  NetworkService.connectNetwork(modelData.ssid, modelData.secured)
              }
            }
          }

          Text {
            width: parent.width
            text: NetworkService.scanning ? "SCANNING…" : "NO NETWORKS FOUND"
            visible: NetworkService.hasWifi && NetworkService.wifiEnabled && NetworkService.availableNetworks.length === 0
            color: Theme.textDisabled
            font.pixelSize: Theme.fontSizeMicro
            font.family: Theme.fontFamilyMono
            font.letterSpacing: 0.06
            horizontalAlignment: Text.AlignHCenter
          }

          Text {
            width: parent.width
            text: NetworkService.lastError
            visible: NetworkService.lastError !== ""
            color: Theme.error
            font.pixelSize: Theme.fontSizeMicro
            font.family: Theme.fontFamilyMono
            wrapMode: Text.Wrap
          }
        }
      }

      Divider { width: parent.width }

      // ── Live stats ─────────────────────────────────
      RowLayout {
        width: parent.width
        spacing: Theme.spaceSm

        LiveStat { statIcon: "arrow-down"; value: netPopup._fmtRate(NetworkService.downRate) }
        LiveStat { statIcon: "arrow-up"; value: netPopup._fmtRate(NetworkService.upRate) }
        LiveStat { statIcon: "activity"; value: NetworkService.pingMs < 0 ? "…" : NetworkService.pingMs + " MS" }
      }
    }
  }

  component LiveStat: RowLayout {
    property string statIcon: ""
    property string value: ""

    Layout.fillWidth: true
    spacing: Theme.spaceXs

    Icon {
      source: Icons.get(statIcon)
      size: 12
      color: Theme.textDisabled
    }

    Text {
      Layout.fillWidth: true
      text: value
      color: Theme.textPrimary
      font.pixelSize: Theme.fontSizeCaption
      font.family: Theme.fontFamilyMono
      font.weight: Font.DemiBold
      elide: Text.ElideRight
    }
  }

  component NetRow: Rectangle {
    id: rowRoot

    property string name: ""
    property string detail: ""
    property bool activeRow: false
    property bool secured: false

    signal rowClicked()

    width: parent.width
    height: 28
    radius: Theme.radiusSmall
    color: rowMa.containsMouse ? Theme.controlBackgroundHover : "transparent"

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: Theme.spaceSm
      anchors.rightMargin: Theme.spaceSm
      spacing: Theme.spaceXs

      Text {
        Layout.fillWidth: true
        text: rowRoot.name
        color: rowRoot.activeRow ? Theme.accent : Theme.textPrimary
        font.pixelSize: Theme.fontSizeCaption
        font.family: Theme.fontFamilyMono
        font.weight: rowRoot.activeRow ? Font.DemiBold : Font.Normal
        elide: Text.ElideRight
      }

      Icon {
        source: Icons.get("lock")
        size: 10
        color: Theme.textDisabled
        visible: rowRoot.secured
      }

      Text {
        text: rowRoot.detail
        color: rowRoot.activeRow ? Theme.accent : Theme.textSecondary
        font.pixelSize: Theme.fontSizeMicro
        font.family: Theme.fontFamilyMono
        font.letterSpacing: 0.04
      }
    }

    MouseArea {
      id: rowMa
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: rowRoot.activeRow ? Qt.ArrowCursor : Qt.PointingHandCursor
      onClicked: rowRoot.rowClicked()
    }
  }
}
