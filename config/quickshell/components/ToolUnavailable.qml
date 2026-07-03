import QtQuick
import "../styles"

Column {
  id: root

  property string toolName: ""
  property string toolPackage: ""

  width: parent.width
  spacing: Theme.spaceSm

  SectionLabel { label: toolName.toUpperCase() }

  Card {
    width: parent.width
    description: root.toolPackage + " not installed"

    Text {
      width: parent.width
      text: "sudo pacman -S " + root.toolPackage
      color: Theme.textSecondary
      font.pixelSize: Theme.fontSizeCaption
      font.family: Theme.fontFamilyMono
      horizontalAlignment: Text.AlignHCenter
      topPadding: Theme.spaceSm
    }
  }
}
