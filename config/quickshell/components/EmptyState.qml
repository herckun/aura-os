import QtQuick
import "../styles"
import "../core"

Column {
  id: root

  // ── Properties ─────────────────────────────────────────────
  property string stateText: ""
  property string description: ""
  property string icon: ""
  property int iconSize: 24

  width: parent ? parent.width : implicitWidth
  spacing: Theme.spaceSm
  topPadding: Theme.spaceSm
  bottomPadding: Theme.spaceSm

  Surface {
    visible: root.icon !== ""
    width: 56
    height: 56
    radius: width / 2
    antialiasing: true
    bordered: false
    color: Theme.controlBackground
    anchors.horizontalCenter: parent.horizontalCenter

    Icon {
      anchors.centerIn: parent
      source: Icons.get(root.icon)
      size: root.iconSize
      color: Theme.textDisabled
    }
  }

  Text {
    visible: root.stateText !== ""
    width: parent.width
    horizontalAlignment: Text.AlignHCenter
    text: root.stateText
    color: Theme.textSecondary
    font.pixelSize: Theme.fontSizeSubhead
    font.family: Theme.fontFamily
  }

  Text {
    visible: root.description !== ""
    width: parent.width
    horizontalAlignment: Text.AlignHCenter
    text: root.description
    color: Theme.textDisabled
    font.pixelSize: Theme.fontSizeCaption
    font.family: Theme.fontFamilyMono
  }
}
