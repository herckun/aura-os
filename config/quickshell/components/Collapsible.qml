import QtQuick
import "../styles"

Item {
  id: root

  property bool expanded: false
  property bool animated: true
  default property alias contentData: contentCol.data

  width: parent ? parent.width : implicitWidth
  implicitHeight: expanded ? contentCol.implicitHeight : 0
  height: implicitHeight
  clip: true

  Behavior on implicitHeight {
    enabled: Theme.animationsEnabled && root.animated
    NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic }
  }

  Column {
    id: contentCol
    anchors.top: parent.top
    width: parent.width
    opacity: root.expanded ? 1 : 0

    Behavior on opacity {
      enabled: Theme.animationsEnabled
      NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutQuad }
    }
  }
}
