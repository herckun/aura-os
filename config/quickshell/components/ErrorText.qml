import QtQuick
import "../styles"

Text {
  id: root

  property string errorText: ""

  width: parent.width
  text: errorText
  color: Theme.error
  font.pixelSize: Theme.fontSizeCaption
  font.family: Theme.fontFamilyMono
  visible: errorText !== ""
}
