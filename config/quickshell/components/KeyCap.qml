import QtQuick
import "../styles"

Rectangle {
  id: root

  property string label: ""
  property bool accent: false

  width: _label.implicitWidth + Theme.spaceSm * 2
  height: _label.implicitHeight + Theme.spaceXs * 2
  radius: Theme.radiusXs
  color: accent ? Theme.accent : Theme.backgroundTertiary
  border.width: accent ? 0 : 1
  border.color: Theme.controlBorder

  Text {
    id: _label
    anchors.centerIn: parent
    text: root.label
    color: root.accent ? Theme.background : Theme.textSecondary
    font.pixelSize: Theme.fontSizeMicro
    font.family: Theme.fontFamilyMono
    font.weight: Font.Bold
    font.letterSpacing: 0.04
  }
}
