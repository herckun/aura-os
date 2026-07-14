import QtQuick
import "../styles"

Row {
  id: root

  property real value: 0
  property real stepSize: 1
  property real minValue: 0
  property real maxValue: 100
  property string unit: ""
  property string label: ""
  property string variant: "accent"
  property color valueColor: "transparent"

  signal stepped()

  readonly property color _vc: valueColor.a > 0 ? valueColor : Theme.variantColor(variant)

  spacing: Theme.spaceSm

  Button {
    shape: "circle"
    width: Theme.controlHeight; height: Theme.controlHeight
    text: "−"
    onClicked: {
      root.value = Math.max(root.minValue, root.value - root.stepSize)
      root.stepped()
    }
  }

  Rectangle {
    width: Theme.controlHeight + Theme.spaceXs * 2; height: Theme.controlHeight
    radius: Theme.radiusPill
    antialiasing: true
    color: Theme.backgroundTertiary
    border.width: Theme.borderWidth; border.color: Theme.border

    Text {
      anchors.centerIn: parent
      text: Math.round(root.value) + root.unit
      color: root._vc
      font.pixelSize: Theme.fontSizeLabel
      font.family: Theme.fontFamilyMono
      font.weight: Font.Bold
      font.letterSpacing: 0.04
    }
  }

  Button {
    shape: "circle"
    width: Theme.controlHeight; height: Theme.controlHeight
    text: "+"
    onClicked: {
      root.value = Math.min(root.maxValue, root.value + root.stepSize)
      root.stepped()
    }
  }
}
