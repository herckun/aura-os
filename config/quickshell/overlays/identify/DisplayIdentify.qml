import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../styles"
import "../../core"
import "../../services"
import "../../components"

PanelWindow {
  id: win

  required property var modelData
  screen: modelData

  readonly property var mon: DisplayService.monitorByName(win.screen ? win.screen.name : "")

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell:identify"
  exclusiveZone: 0
  focusable: false
  color: "transparent"
  visible: DisplayService.identifyVisible
  mask: Region {}

  implicitWidth: col.implicitWidth + Theme.spaceXl * 2
  implicitHeight: col.implicitHeight + Theme.spaceLg * 2

  Surface {
    anchors.fill: parent
    radius: Theme.radiusLarge
    antialiasing: true
    color: Theme.panelBackground
    border.width: 2
    border.color: Theme.accent

    Column {
      id: col
      anchors.centerIn: parent
      spacing: Theme.spaceXs

      Text {
        text: win.screen ? win.screen.name.toUpperCase() : "?"
        color: Theme.accent
        font.pixelSize: Theme.fontSizeDisplay
        font.family: Theme.fontFamilyDisplay
        font.weight: Font.Bold
        anchors.horizontalCenter: parent.horizontalCenter
      }

      Text {
        text: win.mon ? (win.mon.description || win.mon.model || "") : ""
        color: Theme.textSecondary
        font.pixelSize: Theme.fontSizeCaption
        font.family: Theme.fontFamilyMono
        anchors.horizontalCenter: parent.horizontalCenter
        visible: text !== ""
      }

      Text {
        text: DisplayService.getCurrentMode(win.mon) || ""
        color: Theme.textDisabled
        font.pixelSize: Theme.fontSizeCaption
        font.family: Theme.fontFamilyMono
        anchors.horizontalCenter: parent.horizontalCenter
        visible: text !== ""
      }
    }
  }
}
