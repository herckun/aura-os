import QtQuick
import "../styles"

Item {
  id: root

  property string mod: ""
  property string key: ""
  property string desc: ""

  implicitWidth: descText.implicitWidth + Theme.spaceMd + keysRow.width
  implicitHeight: Math.max(keysRow.height, descText.implicitHeight)
  height: implicitHeight

  Text {
    id: descText
    anchors.left: parent.left
    anchors.right: keysRow.left
    anchors.rightMargin: Theme.spaceMd
    anchors.verticalCenter: parent.verticalCenter
    text: root.desc
    color: Theme.textSecondary
    font.pixelSize: Theme.fontSizeCaption
    font.family: Theme.fontFamily
    elide: Text.ElideRight
  }

  Row {
    id: keysRow
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.space2

    Repeater {
      model: root.mod.split("+")

      KeyCap {
        label: modelData
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Text {
      text: "+"
      color: Theme.textDisabled
      font.pixelSize: Theme.fontSizeMicro
      font.family: Theme.fontFamilyMono
      anchors.verticalCenter: parent.verticalCenter
    }

    KeyCap {
      label: root.key
      accent: true
      anchors.verticalCenter: parent.verticalCenter
    }
  }
}
