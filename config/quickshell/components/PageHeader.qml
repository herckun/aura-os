import QtQuick
import QtQuick.Layouts
import "../styles"

Column {
  id: root

  property string title: ""

  spacing: Theme.spaceSm

  Text {
    text: (root.title || "").toUpperCase()
    color: Theme.textDisplay
    font.pixelSize: Theme.fontSizeHeading
    font.family: Theme.fontFamilyDisplay
    font.letterSpacing: 2
  }

  Rectangle {
    width: parent.width
    height: 1
    color: Theme.border
  }
}
