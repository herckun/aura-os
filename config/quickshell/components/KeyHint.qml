import QtQuick
import "../styles"

Row {
  id: root

  property string key: ""
  property string label: ""
  property bool accent: false

  spacing: Theme.spaceXs

  KeyCap {
    label: root.key
    accent: root.accent
    anchors.verticalCenter: parent.verticalCenter
  }

  Text {
    text: root.label
    visible: root.label.length > 0
    color: Theme.textDisabled
    font.pixelSize: Theme.fontSizeCaption
    font.family: Theme.fontFamilyMono
    anchors.verticalCenter: parent.verticalCenter
  }
}
