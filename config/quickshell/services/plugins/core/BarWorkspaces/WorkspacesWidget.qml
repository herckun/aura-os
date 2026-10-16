import QtQuick
import Quickshell
import "../../../../services"
import "../../../../styles"

Item {
  id: root

  readonly property var ws: HyprlandService.workspaces
  readonly property int activeId: HyprlandService.activeWsId

  readonly property var _regularWs: {
    if (!ws) return []
    var result = []
    for (var i = 0; i < ws.length; i++) {
      if (ws[i].id >= 0) result.push(ws[i])
    }
    return result
  }

  readonly property var _specialVisible: {
    if (!ws) return []
    var result = []
    for (var i = 0; i < ws.length; i++) {
      if (ws[i].id < 0 && (ws[i].id === activeId || ws[i].windows > 0))
        result.push(ws[i])
    }
    return result
  }

  implicitWidth: dotsRow.width + specialRow.width + (dotsRow.width > 0 && specialRow.width > 0 ? Theme.spaceXs + 2 : 0)
  implicitHeight: 30

  Row {
    id: dotsRow
    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.spaceXs + 2

    Repeater {
      model: root._regularWs.length

      delegate: Item {
        width: 8
        height: 8
        readonly property var w: root._regularWs[index]
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

  Row {
    id: specialRow
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: dotsRow.right
    anchors.leftMargin: dotsRow.width > 0 ? Theme.spaceXs + 2 : 0
    spacing: Theme.spaceXs + 2

    Repeater {
      model: root._specialVisible.length

      delegate: Item {
        width: 14
        height: 14
        readonly property var w: root._specialVisible[index]
        readonly property bool active: w && w.id === HyprlandService.activeSpecialWsId

        Rectangle {
          anchors.centerIn: parent
          width: active ? 14 : 10
          height: active ? 14 : 10
          radius: Theme.radiusXs
          antialiasing: true
          color: "transparent"
          border.width: 1
          border.color: active ? Theme.accent : Theme.textSecondary

          Behavior on width { enabled: Theme.animationsEnabled; NumberAnimation { duration: Theme.animationFast } }
          Behavior on height { enabled: Theme.animationsEnabled; NumberAnimation { duration: Theme.animationFast } }
          Behavior on border.color { enabled: Theme.animationsEnabled; ColorAnimation { duration: Theme.animationFast } }
        }

        Text {
          anchors.centerIn: parent
          anchors.verticalCenterOffset: 1
          text: "\u2605"
          font.pixelSize: active ? 9 : 7
          color: active ? Theme.accent : Theme.textSecondary

          Behavior on font.pixelSize { enabled: Theme.animationsEnabled; NumberAnimation { duration: Theme.animationFast } }
          Behavior on color { enabled: Theme.animationsEnabled; ColorAnimation { duration: Theme.animationFast } }
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
