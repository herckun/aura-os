import QtQuick
import "../styles"
import "../core"

Rectangle {
  id: root

  property string label: ""
  property string icon: ""
  property color textColor: Theme.textDisabled

  implicitWidth: tagRow.implicitWidth + Theme.spaceSm
  implicitHeight: tagRow.implicitHeight + Theme.spaceXxs * 2
  radius: Theme.radiusSmall
  color: Theme.controlBackground

  Row {
    id: tagRow
    anchors.centerIn: parent
    spacing: Theme.spaceXxs

    Icon {
      anchors.verticalCenter: parent.verticalCenter
      source: root.icon ? Icons.get(root.icon) : ""
      size: Theme.fontSizeMicro
      color: root.textColor
      visible: root.icon !== ""
    }
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.label.toUpperCase()
      color: root.textColor
      font.pixelSize: Theme.fontSizeMicro
      font.family: Theme.fontFamilyMono
      font.letterSpacing: 0.08
    }
  }
}
