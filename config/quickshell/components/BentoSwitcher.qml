import QtQuick
import QtQuick.Layouts
import "../styles"
import "../core"

Column {
  id: root

  property var items: []
  property int currentIndex: 0
  property int columns: 3
  property int cellWidth: 100
  property int cellHeight: 80
  property string variant: "accent"

  signal selected(int index)

  readonly property color _sc: Theme.variantColor(variant)

  readonly property int _cols: Math.min(columns, items.length)
  readonly property int _rows: Math.ceil(items.length / _cols)

  spacing: Theme.spaceSm

  GridLayout {
    width: parent.width
    columns: root._cols
    columnSpacing: Theme.spaceSm
    rowSpacing: Theme.spaceSm

    Repeater {
      model: root.items

      delegate: Item {
        id: cell
        required property var modelData
        required property int index

        Layout.fillWidth: true
        Layout.preferredHeight: root.cellHeight

        readonly property bool selected: index === root.currentIndex
        readonly property bool hovered: hoverArea.containsMouse

        Rectangle {
          anchors.fill: parent
          radius: Theme.radiusMedium
          antialiasing: true
          color: cell.selected ? Qt.rgba(root._sc.r, root._sc.g, root._sc.b, 0.15) :
            cell.hovered ? Theme.controlBackgroundHover :
            Theme.backgroundTertiary

          border.width: cell.selected ? 2 : Theme.borderWidth
          border.color: cell.selected ? root._sc : Theme.border

          Behavior on color {
            enabled: Theme.animationsEnabled
            ColorAnimation { duration: Theme.animationNormal; easing.type: Easing.OutQuad }
          }
          Behavior on border.color {
            enabled: Theme.animationsEnabled
            ColorAnimation { duration: Theme.animationNormal; easing.type: Easing.OutQuad }
          }

          Column {
            anchors.centerIn: parent
            spacing: Theme.spaceXs

            Icon {
              anchors.horizontalCenter: parent.horizontalCenter
              source: cell.modelData.icon ? Icons.get(cell.modelData.icon) : ""
              size: 22
              color: cell.selected ? root._sc : Theme.textSecondary
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: cell.modelData.name || ""
              color: cell.selected ? Theme.textPrimary : Theme.textSecondary
              font.pixelSize: Theme.fontSizeCaption
              font.family: Theme.fontFamilyMono
              font.weight: Font.Medium
              font.letterSpacing: 0.06
            }
          }
        }

        MouseArea {
          id: hoverArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.selected(cell.index)
        }
      }
    }
  }

  Text {
    width: parent.width
    text: {
      var item = root.items[root.currentIndex]
      return (item && item.description) ? item.description : ""
    }
    color: Theme.textSecondary
    font.pixelSize: Theme.fontSizeCaption
    font.family: Theme.fontFamilyMono
    horizontalAlignment: Text.AlignHCenter
    visible: text !== ""
  }
}
