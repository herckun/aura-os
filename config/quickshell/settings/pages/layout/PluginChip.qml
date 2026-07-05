import QtQuick
import QtQuick.Layouts
import "../../../core"
import "../../../styles"
import "../../../components"

Item {
  id: root

  property string pluginId: ""
  property string fromLocation: ""
  property string label: ""
  property string icon: "cpu"
  property bool selected: false
  property bool dimmed: false
  property bool fill: false
  property bool draggable: true
  property Item dragLayer: null

  signal clicked()

  readonly property bool dragging: ma.drag.active
  property real _pressWidth: 0

  width: dragging ? 0 : fill ? (parent ? parent.width : body.implicitWidth) : body.width
  height: dragging ? 0 : 30

  Rectangle {
    id: body
    width: root.fill ? (root.dragging ? root._pressWidth : root.width) : chipRow.implicitWidth + Theme.spaceSm * 2
    height: 30
    radius: Theme.radiusSmall
    color: root.selected ? Theme.accent
         : ma.drag.active ? Theme.controlBackgroundPressed
         : ma.containsMouse ? Theme.controlBackgroundHover
         : root.dimmed ? Theme.controlBackground : Theme.backgroundTertiary
    border.width: Theme.borderWidth
    border.color: ma.drag.active ? Theme.accent
                : root.selected ? Theme.accent
                : ma.containsMouse ? Theme.borderActive : Theme.borderVisible
    opacity: ma.drag.active ? 0.92 : root.dimmed ? 0.55 : 1
    z: ma.drag.active ? 100 : 0

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter

    Drag.active: ma.drag.active
    Drag.source: root
    Drag.keys: ["plugin"]
    Drag.hotSpot.x: width / 2
    Drag.hotSpot.y: height / 2

    RowLayout {
      id: chipRow
      anchors.fill: parent
      anchors.leftMargin: Theme.spaceSm
      anchors.rightMargin: Theme.spaceSm
      spacing: Theme.spaceXs

      Icon {
        source: Icons.get(root.icon)
        size: 13
        color: root.selected ? Theme.contrastTextColor(Theme.accent)
             : root.dimmed ? Theme.textDisabled : Theme.textSecondary
      }

      Text {
        Layout.fillWidth: root.fill
        text: root.label.toUpperCase()
        color: root.selected ? Theme.contrastTextColor(Theme.accent)
             : root.dimmed ? Theme.textDisabled : Theme.textPrimary
        font.pixelSize: Theme.fontSizeMicro
        font.family: Theme.fontFamilyMono
        font.weight: Font.Bold
        font.letterSpacing: 0.06
        elide: Text.ElideRight
      }

      Icon {
        source: Icons.get("dots-six-vertical")
        size: 12
        color: root.selected ? Theme.contrastTextColor(Theme.accent) : Theme.textDisabled
        visible: root.fill && root.draggable
      }
    }

    states: State {
      when: ma.drag.active
      ParentChange { target: body; parent: root.dragLayer ? root.dragLayer : root }
      AnchorChanges {
        target: body
        anchors.horizontalCenter: undefined
        anchors.verticalCenter: undefined
      }
    }
  }

  MouseArea {
    id: ma
    anchors.fill: parent
    hoverEnabled: true
    preventStealing: true
    cursorShape: drag.active ? Qt.ClosedHandCursor
               : root.draggable ? Qt.OpenHandCursor : Qt.PointingHandCursor
    drag.target: root.draggable ? body : undefined
    drag.threshold: 6
    onPressed: root._pressWidth = body.width
    onClicked: root.clicked()
    onReleased: if (drag.active) body.Drag.drop()
  }
}
