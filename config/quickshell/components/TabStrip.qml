import QtQuick
import QtQuick.Layouts
import "../core"
import "../styles"

Item {
  id: root

  property var model: []
  property int currentIndex: 0

  signal selected(int index)

  implicitHeight: 66

  Rectangle {
    anchors.fill: parent
    radius: Theme.radiusMedium
    color: Theme.backgroundSecondary
    border.width: Theme.borderWidth
    border.color: Theme.border
  }

  RowLayout {
    anchors.fill: parent
    anchors.margins: Theme.space2
    spacing: 0

    Repeater {
      model: root.model

      delegate: Item {
        id: tab
        required property var modelData
        required property int index
        readonly property bool active: index === root.currentIndex
        readonly property int count: modelData.count !== undefined ? modelData.count : -1

        Layout.fillWidth: true
        Layout.fillHeight: true

        Rectangle {
          anchors.fill: parent
          anchors.margins: Theme.space2
          radius: Theme.radiusSmall
          color: tab.active ? Theme.controlBackgroundActive : tabMa.containsMouse ? Theme.hoverOverlay : "transparent"

          Behavior on color { enabled: Theme.animationsEnabled; ColorAnimation { duration: Theme.animationFast } }
        }

        Column {
          anchors.centerIn: parent
          spacing: Theme.space2

          Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            source: Icons.get(tab.modelData.icon || "")
            size: 15
            color: tab.active ? Theme.accent : Theme.textDisabled
            visible: (tab.modelData.icon || "") !== ""

            Behavior on color { enabled: Theme.animationsEnabled; ColorAnimation { duration: Theme.animationFast } }
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: (tab.modelData.label || "").toUpperCase()
            color: tab.active ? Theme.textDisplay : Theme.textSecondary
            font.pixelSize: Theme.fontSizeMicro
            font.family: Theme.fontFamilyMono
            font.weight: tab.active ? Font.Bold : Font.Medium
            font.letterSpacing: 0.06
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            height: font.pixelSize + 1
            text: tab.count > 0 ? tab.count : ""
            color: tab.active ? Theme.accent : Theme.textDisabled
            font.pixelSize: Theme.fontSizeMicro
            font.family: Theme.fontFamilyMono
            font.weight: Font.Bold
          }
        }

        Rectangle {
          anchors.bottom: parent.bottom
          anchors.horizontalCenter: parent.horizontalCenter
          width: tab.active ? parent.width - Theme.spaceMd * 2 : 0
          height: 2
          radius: 1
          color: Theme.accent

          Behavior on width { enabled: Theme.animationsEnabled; NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }
        }

        MouseArea {
          id: tabMa
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.selected(tab.index)
        }
      }
    }
  }
}
