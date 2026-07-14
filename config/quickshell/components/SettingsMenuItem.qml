import QtQuick
import QtQuick.Layouts
import "../styles"
import "../core"

Rectangle {
  id: root

  property string icon: ""
  property string label: ""
  property bool selected: false

  signal clicked()

  width: parent.width
  height: Theme.controlHeight + Theme.spaceSm
  radius: Theme.radiusMedium
  antialiasing: true
  color: selected
    ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)
    : hoverArea.containsMouse
      ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.06)
      : "transparent"

  Behavior on color {
    enabled: Theme.animationsEnabled
    ColorAnimation { duration: Theme.animationFast }
  }

  Rectangle {
    anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
    width: 2; height: 16; radius: Theme.radiusXs
    color: Theme.accent
    opacity: root.selected ? 1 : 0

    Behavior on opacity {
      enabled: Theme.animationsEnabled
      NumberAnimation { duration: Theme.animationNormal }
    }
  }

  Row {
    anchors { left: parent.left; leftMargin: 16; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
    spacing: Theme.spaceSm

    Icon {
      source: Icons.get(root.icon)
      size: 14
      color: root.selected ? Theme.accent : (hoverArea.containsMouse ? Theme.textPrimary : Theme.textSecondary)
      anchors.verticalCenter: parent.verticalCenter

      Behavior on color {
        enabled: Theme.animationsEnabled
        ColorAnimation { duration: Theme.animationFast }
      }
    }

    Text {
      text: root.label
      color: root.selected ? Theme.accent : (hoverArea.containsMouse ? Theme.textPrimary : Theme.textSecondary)
      font.pixelSize: Theme.fontSizeCaption
      font.family: Theme.fontFamilyMono
      font.letterSpacing: 1
      font.weight: root.selected ? Font.Bold : Font.Normal
      anchors.verticalCenter: parent.verticalCenter

      Behavior on color {
        enabled: Theme.animationsEnabled
        ColorAnimation { duration: Theme.animationFast }
      }
    }
  }

  MouseArea {
    id: hoverArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
