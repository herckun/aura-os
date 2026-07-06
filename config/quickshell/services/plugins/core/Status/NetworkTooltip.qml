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
  implicitHeight: contentCol.implicitHeight + 28

  anchors { top: true; left: true }
  margins.top: PopupPositioner.belowBar()
  margins.left: popupX
  exclusiveZone: 0
  color: "transparent"
  visible: false

  mask: Region { item: bg }

  property Item anchorItem: null
  property real popupX: PopupPositioner.anchorRightX(anchorItem, netPopup.width, netPopup.screen ? netPopup.screen.width : 0)
  property string publicIp: ""

  function _recalcPopupX() {
    popupX = PopupPositioner.anchorRightX(anchorItem, netPopup.width, netPopup.screen ? netPopup.screen.width : 0)
  }

  onWidthChanged: _recalcPopupX()
  onScreenChanged: _recalcPopupX()

  onVisibleChanged: {
    if (visible) {
      _recalcPopupX()
      _fetchIp()
    }
  }

  function _fetchIp(): void {
    RequestService.get("https://ipinfo.io/json", function(r) {
      netPopup.publicIp = (r.ok && r.data && r.data.ip) ? r.data.ip : ""
    })
  }

  function toggle(): void {
    visible = !visible
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
      else if (netPopup.visible) leaveTimer.restart()
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

      // ── Hero ───────────────────────────────────────
      RowLayout {
        width: parent.width
        spacing: Theme.spaceSm

        Icon {
          Layout.alignment: Qt.AlignVCenter
          source: Icons.get(NetworkService.online
            ? (NetworkService.ethernetConnected ? "globe" : "wifi-high") : "wifi-off")
          size: 26
          color: NetworkService.online ? Theme.textPrimary : Theme.textDisabled
        }

        Column {
          Layout.fillWidth: true
          spacing: Theme.space2

          Text {
            width: parent.width
            text: NetworkService.online
              ? (NetworkService.ethernetConnected
                  ? "WIRED"
                  : (NetworkService.primarySsid || "WI-FI").toUpperCase())
              : "OFFLINE"
            color: NetworkService.online ? Theme.textDisplay : Theme.textDisabled
            font.pixelSize: Theme.fontSizeTitle
            font.family: Theme.fontFamilyDeco
            font.weight: Font.Bold
            elide: Text.ElideRight
          }

          Text {
            width: parent.width
            text: NetworkService.online
              ? (NetworkService.ethernetConnected
                  ? (NetworkService.ethernetConnection || "ETHERNET").toUpperCase() + "  ·  CONNECTED"
                  : "WIRELESS  ·  " + NetworkService.signalStrength + "% SIGNAL")
              : "NO ACTIVE CONNECTION"
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSizeMicro
            font.family: Theme.fontFamilyMono
            font.letterSpacing: 0.06
            elide: Text.ElideRight
          }
        }

        Button {
          Layout.alignment: Qt.AlignTop
          shape: "icon"
          icon: "gear"
          size: "xs"
          showBackground: false
          tooltip: "SETTINGS"
          onClicked: {
            netPopup.visible = false
            IpcService.navigatePanel("settings", "connectivity")
          }
        }
      }

      // ── Signal bar (wifi) ──────────────────────────
      ProgressBar {
        width: parent.width
        value: NetworkService.signalStrength / 100
        barHeight: 3
        visible: NetworkService.online && !NetworkService.ethernetConnected
      }

      Divider { width: parent.width }

      // ── Stats grid ─────────────────────────────────
      GridLayout {
        width: parent.width
        columns: 2
        columnSpacing: Theme.spaceSm
        rowSpacing: Theme.spaceXs

        StatCell { label: "PUBLIC IP"; value: netPopup.publicIp !== "" ? netPopup.publicIp : "…" }
        StatCell {
          label: "DEVICE"
          value: NetworkService.ethernetConnected
            ? (NetworkService.ethernetDevice || "—")
            : (NetworkService.online ? "WI-FI" : "—")
        }
        StatCell {
          label: "TYPE"
          value: NetworkService.online
            ? (NetworkService.ethernetConnected ? "ETHERNET" : "WIRELESS") : "—"
        }
        StatCell {
          label: "WI-FI RADIO"
          value: NetworkService.hasWifi ? (NetworkService.wifiEnabled ? "ON" : "OFF") : "—"
        }
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
