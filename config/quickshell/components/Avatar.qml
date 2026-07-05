import QtQuick
import Qt5Compat.GraphicalEffects
import "../styles"

Item {
  id: root

  property int size: 40
  property string source: ""
  property string fallbackText: "?"
  property color ringColor: Theme.borderVisible

  readonly property bool _hasImage: source !== "" && img.status === Image.Ready

  width: size
  height: size

  Rectangle {
    anchors.fill: parent
    radius: root.size / 2
    color: Theme.controlBackground
    border.width: Theme.borderWidth
    border.color: root.ringColor
  }

  Text {
    anchors.centerIn: parent
    text: root.fallbackText
    color: Theme.accent
    font.pixelSize: Math.round(root.size * 0.42)
    font.family: Theme.fontFamilyDisplay
    font.weight: Font.Bold
    visible: !root._hasImage
  }

  Image {
    id: img
    anchors.fill: parent
    anchors.margins: 1
    source: root.source
    sourceSize.width: root.size * 2
    sourceSize.height: root.size * 2
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: false
    visible: false
  }

  Rectangle {
    id: mask
    anchors.fill: img
    radius: root.size / 2
    visible: false
  }

  OpacityMask {
    anchors.fill: img
    source: img
    maskSource: mask
    visible: root._hasImage
  }
}
