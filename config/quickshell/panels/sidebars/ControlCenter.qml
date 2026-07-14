import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../styles"
import "../../core"
import "../../services"
import "../../components"

PanelContainer {
  id: cc

  implicitWidth: 320
  paddingX: 22
  paddingY: 20
  maxHeightRatio: 0.88
  scrollLock: ccHeader.menuOpen

  // ── Header ──────────────────────────────────────────────
  ControlCenterHeader {
    id: ccHeader
  }

  // ── Quick Toggles ───────────────────────────────────────
  Section {
    borderEnabled: false
    transparentBg: true
    paddingX: 0
    paddingY: 0
    QuickToggles {
      width: parent.width
    }
  }

  // ── Volume + Brightness ─────────────────────────────────
  Section {
    Column {
      width: parent.width
      spacing: Theme.spaceMd

      SliderControl {
        width: parent.width
        from: 0; to: 1.0
        value: AudioService.volume
        stepSize: 0.05
        label: AudioService.muted ? "VOLUME  ·  MUTED" : "VOLUME"
        unit: "%"
        displayMin: 0; displayMax: 100
        opacity: AudioService.muted ? 0.5 : 1
        onMoved: (v) => AudioService.setVolume(v)
      }

      SliderControl {
        width: parent.width
        from: 0.05; to: 1
        value: BrightnessService.brightness
        stepSize: 0.05
        label: "BRIGHTNESS"
        unit: "%"
        displayMin: 5; displayMax: 100
        visible: BrightnessService.hasDevice
        onMoved: (v) => BrightnessService.setBrightness(v)
      }
    }
  }

  // ── Plugin Sections ─────────────────────────────────────
  PluginHost {
    width: parent.width
    location: "controlcenter_row"
    sectioned: true
  }

  // ── Floating header menu ────────────────────────────────
  Item {
    id: menuLayer
    parent: cc.contentItem
    anchors.fill: parent
    z: 50
    visible: scrim.opacity > 0.01

    Connections {
      target: ccHeader
      function onMenuOpenChanged() {
        if (ccHeader.menuOpen && ccHeader.menuAnchor)
          menuPanel.anchorY = ccHeader.menuAnchor.mapToItem(cc.contentItem, 0, ccHeader.menuAnchor.height).y + Theme.spaceSm
      }
    }

    Item {
      id: scrim
      x: cc.bg.x
      y: menuPanel.anchorY - Theme.spaceSm
      width: cc.bg.width
      height: cc.bg.y + cc.bg.height - y
      opacity: ccHeader.menuOpen ? 1 : 0
      layer.enabled: true
      layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: scrimMask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
      }

      Behavior on opacity { enabled: Theme.animationsEnabled; NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }

      ShaderEffectSource {
        id: scrimSource
        x: cc.paddingX - cc.outerMargin
        y: cc.paddingY - scrim.y
        width: cc.contentWrap.width
        height: cc.contentWrap.height
        sourceItem: cc.contentWrap
        live: true
        visible: false
      }

      MultiEffect {
        x: scrimSource.x
        y: scrimSource.y
        width: scrimSource.width
        height: scrimSource.height
        source: scrimSource
        blurEnabled: Theme.blurEnabled
        blur: 1
        blurMax: 40
        autoPaddingEnabled: false
      }

      Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, Theme.blurEnabled ? 0.6 : 0.8)
      }
    }

    MouseArea {
      anchors.fill: scrim
      enabled: ccHeader.menuOpen
      onClicked: ccHeader.menuOpen = false
      onWheel: (wheel) => {
        wheel.accepted = true
      }
    }

    Item {
      id: scrimMask
      width: scrim.width
      height: scrim.height
      visible: false
      layer.enabled: true

      Rectangle {
        x: 0
        y: -Theme.radiusLarge
        width: parent.width
        height: parent.height + Theme.radiusLarge
        radius: Theme.radiusLarge
        antialiasing: true
        color: "#FFFFFF"
      }
    }

    Surface {
      id: menuPanel

      property real anchorY: 72

      x: cc.paddingX
      y: anchorY
      width: cc.width - cc.paddingX * 2
      height: menuCol.implicitHeight + Theme.spaceSm * 2
      radius: Theme.radiusLarge
      antialiasing: true
      color: Theme.panelBackground
      border.color: Theme.borderVisible
      opacity: ccHeader.menuOpen ? 1 : 0
      scale: ccHeader.menuOpen ? 1 : 0.92
      transformOrigin: Item.Top

      Behavior on opacity { enabled: Theme.animationsEnabled; NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic } }
      Behavior on scale { enabled: Theme.animationsEnabled; NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutBack } }

      Column {
        id: menuCol
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceSm }
        spacing: Theme.spaceXxs

        Repeater {
          model: ccHeader._menuActions.filter((a) => a.group === 0)

          delegate: MenuRow {
            required property var modelData
            icon: modelData.icon
            label: modelData.label
            onClicked: ccHeader._runAction(modelData)
          }
        }

        Divider { width: parent.width }

        Repeater {
          model: ccHeader._menuActions.filter((a) => a.group === 1)

          delegate: MenuRow {
            required property var modelData
            icon: modelData.icon
            label: modelData.label
            onClicked: ccHeader._runAction(modelData)
          }
        }

        Divider { width: parent.width }

        Repeater {
          model: ccHeader._menuActions.filter((a) => a.group === 2)

          delegate: MenuRow {
            required property var modelData
            icon: modelData.icon
            label: modelData.label
            danger: modelData.danger === true
            onClicked: ccHeader._runAction(modelData)
          }
        }
      }
    }
  }
}
