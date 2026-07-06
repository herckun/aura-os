import QtQuick
import QtQuick.Layouts
import "../../../styles"

Stage {
  id: root

  property Item dragLayer: null
  property string selectedId: ""
  property var modelFor: null

  signal chipClicked(string pluginId, string location)
  signal dropRequested(string pluginId, string fromLocation, string toLocation, int index)

  Column {
    width: parent.width
    spacing: Theme.spaceXs

    Rectangle {
      width: parent.width
      height: zonesRow.implicitHeight + Theme.spaceXs * 2
      radius: Theme.radiusMedium
      color: Theme.panelBackground
      border.width: Theme.borderWidth
      border.color: Theme.borderVisible

      RowLayout {
        id: zonesRow
        anchors.fill: parent
        anchors.margins: Theme.spaceXs
        spacing: Theme.spaceXs

        Repeater {
          model: ["bar_left", "bar_center", "bar_right"]

          delegate: DropZone {
            required property string modelData
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            location: modelData
            zoneLabel: "DROP HERE"
            bare: true
            centered: true
            model: root.modelFor ? root.modelFor(modelData) : []
            dragLayer: root.dragLayer
            selectedId: root.selectedId
            onChipClicked: (pluginId) => root.chipClicked(pluginId, modelData)
            onDropRequested: (pluginId, fromLocation, index) => root.dropRequested(pluginId, fromLocation, modelData, index)
          }
        }
      }
    }

    RowLayout {
      width: parent.width
      spacing: Theme.spaceXs

      Repeater {
        model: ["LEFT", "CENTER", "RIGHT"]

        delegate: Text {
          required property string modelData
          Layout.fillWidth: true
          Layout.preferredWidth: 1
          text: modelData
          horizontalAlignment: Text.AlignHCenter
          color: Theme.textSecondary
          opacity: 0.8
          font.pixelSize: Theme.fontSizeMicro
          font.family: Theme.fontFamilyMono
          font.letterSpacing: 0.16
        }
      }
    }

    Item { width: 1; height: Theme.spaceLg }
  }
}
