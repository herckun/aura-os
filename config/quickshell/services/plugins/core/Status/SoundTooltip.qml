import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../../../styles"
import "../../../../core"
import "../../../../services"
import "../../../../components"

PanelWindow {
  id: sndPopup

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
  property real popupX: PopupPositioner.anchorRightX(anchorItem, sndPopup.width, sndPopup.screen ? sndPopup.screen.width : 0)
  property bool switching: false

  function _recalcPopupX() {
    popupX = PopupPositioner.anchorRightX(anchorItem, sndPopup.width, sndPopup.screen ? sndPopup.screen.width : 0)
  }

  onWidthChanged: _recalcPopupX()
  onScreenChanged: _recalcPopupX()

  onVisibleChanged: {
    if (visible) _recalcPopupX()
    else switching = false
  }

  function toggle(): void {
    visible = !visible
  }

  function _openSettings(): void {
    sndPopup.visible = false
    IpcService.navigatePanel("settings", "audio")
  }

  HyprlandFocusGrab {
    windows: [sndPopup]
    active: sndPopup.visible
    onCleared: sndPopup.visible = false
  }

  Timer {
    id: leaveTimer
    interval: 2000
    onTriggered: sndPopup.visible = false
  }

  HoverHandler {
    onHoveredChanged: {
      if (hovered) leaveTimer.stop()
      else if (sndPopup.visible && !sndPopup.switching) leaveTimer.restart()
    }
  }

  Surface {
    id: bg
    anchors.fill: parent
    radius: Theme.radiusLarge
    antialiasing: true

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
          text: "SOUND"
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
          onClicked: sndPopup._openSettings()
        }
      }

      // ── Current output ─────────────────────────────
      CollapsibleHeader {
        width: parent.width
        expanded: sndPopup.switching
        onToggled: sndPopup.switching = !sndPopup.switching

        Icon {
          Layout.alignment: Qt.AlignVCenter
          source: Icons.get(AudioService.muted ? "volume-mute" : "speaker-low")
          size: 16
          color: AudioService.muted ? Theme.textDisabled : Theme.textPrimary
        }

        Column {
          Layout.fillWidth: true
          spacing: Theme.space2

          Text {
            width: parent.width
            text: AudioService.sinkName.toUpperCase()
            color: Theme.textPrimary
            font.pixelSize: Theme.fontSizeCaption
            font.family: Theme.fontFamilyMono
            font.weight: Font.DemiBold
            font.letterSpacing: 0.04
            elide: Text.ElideRight
          }

          Text {
            width: parent.width
            text: AudioService.muted
              ? "OUTPUT  ·  MUTED"
              : "OUTPUT  ·  " + Math.round(AudioService.volume * 100) + "%"
              + (AudioService.effectsActive ? "  ·  FX" : "")
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
          antialiasing: true
          color: AudioService.muted ? Theme.textDisabled : Theme.success
        }
      }

      // ── Output switcher ────────────────────────────
      Collapsible {
        expanded: sndPopup.switching
        animated: false

        Column {
          width: parent.width
          spacing: Theme.spaceXs
          bottomPadding: Theme.spaceXs

          Text {
            text: "OUTPUTS"
            color: Theme.textDisabled
            font.pixelSize: Theme.fontSizeMicro
            font.family: Theme.fontFamilyMono
            font.letterSpacing: 0.08
          }

          Repeater {
            model: AudioService.outputDevices

            delegate: SinkRow {
              required property var modelData
              name: (modelData.name || "").toUpperCase()
              detail: modelData.isDefault ? "ACTIVE" : (modelData.isVirtual ? "VIRTUAL" : "")
              activeRow: modelData.isDefault === true
              onRowClicked: {
                if (!modelData.isDefault)
                  AudioService.setOutputDevice(modelData.node)
              }
            }
          }

          Text {
            width: parent.width
            text: "NO OUTPUT DEVICES"
            visible: AudioService.outputDevices.length === 0
            color: Theme.textDisabled
            font.pixelSize: Theme.fontSizeMicro
            font.family: Theme.fontFamilyMono
            font.letterSpacing: 0.06
            horizontalAlignment: Text.AlignHCenter
          }
        }
      }

      Divider { width: parent.width }

      // ── Volume ─────────────────────────────────────
      SliderControl {
        width: parent.width
        from: 0; to: 1.0
        stepSize: 0.05
        displayMin: 0; displayMax: 100
        unit: "%"
        label: AudioService.muted ? "VOLUME  ·  MUTED" : "VOLUME"
        iconName: AudioService.muted ? "volume-mute" : "volume"
        iconColor: AudioService.muted ? Theme.warning : Theme.textSecondary
        opacity: AudioService.muted ? 0.6 : 1
        value: AudioService.volume
        onMoved: (v) => AudioService.setVolume(v)
        onIconClicked: AudioService.toggleMute()
      }

      // ── Microphone ─────────────────────────────────
      SliderControl {
        width: parent.width
        visible: AudioService.sourceReady
        from: 0; to: 1.0
        stepSize: 0.05
        displayMin: 0; displayMax: 100
        unit: "%"
        label: AudioService.micMuted ? "MIC  ·  MUTED" : "MIC"
        iconName: AudioService.micMuted ? "volume-mute" : "volume"
        iconColor: AudioService.micMuted ? Theme.warning : Theme.textSecondary
        opacity: AudioService.micMuted ? 0.6 : 1
        value: AudioService.micVolume
        onMoved: (v) => AudioService.setMicVolume(v)
        onIconClicked: AudioService.toggleMicMute()
      }
    }
  }

  component SinkRow: Rectangle {
    id: rowRoot

    property string name: ""
    property string detail: ""
    property bool activeRow: false

    signal rowClicked()

    width: parent.width
    height: 28
    radius: Theme.radiusSmall
    antialiasing: true
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
