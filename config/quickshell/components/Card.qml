import QtQuick
import QtQuick.Layouts
import "../styles"

Item {
  id: root

  // ── Properties ─────────────────────────────────────────────
  default property alias content: container.data
  property string title: ""
  property string description: ""
  property int padding: Theme.cardPadding

  width: parent ? parent.width : implicitWidth
  implicitWidth: 300
  height: implicitHeight
  implicitHeight: container.implicitHeight + (title ? (Theme.spaceMd + Theme.spaceSm) : padding * 2)

  Surface {
    anchors.fill: parent
    radius: Theme.radiusMedium
    border.color: Theme.border
  }

  Column {
    id: container
    anchors.fill: parent
    anchors.margins: root.padding
    spacing: Theme.spaceMd

    Column {
      width: parent.width
      spacing: Theme.spaceXs
      visible: root.title !== ""

      Text {
        text: root.title
        color: Theme.textSecondary
        font.pixelSize: Theme.fontSizeLabel
        font.family: Theme.fontFamilyMono
        font.letterSpacing: 0.1
      }

      Divider { width: parent.width }

      Text {
        visible: root.description !== ""
        width: parent.width
        text: root.description
        color: Theme.textDisabled
        font.pixelSize: Theme.fontSizeCaption
        font.family: Theme.fontFamilyMono
        font.letterSpacing: 0.04
        wrapMode: Text.WordWrap
      }
    }
  }
}
