import QtQuick
import "../styles"

Surface {
  id: root

  property string title: ""
  property string description: ""

  width: parent ? parent.width : implicitWidth
  implicitHeight: headerCol.implicitHeight + Theme.spaceMd * 2
  height: implicitHeight
  radius: Theme.radiusMedium
  antialiasing: true
  border.color: Theme.border

  Rectangle {
    id: accentBar
    anchors.left: parent.left
    anchors.leftMargin: Theme.spaceMd
    anchors.verticalCenter: parent.verticalCenter
    width: 3
    height: headerCol.implicitHeight
    radius: Theme.radiusXs
    antialiasing: true
    color: Theme.accent
  }

  Column {
    id: headerCol
    anchors.left: accentBar.right
    anchors.leftMargin: Theme.spaceMd
    anchors.right: parent.right
    anchors.rightMargin: Theme.spaceMd
    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.spaceSm

    Text {
      text: (root.title || "").toUpperCase()
      color: Theme.textDisplay
      font.pixelSize: Theme.fontSizeHeading
      font.family: Theme.fontFamilyDisplay
      font.letterSpacing: 2
      elide: Text.ElideRight
      width: parent.width
    }

    Text {
      visible: root.description !== ""
      text: root.description
      color: Theme.textSecondary
      font.pixelSize: Theme.fontSizeCaption
      font.family: Theme.fontFamilyMono
      font.letterSpacing: 0.04
      wrapMode: Text.WordWrap
      width: parent.width
    }
  }
}
