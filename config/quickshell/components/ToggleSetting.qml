import QtQuick
import "../styles"

SettingRow {
  id: root

  property bool checked: false

  signal toggled(bool checked)

  width: parent ? parent.width : 0

  Toggle {
    anchors.verticalCenter: parent.verticalCenter
    toggleWidth: 38
    toggleHeight: 20
    checked: root.checked
    onToggled: (v) => root.toggled(v)
  }
}
