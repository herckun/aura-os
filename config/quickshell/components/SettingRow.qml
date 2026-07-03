import QtQuick
import QtQuick.Layouts
import "../styles"

RowLayout {
  id: root

  property string label: ""
  property string description: ""
  property string _loc: ""
  default property alias control: controlArea.data

  property int _labelSize: Theme.fontSizeLabel
  property int _descSize: Theme.fontSizeCaption

  width: parent.width
  height: Math.max(Theme.controlHeight + Theme.spaceSm, labelCol.implicitHeight + Theme.spaceMd * 2)
  spacing: Theme.spaceSm

  // ── Label + Description ───────────────────────────────────────────
  Column {
    id: labelCol
    Layout.fillWidth: true
    spacing: Theme.spaceXs

    Text {
      text: root.label
      color: Theme.textPrimary
      font.pixelSize: root._labelSize
      font.family: Theme.fontFamilyMono
      font.weight: Font.Medium
      font.letterSpacing: 0.06
    }

    Text {
      visible: root.description !== ""
      width: parent.width
      text: root.description
      color: Theme.textDisabled
      font.pixelSize: root._descSize
      font.family: Theme.fontFamilyMono
      font.letterSpacing: 0.04
      wrapMode: Text.WordWrap
    }
  }

  // ── Control Area ──────────────────────────────────────────────────
  Item {
    id: controlArea
    Layout.alignment: Qt.AlignVCenter
    Layout.preferredWidth: childrenRect.width
    Layout.preferredHeight: childrenRect.height
  }
}
