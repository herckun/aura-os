import QtQuick
import Quickshell
import "../styles"

Item {
  id: root

  // ── Properties ─────────────────────────────────────────────
  property bool checked: false
  property string variant: "accent"
  property color trackOn: "transparent"
  property color trackOff: "transparent"
  property color thumbOn: "transparent"
  property color thumbOff: "transparent"
  property real toggleWidth: 44
  property real toggleHeight: 24

  // ── Signals ────────────────────────────────────────────────
  signal toggled(bool checked)

  // ── Internal state ─────────────────────────────────────────
  readonly property color _vto: trackOn.a > 0 ? trackOn : Theme.variantColor(variant)

  readonly property color _vtf: trackOff.a > 0 ? trackOff :
    variant === "accent" ? Theme.borderVisible :
    variant === "success" ? Theme.borderVisible :
    variant === "warning" ? Theme.borderVisible :
    variant === "error" ? Theme.borderVisible : Theme.borderVisible

  readonly property color _vho: thumbOn.a > 0 ? thumbOn : Theme.background
  readonly property color _vhf: thumbOff.a > 0 ? thumbOff : Theme.textDisabled

  width: toggleWidth
  height: toggleHeight

  Rectangle {
    id: trackBg
    anchors.fill: parent
    radius: height / 2
    antialiasing: true
    color: root.checked ? root._vto : root._vtf

    Behavior on color {
      enabled: Theme.animationsEnabled
      ColorAnimation { duration: Theme.animationFast }
    }
  }

  Rectangle {
    id: thumb
    width: root.height - 6
    height: root.height - 6
    radius: width / 2
    antialiasing: true
    color: root.checked ? root._vho : root._vhf
    x: root.checked ? parent.width - width - 3 : 3
    y: (parent.height - height) / 2

    Behavior on x {
      enabled: Theme.animationsEnabled
      NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutQuad }
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.toggled(!root.checked)
  }
}
