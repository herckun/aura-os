import QtQuick
import "../styles"

Row {
  id: root

  property var tabs: []
  property int currentIndex: 0
  signal selected(int index)

  spacing: Theme.spaceXs

  Repeater {
    model: root.tabs

    delegate: Chip {
      required property var modelData
      required property int index
      readonly property int tabIndex: modelData.tab !== undefined ? modelData.tab : index

      icon: modelData.icon || ""
      label: modelData.label || ""
      selected: root.currentIndex === tabIndex
      onClicked: root.selected(tabIndex)
    }
  }
}
