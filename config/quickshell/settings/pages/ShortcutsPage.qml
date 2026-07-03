import QtQuick
import QtQuick.Layouts
import "../../styles"
import "../../services"
import "../../components"

ColumnLayout {
  id: root
  spacing: Theme.spaceLg
  width: parent.width

  Text {
    text: "SHORTCUTS"
    color: Theme.textDisplay
    font.pixelSize: Theme.fontSizeHeading
    font.family: Theme.fontFamilyDisplay
    font.letterSpacing: 2
  }

  Card {
    Layout.fillWidth: true
    title: "KEYBOARD LAYOUT"
    InfoRow {
      label: "ACTIVE"
      value: HyprlandKeyboardService.layout || "UNKNOWN"
    }
  }

  Card {
    Layout.fillWidth: true
    title: "WINDOW MANAGEMENT"
    Column {
      width: parent.width
      spacing: Theme.spaceSm
      InfoRow { label: "SUPER + W"; value: "CLOSE WINDOW" }
      InfoRow { label: "SUPER + F"; value: "TOGGLE FLOATING" }
      InfoRow { label: "SUPER + M"; value: "FULLSCREEN" }
      InfoRow { label: "SUPER + Q"; value: "KILL WINDOW" }
    }
  }

  Card {
    Layout.fillWidth: true
    title: "NAVIGATION"
    Column {
      width: parent.width
      spacing: Theme.spaceSm
      InfoRow { label: "SUPER + H/J/K/L"; value: "MOVE FOCUS" }
      InfoRow { label: "SUPER + SHIFT + H/J/K/L"; value: "MOVE WINDOW" }
      InfoRow { label: "SUPER + CTRL + H/J/K/L"; value: "RESIZE WINDOW" }
    }
  }

  Card {
    Layout.fillWidth: true
    title: "SHELL"
    Column {
      width: parent.width
      spacing: Theme.spaceSm
      InfoRow { label: "SUPER + SPACE"; value: "LAUNCHER" }
      InfoRow { label: "SUPER + TAB"; value: "OVERVIEW" }
      InfoRow { label: "SUPER + ."; value: "CONTROL CENTER" }
      InfoRow { label: "SUPER + /"; value: "KEYBIND CHEATSHEET" }
      InfoRow { label: "SUPER + ,"; value: "SETTINGS" }
    }
  }

  Card {
    Layout.fillWidth: true
    title: "WORKSPACES"
    Column {
      width: parent.width
      spacing: Theme.spaceSm
      InfoRow { label: "SUPER + 1-9"; value: "SWITCH WORKSPACE" }
      InfoRow { label: "SUPER + ALT + 1-9"; value: "MOVE TO WORKSPACE" }
    }
  }

  Item { Layout.fillHeight: true }
}
