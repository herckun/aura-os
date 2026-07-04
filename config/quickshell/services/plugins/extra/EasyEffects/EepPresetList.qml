pragma ComponentBehavior: Bound
import QtQuick
import "../../../../styles"
import "../../../../components"

Column {
  id: root

  property string title: ""
  property var presets: []
  property string activePreset: ""
  property string pendingPreset: ""
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

      DeviceRow {
        id: presetRow
        required property var modelData
        readonly property bool isActive: presetRow.modelData === root.activePreset

        width: parent.width
        icon: "adjustments"
        name: presetRow.modelData
        active: presetRow.isActive
        busy: presetRow.modelData === root.pendingPreset
        busyLabel: "LOADING"
        opacity: root.pendingPreset !== "" && !presetRow.busy ? 0.5 : 1

        onClicked: {
          if (presetRow.isActive || root.pendingPreset !== "") return
          root.selected(presetRow.modelData)
        }
      }
    }
  }
}
