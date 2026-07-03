import QtQuick
import QtQuick.Layouts
import "../styles"
import "../core"
import "../components"

Rectangle {
  id: root

  property string icon: ""
  property string name: ""
  property string subtitle: ""
  property bool active: false
  property bool showToggle: false
  property bool toggleChecked: false
  property string actionLabel: ""
  property bool showAction: false
  property bool busy: false
  property string busyLabel: "CONNECTING"

  signal clicked()
  signal toggled(bool checked)
  signal actionClicked()

  height: Theme.controlHeight + Theme.spaceSm
  radius: Theme.radiusSmall
  color: hoverArea.containsMouse ? Theme.controlBackgroundHover : "transparent"

  MouseArea {
    id: hoverArea
    anchors.fill: parent
    hoverEnabled: true
    z: -1
    onClicked: root.clicked()
  }

  RowLayout {
    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: Theme.spaceSm }
    spacing: Theme.spaceSm

    Icon {
      source: Icons.get(root.icon)
      size: 11
      color: root.active ? Theme.accent : Theme.textSecondary
    }

    Column {
      Layout.fillWidth: true
      spacing: Theme.spaceXxs

      Text {
        width: parent.width
        text: root.name
        color: root.active ? Theme.accent : Theme.textPrimary
        font.pixelSize: Theme.fontSizeCaption
        font.family: Theme.fontFamilyMono
        elide: Text.ElideRight
      }

      Text {
        visible: root.subtitle !== ""
        text: root.subtitle
        color: Theme.textDisabled
        font.pixelSize: Theme.fontSizeMicro
        font.family: Theme.fontFamilyMono
        font.letterSpacing: 0.04
      }
    }

    Text {
      visible: root.active && !root.showToggle && !root.showAction && !root.busy
      text: "ACTIVE"
      color: Theme.accent
      font.pixelSize: Theme.fontSizeMicro
      font.family: Theme.fontFamilyMono
      font.letterSpacing: 0.06
    }

    RowLayout {
      visible: root.busy
      spacing: Theme.spaceXs
      Layout.alignment: Qt.AlignVCenter

      Spinner {
        spinnerSize: 12
        spinnerColor: Theme.accent
        Layout.alignment: Qt.AlignVCenter
      }

      Text {
        text: root.busyLabel
        color: Theme.accent
        font.pixelSize: Theme.fontSizeMicro
        font.family: Theme.fontFamilyMono
        font.letterSpacing: 0.06
        Layout.alignment: Qt.AlignVCenter
      }
    }

    Button {
      visible: root.showAction && !root.busy
      text: root.actionLabel
      size: "sm"
      onClicked: root.actionClicked()
    }

    Toggle {
      visible: root.showToggle
      Layout.alignment: Qt.AlignVCenter
      toggleWidth: 28
      toggleHeight: 16
      checked: root.toggleChecked
      onToggled: (v) => root.toggled(v)
    }
  }
}
