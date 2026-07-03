import QtQuick
import QtQuick.Layouts
import "../styles"

Rectangle {
  id: root

  property string label: ""
  property string infoValue: ""
  property bool active: true

  width: parent.width
  height: Theme.controlHeight + Theme.spaceXs
  radius: Theme.radiusMedium
  color: Theme.backgroundSecondary
  border.width: Theme.borderWidth
  border.color: Theme.border

  RowLayout {
    anchors { fill: parent; leftMargin: Theme.controlPadding; rightMargin: Theme.controlPadding }
    spacing: Theme.spaceSm

    Text {
      text: root.label
      color: Theme.textDisabled
      font.pixelSize: Theme.fontSizeCaption
      font.family: Theme.fontFamilyMono
    }

    Item { Layout.fillWidth: true; height: 1 }

    Text {
      text: root.infoValue
      color: root.active ? Theme.accent : Theme.textDisabled
      font.pixelSize: Theme.fontSizeCaption
      font.family: Theme.fontFamilyMono
      font.letterSpacing: 0.04
    }
  }
}
