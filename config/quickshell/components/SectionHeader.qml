import QtQuick
import "../styles"

Column {
  id: root

  property string text: ""

  width: parent.width
  spacing: Theme.spaceSm

  Rectangle { width: parent.width; height: 1; color: Theme.border }

  Text {
    text: root.text.toUpperCase()
    color: Theme.accent
    font.pixelSize: Theme.fontSizeMicro
    font.family: Theme.fontFamilyMono
    font.weight: Font.Bold
    font.letterSpacing: 0.12
  }
}
