import QtQuick
import "../styles"

Text {
  property string label: ""

  text: label.toUpperCase()
  color: Theme.textDisabled
  font.pixelSize: Theme.fontSizeMicro
  font.family: Theme.fontFamilyMono
  font.letterSpacing: 0.1
}
