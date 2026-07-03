import QtQuick
import "../styles"

Item {
  id: root

  property string label: ""
  property string value: ""
  property color valueColor: Theme.textSecondary

  width: parent.width
  height: Theme.controlHeight

  Rectangle {
    anchors.fill: parent
    radius: Theme.radiusSmall
    color: hoverArea.containsMouse ? Theme.controlBackgroundHover : "transparent"

    MouseArea {
      id: hoverArea
      anchors.fill: parent
      hoverEnabled: true
    }
  }

  Text {
    anchors { left: parent.left; leftMargin: Theme.controlPadding; verticalCenter: parent.verticalCenter }
    text: root.label.toUpperCase()
    color: Theme.textPrimary
    font.pixelSize: Theme.fontSizeCaption
    font.family: Theme.fontFamilyMono
    font.letterSpacing: 0.04
  }

  Text {
    anchors { right: parent.right; rightMargin: Theme.controlPadding; verticalCenter: parent.verticalCenter }
    text: root.value
    color: root.valueColor
    font.pixelSize: Theme.fontSizeCaption
    font.family: Theme.fontFamilyMono
    font.letterSpacing: 0.04
    elide: Text.ElideRight
    width: Math.min(implicitWidth, 240)
    horizontalAlignment: Text.AlignRight
  }
}
