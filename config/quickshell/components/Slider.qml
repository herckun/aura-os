import QtQuick
import QtQuick.Controls
import Quickshell
import "../styles"

Item {
  id: root

  // ── Properties ─────────────────────────────────────────────
  property real from: 0
  property real to: 1
  property real value: 0
  property real stepSize: 0.01
  property bool live: true
  property bool interactive: true
  property color accentColor: Theme.textDisplay

  // ── Signals ────────────────────────────────────────────────
  signal moved()

  // ── Geometry ───────────────────────────────────────────────
  implicitWidth: 200
  implicitHeight: 24

  Rectangle {
    id: track
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.right: parent.right
    height: 4
    radius: Theme.radiusXs
    color: Theme.border
  }

  Rectangle {
    id: fill
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    height: 4
    radius: Theme.radiusXs
    width: track.width * ((root.value - root.from) / (root.to - root.from))
    color: root.accentColor
  }

  Rectangle {
    id: thumb
    anchors.verticalCenter: parent.verticalCenter
    x: Math.max(0, Math.min(track.width - 10, track.width * ((root.value - root.from) / (root.to - root.from)) - 5))
    width: 10
    height: 22
    radius: Theme.radiusSmall
    color: Theme.textDisplay
    visible: root.interactive
  }

  MouseArea {
    id: dragArea
    anchors.fill: parent
    enabled: root.interactive
    cursorShape: Qt.PointingHandCursor
    onPositionChanged: (mouse) => {
      if (pressed) {
        updateValue(mouse)
      }
    }
    onClicked: (mouse) => updateValue(mouse)

    function updateValue(mouse): void {
      const pos = Math.max(0, Math.min(track.width, mouse.x))
      const ratio = pos / track.width
      const val = root.from + (root.to - root.from) * ratio
      const stepped = Math.round(val / root.stepSize) * root.stepSize
      root.value = Math.max(root.from, Math.min(root.to, stepped))
      if (root.live) root.moved()
    }
  }
}
