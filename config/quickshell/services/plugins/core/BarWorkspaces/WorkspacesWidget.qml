import QtQuick
import Quickshell
import "../../../../services"
import "../../../../styles"

Item {
  id: root

  readonly property var ws: HyprlandService.workspaces
  readonly property int activeId: HyprlandService.activeWsId

  implicitWidth: dotsRow.width
  implicitHeight: 30

  Row {
    id: dotsRow
    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.spaceXs + 2

    Repeater {
      model: ws ? ws.length : 0

      delegate: Item {
        width: 8
        height: 8
        readonly property var w: ws[index]
        readonly property bool active: w && w.id === root.activeId
        readonly property bool occupied: w && w.windows > 0

        Rectangle {
          anchors.centerIn: parent
          width: active ? 8 : 5
          height: active ? 8 : 5
          radius: Theme.radiusXs
          antialiasing: true
          color: active ? Theme.textDisplay : (occupied ? Theme.textSecondary : Theme.border)

          Behavior on color {
            enabled: Theme.animationsEnabled
            ColorAnimation { duration: Theme.animationFast }
          }
          Behavior on width {
            enabled: Theme.animationsEnabled
            NumberAnimation { duration: Theme.animationFast }
          }
          Behavior on height {
            enabled: Theme.animationsEnabled
            NumberAnimation { duration: Theme.animationFast }
          }
        }

        MouseArea {
          anchors.fill: parent
          anchors.margins: -4
          cursorShape: Qt.PointingHandCursor
          onClicked: { if (w) HyprlandService.setWorkspace(w.id) }
        }
      }
    }
  }
}