import QtQuick
import "../../../styles"

Stage {
  id: root

  property Item dragLayer: null
  property string selectedId: ""
  property var modelFor: null
  property var zones: []
  property string align: "center"
  property real panelRatio: 0.74

  signal chipClicked(string pluginId, string location)
  signal dropRequested(string pluginId, string fromLocation, string toLocation, int index)

  Rectangle {
    id: panel
    width: Math.round(parent.width * root.panelRatio)
    height: panelCol.implicitHeight + Theme.spaceMd * 2
    x: root.align === "right" ? parent.width - width
     : root.align === "left" ? 0
     : Math.round((parent.width - width) / 2)
    radius: Theme.radiusLarge
    color: Qt.rgba(0, 0, 0, 0.82)
    border.width: Theme.borderWidth
    border.color: Theme.borderVisible

    Column {
      id: panelCol
      anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceMd }
      spacing: Theme.spaceSm

      Repeater {
        model: root.zones

        delegate: Column {
          id: zoneCol
          required property var modelData
          width: panelCol.width
          spacing: Theme.spaceXs

          Text {
            text: zoneCol.modelData.label
            color: Theme.textSecondary
            opacity: 0.8
            font.pixelSize: Theme.fontSizeMicro
            font.family: Theme.fontFamilyMono
            font.letterSpacing: 0.16
          }

          DropZone {
            width: parent.width
            height: implicitHeight
            location: zoneCol.modelData.location
            zoneLabel: "DROP HERE"
            vertical: zoneCol.modelData.vertical === true
            model: root.modelFor ? root.modelFor(zoneCol.modelData.location) : []
            dragLayer: root.dragLayer
            selectedId: root.selectedId
            onChipClicked: (pluginId) => root.chipClicked(pluginId, zoneCol.modelData.location)
            onDropRequested: (pluginId, fromLocation, index) => root.dropRequested(pluginId, fromLocation, zoneCol.modelData.location, index)
          }
        }
      }
    }
  }
}
