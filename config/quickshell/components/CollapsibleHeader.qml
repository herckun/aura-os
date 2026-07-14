import QtQuick
import QtQuick.Layouts
import "../styles"
import "../core"

Rectangle {
  id: root

  property bool expanded: false
  default property alias contentData: contentRow.data

  signal toggled()

  implicitWidth: contentRow.implicitWidth + chevron.width + Theme.spaceSm * 2 + Theme.spaceXs
  implicitHeight: contentRow.implicitHeight + Theme.spaceSm * 2
  radius: Theme.radiusSmall
  antialiasing: true
  color: headerMa.containsMouse ? Theme.controlBackgroundHover : "transparent"

  Behavior on color {
    enabled: Theme.animationsEnabled
    ColorAnimation { duration: Theme.animationFast; easing.type: Easing.OutQuad }
  }

  MouseArea {
    id: headerMa
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.toggled()
  }

  RowLayout {
    id: contentRow
    anchors {
      left: parent.left
      right: chevron.left
      verticalCenter: parent.verticalCenter
      leftMargin: Theme.spaceSm
      rightMargin: Theme.spaceXs
    }
    spacing: Theme.spaceSm
  }

  Icon {
    id: chevron
    anchors.right: parent.right
    anchors.rightMargin: Theme.spaceSm
    anchors.verticalCenter: parent.verticalCenter
    source: Icons.get("chevron.down")
    size: 12
    color: headerMa.containsMouse ? Theme.textPrimary : Theme.textSecondary
    rotation: root.expanded ? 180 : 0

    Behavior on rotation {
      enabled: Theme.animationsEnabled
      NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic }
    }
  }
}
