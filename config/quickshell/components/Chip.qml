import QtQuick
import QtQuick.Layouts
import "../styles"
import "../core"

Rectangle {
  id: root

  property string icon: ""
  property string label: ""
  property int count: -1
  property bool selected: false

  signal clicked()

  height: Math.max(Theme.controlHeight + Theme.spaceXxs * 2, chipRow.implicitHeight + Theme.spaceXs * 2)
  radius: Theme.radiusMedium
  antialiasing: true
  width: chipRow.implicitWidth + Theme.spaceMd * 2
  color: selected ? Theme.accent : Theme.backgroundSecondary
  border.width: Theme.borderWidth
  border.color: selected ? Theme.accent : (hoverArea.containsMouse ? Theme.borderActive : Theme.border)

  Row {
    id: chipRow
    anchors.centerIn: parent
    spacing: Theme.spaceXs

    Icon {
      anchors.verticalCenter: parent.verticalCenter
      source: Icons.get(root.icon)
      size: 13
      color: root.selected ? Theme.contrastTextColor(Theme.accent) : Theme.textSecondary
      visible: root.icon !== ""
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.label.toUpperCase()
      color: root.selected ? Theme.contrastTextColor(Theme.accent) : Theme.textPrimary
      font.pixelSize: Theme.fontSizeMicro
      font.family: Theme.fontFamilyMono
      font.weight: Font.Bold
      font.letterSpacing: 0.08
    }

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.count > 0
      width: countText.implicitWidth + Theme.spaceSm
      height: countText.implicitHeight + Theme.spaceXxs * 2
      radius: height / 2
      antialiasing: true
      color: root.selected ? Theme.contrastTextColor(Theme.accent) : Theme.backgroundTertiary

      Text {
        id: countText
        anchors.centerIn: parent
        text: root.count
        color: root.selected ? Theme.accent : Theme.textSecondary
        font.pixelSize: Theme.fontSizeMicro
        font.family: Theme.fontFamilyMono
        font.weight: Font.Bold
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
