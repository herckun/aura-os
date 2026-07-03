pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../../../styles"
import "../../../../components"

Column {
  id: root

  property string title: ""
  property var presets: []
  property string activePreset: ""
  signal selected(string name)

  width: parent.width
  spacing: Theme.spaceSm

  Divider {}

  Column {
    width: parent.width
    spacing: Theme.spaceXs

    Text {
      text: root.title
      color: Theme.textDisabled
      font.pixelSize: Theme.fontSizeMicro
      font.family: Theme.fontFamilyMono
      font.letterSpacing: 0.08
    }

    Repeater {
      model: root.presets

      delegate: Rectangle {
        id: presetRow
        required property var modelData
        readonly property bool active: presetRow.modelData === root.activePreset

        width: parent.width
        height: 32
        radius: Theme.radiusSmall
        color: presetRow.active ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)
          : presetHover.containsMouse ? Theme.controlBackgroundHover : "transparent"
        border.width: Theme.borderWidth
        border.color: presetRow.active ? Theme.accent : "transparent"

        RowLayout {
          anchors { left: parent.left; leftMargin: Theme.spaceSm; right: parent.right; rightMargin: Theme.spaceSm; verticalCenter: parent.verticalCenter }
          spacing: Theme.spaceSm

          Text {
            text: presetRow.modelData
            color: presetRow.active ? Theme.accent : Theme.textPrimary
            font.pixelSize: Theme.fontSizeLabel
            font.family: Theme.fontFamilyMono
            Layout.fillWidth: true
          }

          Badge {
            text: "ACTIVE"
            bgColor: Theme.accent
            textColor: Theme.background
            size: "sm"
            visible: presetRow.active
          }
        }

        MouseArea {
          id: presetHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.selected(presetRow.modelData)
        }
      }
    }
  }
}
