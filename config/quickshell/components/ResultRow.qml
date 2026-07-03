import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import "../styles"
import "../core"

Rectangle {
  id: root

  property var result: ({})
  property bool selected: false
  property bool showSource: true

  signal clicked()
  signal hovered()

  implicitHeight: 46
  height: implicitHeight
  radius: Theme.radiusMedium
  color: root.selected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14)
       : rowMouse.containsMouse ? Theme.controlBackgroundHover : "transparent"

  Behavior on color {
    enabled: Theme.animationsEnabled
    ColorAnimation { duration: Theme.animationFast }
  }

  Rectangle {
    anchors.left: parent.left
    anchors.leftMargin: Theme.spaceXs
    anchors.verticalCenter: parent.verticalCenter
    width: 3
    height: parent.height * 0.5
    radius: Theme.radiusPill
    color: Theme.accent
    visible: root.selected
  }

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: Theme.spaceMd
    anchors.rightMargin: Theme.spaceMd
    spacing: Theme.spaceSm

    Surface {
      Layout.preferredWidth: 30
      Layout.preferredHeight: 30
      radius: Theme.radiusSmall
      bordered: false
      color: root.selected ? "transparent" : Theme.controlBackground
      clip: true

      IconImage {
        id: appIcon
        anchors.centerIn: parent
        width: 20; height: 20
        source: (root.result.iconKind === "app" && root.result.icon)
                ? "image://icon/" + root.result.icon : ""
        visible: root.result.iconKind === "app" && status === Image.Ready
      }
      Icon {
        id: urlIcon
        anchors.centerIn: parent
        size: 18
        byPassColorOverlay: true
        source: (root.result.iconKind === "image" && root.result.icon)
                ? root.result.icon : ""
        visible: root.result.iconKind === "image" && status === Image.Ready
      }
      Icon {
        id: symIcon
        anchors.centerIn: parent
        size: 18
        color: root.selected ? Theme.accent : Theme.textSecondary
        // symbolic kind → the icon itself; image kind → the fallback while the image loads/fails
        source: root.result.iconKind === "image"
                ? (!urlIcon.visible && root.result.iconFallback ? Icons.get(root.result.iconFallback) : "")
                : (root.result.iconKind !== "app" && root.result.icon ? Icons.get(root.result.icon) : "")
        visible: source !== ""
      }
      Grid {
        anchors.centerIn: parent
        columns: 3
        spacing: Theme.space2
        visible: !appIcon.visible && !urlIcon.visible && !symIcon.visible
        Repeater {
          model: 9
          Rectangle {
            required property int index
            width: 4; height: 4
            radius: Theme.radiusXs
            color: index === 4 ? Theme.textSecondary : Theme.border
          }
        }
      }
    }

    Column {
      Layout.fillWidth: true
      spacing: 0
      Text {
        width: parent.width
        text: root.result.label || ""
        color: root.selected ? Theme.textDisplay : Theme.textPrimary
        font.pixelSize: Theme.fontSizeSubhead
        font.family: Theme.fontFamily
        font.weight: root.selected ? Font.DemiBold : Font.Normal
        elide: Text.ElideRight
      }
      Text {
        width: parent.width
        text: root.result.sublabel || ""
        visible: !!root.result.sublabel
        color: Theme.textDisabled
        font.pixelSize: Theme.fontSizeCaption
        font.family: Theme.fontFamilyMono
        elide: Text.ElideRight
      }
    }

    Tag {
      visible: root.showSource && root.result.source && root.result.source !== "apps"
      Layout.alignment: Qt.AlignVCenter
      label: root.result.source || ""
    }

    Text {
      visible: root.selected
      Layout.alignment: Qt.AlignVCenter
      text: "↵"
      color: Theme.accent
      font.pixelSize: Theme.fontSizeBody
      font.family: Theme.fontFamilyMono
    }
  }

  MouseArea {
    id: rowMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onEntered: root.hovered()
    onClicked: root.clicked()
  }
}
