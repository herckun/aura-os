import QtQuick
import QtQuick.Layouts
import "../styles"

ColumnLayout {
  id: root

  property var processes: []
  property int maxItems: 5
  property string unit: "%"

  spacing: 0

  Repeater {
    model: root.processes.slice(0, root.maxItems)

    delegate: RowLayout {
      Layout.fillWidth: true
      height: 18
      spacing: Theme.spaceSm

      Rectangle {
        width: 6; height: 6; radius: Theme.radiusSmall
        color: index === 0 ? Theme.accent : Theme.border
      }

      Text {
        text: modelData.name
        color: Theme.textSecondary
        font.pixelSize: Theme.fontSizeCaption
        font.family: Theme.fontFamilyMono
        elide: Text.ElideRight
        maximumLineCount: 1
        Layout.fillWidth: true
      }

      Text {
        text: modelData.usage.toFixed(1) + root.unit
        color: Theme.textDisabled
        font.pixelSize: Theme.fontSizeCaption
        font.family: Theme.fontFamilyMono
        Layout.preferredWidth: 40
        horizontalAlignment: Text.AlignRight
      }
    }
  }
}
