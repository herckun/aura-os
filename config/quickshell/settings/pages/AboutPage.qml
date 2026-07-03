import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../styles"
import "../../core"
import "../../services"
import "../../components"

ColumnLayout {
  id: root
  spacing: Theme.spaceLg
  width: parent.width

  PageHeader { title: "ABOUT" }

  Card {
    Layout.fillWidth: true
    title: "SYSTEM"
    
    Column {
      width: parent.width
      spacing: Theme.spaceSm

      InfoRow { label: "OS"; value: AppInfo.displayName + " v" + AppInfo.version }
      InfoRow { label: "SHELL"; value: "QUICKSHELL / QML" }
      InfoRow { label: "WM"; value: "HYPRLAND" }
    }
  }

  CreditsSection {}

  Text {
    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
    text: AppInfo.displayName + " v" + AppInfo.version
    color: Theme.textDisabled
    font.pixelSize: Theme.fontSizeMicro
    font.family: Theme.fontFamilyMono
    font.letterSpacing: 2
  }

  Item { Layout.fillHeight: true }
}
