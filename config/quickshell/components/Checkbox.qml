import QtQuick
import QtQuick.Layouts
import "../styles"
import "../core"

Item {
  id: root

  // ── Properties ─────────────────────────────────────────────
  property bool checked: false
  property string variant: "accent"
  property color checkedColor: "transparent"
  property color borderColor: Theme.border
  property color hoverBorderColor: Theme.borderVisible
  property color checkColor: Theme.background
  property int size: 18

  // ── Signals ────────────────────────────────────────────────
  signal toggled(bool checked)

  // ── Internal state ─────────────────────────────────────────
  readonly property color _vc: checkedColor.a > 0 ? checkedColor : Theme.variantColor(variant)

  readonly property color _ct: Theme.contrastTextColor(_vc)

  width: size
  height: size

  Rectangle {
    id: box
    anchors.fill: parent
    radius: Theme.radiusSmall
    color: root.checked ? root._vc : "transparent"
    border.width: Theme.borderWidth
    border.color: mouse.containsMouse ? root.hoverBorderColor : (root.checked ? root._vc : root.borderColor)

    Behavior on color {
      enabled: Theme.animationsEnabled
      ColorAnimation { duration: Theme.animationFast }
    }
    Behavior on border.color {
      enabled: Theme.animationsEnabled
      ColorAnimation { duration: Theme.animationFast }
    }
  }

  Icon {
    anchors.centerIn: parent
    source: Icons.get("check")
    size: root.size * 0.6
    color: root._ct
    visible: root.checked
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      root.checked = !root.checked
      root.toggled(root.checked)
    }
  }
}
