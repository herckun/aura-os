import QtQuick
import QtQuick.Layouts
import "../styles"
import "../core"

Rectangle {
  id: root

  property string icon: ""
  property string label: ""
  property string detail: ""
  property bool danger: false

  signal clicked()

  width: parent ? parent.width : implicitWidth
  height: 32
  radius: Theme.radiusSmall
  antialiasing: true
  color: ma.containsMouse
    ? (danger ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : Theme.controlBackgroundHover)
    : "transparent"

  Behavior on color { enabled: Theme.animationsEnabled; ColorAnimation { duration: Theme.animationFast } }

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: Theme.spaceSm
    anchors.rightMargin: Theme.spaceSm
    spacing: Theme.spaceSm

    Icon {
      source: Icons.get(root.icon)
      size: 14
      color: root.danger ? Theme.error : (ma.containsMouse ? Theme.textPrimary : Theme.textSecondary)
      visible: root.icon !== ""

      Behavior on color { enabled: Theme.animationsEnabled; ColorAnimation { duration: Theme.animationFast } }
    }

    Text {
      Layout.fillWidth: true
      text: root.label
      color: root.danger ? Theme.error : (ma.containsMouse ? Theme.textPrimary : Theme.textSecondary)
      font.pixelSize: Theme.fontSizeCaption
      font.family: Theme.fontFamilyMono
      font.weight: Font.DemiBold
      font.letterSpacing: 0.08
      elide: Text.ElideRight

      Behavior on color { enabled: Theme.animationsEnabled; ColorAnimation { duration: Theme.animationFast } }
    }

    Text {
      text: root.detail
      visible: root.detail !== ""
      color: Theme.textDisabled
      font.pixelSize: Theme.fontSizeMicro
      font.family: Theme.fontFamilyMono
      font.letterSpacing: 0.04
    }
  }

  MouseArea {
    id: ma
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
