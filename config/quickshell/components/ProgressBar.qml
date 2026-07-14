import QtQuick
import "../styles"

Rectangle {
  id: root

  property real value: 0
  property string variant: "accent"
  property color barColor: "transparent"
  property color trackColor: Theme.border
  property int barHeight: 6

  readonly property color _bc: barColor.a > 0 ? barColor : Theme.variantColor(variant)

  height: barHeight
  radius: barHeight / 2
  antialiasing: true
  color: trackColor

  Rectangle {
    width: parent.width * Math.max(0, Math.min(1, root.value))
    height: parent.height
    radius: root.barHeight / 2
    antialiasing: true
    color: root._bc

    Behavior on width {
      enabled: Theme.animationsEnabled
      NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic }
    }
  }
}
