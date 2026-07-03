import QtQuick
import QtQuick.Layouts
import "../styles"

ColumnLayout {
  id: root

  // ── Content ────────────────────────────────────────────────
  property string label: ""
  property string value: ""
  property real fraction: 0
  property bool showBar: true
  default property alias footer: footerHolder.data

  // ── Styling ────────────────────────────────────────────────
  property real scale: 1.0
  property color labelColor: Theme.textSecondary
  property color valueColor: Theme.textPrimary
  property color barColor: Theme.accent
  property color trackColor: Theme.border
  property int valueFontSize: Theme.fontSizeHeading
  property real labelLetterSpacing: 2

  spacing: Math.round(Theme.spaceXxs * scale)

  RowLayout {
    Layout.fillWidth: true

    Text {
      text: root.label
      color: root.labelColor
      font.family: Theme.fontFamilyMono
      font.pixelSize: Math.round(Theme.fontSizeMicro * root.scale)
      font.weight: Font.Medium
      font.letterSpacing: root.labelLetterSpacing
    }

    Item { Layout.fillWidth: true }

    Text {
      text: root.value
      color: root.valueColor
      font.family: Theme.fontFamilyMono
      font.pixelSize: Math.round(root.valueFontSize * root.scale)
      font.weight: Font.Bold
    }
  }

  ProgressBar {
    Layout.fillWidth: true
    visible: root.showBar
    barHeight: Math.round(4 * root.scale)
    value: root.fraction
    barColor: root.barColor
    trackColor: root.trackColor
  }

  ColumnLayout {
    id: footerHolder
    Layout.fillWidth: true
    spacing: 0
  }
}
