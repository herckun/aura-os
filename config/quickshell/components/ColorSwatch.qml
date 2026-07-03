import QtQuick
import QtQuick.Layouts
import "../styles"

Rectangle {
  id: root

  property string swatchColor: ""
  property string label: ""
  property bool selected: false

  signal clicked()

  implicitWidth: 60
  implicitHeight: 64
  radius: Theme.radiusMedium
  color: {
    if (root.selected) return Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.06)
    if (hoverArea.containsMouse) return Theme.controlBackgroundHover
    return Theme.backgroundSecondary
  }
  border.width: root.selected ? 2 : 1
  border.color: root.selected ? Theme.accent : Theme.border

  Behavior on color { enabled: Theme.animationsEnabled; ColorAnimation { duration: Theme.animationNormal } }
  Behavior on border.color { enabled: Theme.animationsEnabled; ColorAnimation { duration: Theme.animationNormal } }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Theme.spaceSm
    spacing: Theme.spaceXs

    Item { Layout.fillHeight: true }

    Rectangle {
      width: 28
      height: 28
      radius: Theme.radiusPill
      color: root.swatchColor
      border.width: root.selected ? 3 : 1
      border.color: root.selected ? Theme.background : Qt.rgba(1, 1, 1, 0.08)
      Layout.alignment: Qt.AlignHCenter

      Behavior on border.width { enabled: Theme.animationsEnabled; NumberAnimation { duration: Theme.animationFast } }
      Behavior on border.color { enabled: Theme.animationsEnabled; ColorAnimation { duration: Theme.animationFast } }

      Rectangle {
        anchors.centerIn: parent
        width: 16
        height: 16
        radius: Theme.radiusPill
        color: Qt.rgba(0, 0, 0, 0.5)
        opacity: root.selected ? 1 : 0
        scale: root.selected ? 1 : 0.4

        Behavior on opacity { enabled: Theme.animationsEnabled; NumberAnimation { duration: Theme.animationNormal } }
        Behavior on scale { enabled: Theme.animationsEnabled; NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutBack } }

        Canvas {
          anchors.centerIn: parent
          width: 9
          height: 9
          visible: root.selected
          property bool rootSelected: root.selected

          onRootSelectedChanged: requestPaint()

          onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.strokeStyle = Theme.textDisplay
            ctx.lineWidth = 1.8
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            ctx.beginPath()
            ctx.moveTo(1.8, 5)
            ctx.lineTo(3.8, 7)
            ctx.lineTo(7.5, 2.5)
            ctx.stroke()
          }
        }
      }
    }

    Text {
      text: root.label
      color: root.selected ? Theme.textDisplay : Theme.textSecondary
      font.pixelSize: Theme.fontSizeMicro
      font.family: Theme.fontFamilyMono
      font.letterSpacing: 0.04
      font.weight: root.selected ? Font.DemiBold : Font.Normal
      Layout.alignment: Qt.AlignHCenter
      visible: root.label !== ""

      Behavior on color { enabled: Theme.animationsEnabled; ColorAnimation { duration: Theme.animationNormal } }
    }

    Item { Layout.fillHeight: true }
  }

  MouseArea {
    id: hoverArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
