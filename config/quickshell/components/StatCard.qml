import QtQuick
import QtQuick.Layouts
import "../styles"

Surface {
  id: root

  property string label: ""
  property string value: ""
  property real barValue: 0
  property color barColor: Theme.accent
  property bool showBar: true

  radius: Theme.radiusMedium
  border.color: Theme.border

  ColumnLayout {
    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: Theme.spaceMd }
    spacing: Theme.spaceSm

    Text {
      text: root.label
      color: Theme.textDisabled
      font.pixelSize: Theme.fontSizeMicro
      font.family: Theme.fontFamilyMono
      font.letterSpacing: 0.1
    }

    Text {
      text: root.value
      color: Theme.textDisplay
      font.pixelSize: Theme.fontSizeTitle
      font.family: Theme.fontFamilyDisplay
      elide: Text.ElideRight
      maximumLineCount: 1
      Layout.fillWidth: true
    }

    ProgressBar {
      Layout.fillWidth: true
      barHeight: 3
      value: root.barValue
      barColor: root.barColor
      visible: root.showBar
    }
  }
}
