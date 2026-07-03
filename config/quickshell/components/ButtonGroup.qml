import QtQuick
import QtQuick.Layouts
import "../styles"

Item {
  id: root

  default property alias content: container.data
  property int paddingX: Theme.controlPadding
  property int paddingY: Theme.controlPadding
  property bool borderEnabled: true
  property bool transparentBg: false
  property bool fillWidth: false
  property bool equalWidth: true

  implicitWidth: container.implicitWidth + root.paddingX * 2
  implicitHeight: container.implicitHeight + root.paddingY * 2

  Rectangle {
    id: bg
    anchors.fill: parent
    radius: Theme.radiusMedium
    color: transparentBg ? "transparent" : Theme.panelBackgroundSecondary
    border.width: borderEnabled ? Theme.borderWidth : 0
    border.color: Theme.border
  }

  RowLayout {
    id: container
    anchors.fill: root.fillWidth ? parent : undefined
    anchors.margins: root.fillWidth ? root.paddingX : 0
    anchors.centerIn: root.fillWidth ? undefined : parent
    spacing: Theme.spaceXs

    Component.onCompleted: {
      if (root.equalWidth) {
        for (var i = 0; i < children.length; i++) {
          var child = children[i]
          if (child.hasOwnProperty("Layout")) {
            child.Layout.fillWidth = true
          }
        }
      }
    }
  }
}