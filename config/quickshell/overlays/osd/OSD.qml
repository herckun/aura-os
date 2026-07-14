import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../styles"
import "../../core"
import "../../services"
import "../../components"

PanelWindow {
  id: osd

  implicitWidth: 80
  implicitHeight: contentCol.implicitHeight + Theme.spaceLg * 2

  anchors { bottom: true; left: true }
  margins.bottom: Theme.spaceLg
  margins.left: osd.screen ? (osd.screen.width - osd.implicitWidth) / 2 : 0
  exclusiveZone: 0
  color: "transparent"
  visible: false

  property string icon: ""
  property real value: 0
  property string text: ""

  Timer {
    id: hideTimer
    interval: 1500
    onTriggered: osd.hide()
  }

  function show(iconName: string, val: real, txt: string): void {
    osd.icon = iconName
    osd.value = val
    osd.text = txt
    osd.visible = true
    Qt.callLater(function() { osd.shown = true })
    hideTimer.restart()
  }

  function hide(): void {
    osd.shown = false
    hideTimer.stop()
  }

  property bool shown: false

  Surface {
    id: osdRect
    anchors.fill: parent
    radius: Theme.radiusLarge
    antialiasing: true

    state: osd.shown ? "shown" : "hidden"

    states: [
      State { name: "hidden"; PropertyChanges { target: osdRect; opacity: 0; y: 12 } },
      State { name: "shown"; PropertyChanges { target: osdRect; opacity: 1; y: 0 } }
    ]

    transitions: [
      Transition {
        from: "hidden"; to: "shown"
        NumberAnimation { properties: "opacity,y"; duration: Theme.animationFast; easing.type: Easing.OutCubic }
      },
      Transition {
        from: "shown"; to: "hidden"
        SequentialAnimation {
          NumberAnimation { properties: "opacity,y"; duration: Theme.animationFast; easing.type: Easing.InCubic }
          ScriptAction { script: { osd.visible = false } }
        }
      }
    ]

    Column {
      id: contentCol
      anchors { left: parent.left; right: parent.right; top: parent.top }
      anchors.topMargin: Theme.spaceMd
      anchors.leftMargin: Theme.spaceMd
      anchors.rightMargin: Theme.spaceMd
      spacing: Theme.spaceSm

      // ── Icon ──────────────────────────────────────
      Icon {
        anchors.horizontalCenter: parent.horizontalCenter
        source: Icons.get(osd.icon)
        size: 22
        color: Theme.textDisplay
      }

      // ── Value ─────────────────────────────────────
      OpticalText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Math.round(osd.value * 100)
        color: Theme.textDisplay
        font.pixelSize: Theme.fontSizeTitle
        font.family: Theme.fontFamilyDisplay
        font.weight: Font.Bold
      }

      // ── Progress bar ──────────────────────────────
      Rectangle {
        width: parent.width
        height: 4
        radius: Theme.radiusXs
        antialiasing: true
        color: Theme.border

        Rectangle {
          height: parent.height
          radius: Theme.radiusXs
          antialiasing: true
          width: parent.width * Math.max(0, Math.min(1, osd.value))
          color: Theme.accent

          Behavior on width {
            enabled: Theme.animationsEnabled
            NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic }
          }
        }
      }
    }
  }
}
