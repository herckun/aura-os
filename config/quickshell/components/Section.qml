import QtQuick
import "../styles"

Item {
  id: root

  default property alias content: container.data
  property int paddingX: Theme.controlPadding
  property int paddingY: Theme.controlPadding
  property bool borderEnabled: true
  property bool transparentBg: false

  width: parent ? parent.width : implicitWidth
  implicitWidth: 300
  implicitHeight: container.implicitHeight + root.paddingY * 2
  height: implicitHeight

  Surface {
    anchors.fill: parent
    radius: Theme.radiusMedium
    bordered: root.borderEnabled
    color: root.transparentBg ? "transparent" : Theme.backgroundSecondary
    border.color: Theme.border
  }

  Column {
    id: container
    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: root.paddingX; rightMargin: root.paddingX }
    anchors.topMargin: root.paddingY
    anchors.bottomMargin: root.paddingY
    spacing: Theme.spaceSm
  }
}
