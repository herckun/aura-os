import QtQuick
import "../styles"

Rectangle {
  id: root

  property string text: ""
  property string variant: "accent"
  property color textColor: "transparent"
  property color bgColor: "transparent"
  property variant size: "sm"
  property bool small: size === "xs" || size === "sm"
  property int fontSize: _sizePreset.fontSize
  property int padding: _sizePreset.padding
  property int paddingX: -1
  property int paddingY: -1
  property Component contentItem: null

  readonly property var _sizePreset: {
    if (typeof size === "number") return { fontSize: Theme.fontSizeCaption, padding: Theme.spaceSm }
    var presets = Theme.sizePresets
    var p = presets[size] || presets["sm"] || { fontSize: Theme.fontSizeMicro, padding: 6 }
    return { fontSize: p.fontSize, padding: p.padding }
  }

  readonly property color _vb: variant === "accent" ? Theme.accent :
    variant === "default" ? Theme.backgroundTertiary :
    variant === "error" ? Theme.error :
    variant === "success" ? Theme.success :
    variant === "warning" ? Theme.warning : Theme.backgroundTertiary

  readonly property color _fb: bgColor.a > 0 ? bgColor : _vb
  readonly property color _ft: textColor.a > 0 ? textColor : Theme.contrastTextColor(_fb)

  implicitWidth: {
    var px = paddingX >= 0 ? paddingX : padding
    if (contentItem && customContent.item) {
      return Math.max(customContent.item.implicitWidth + px * 2, 28)
    }
    return Math.max(label.implicitWidth + px * 2, 28)
  }
  implicitHeight: {
    var py = paddingY >= 0 ? paddingY : padding
    if (contentItem && customContent.item) {
      return Math.max(customContent.item.implicitHeight + py * 2, 20)
    }
    return Math.max(label.implicitHeight + py * 2, 20)
  }
  width: implicitWidth
  height: implicitHeight
  radius: Theme.radiusMedium
  antialiasing: true
  color: _fb
  border.width: variant === "default" ? (size === "xs" ? 0 : Theme.borderWidth) : 0
  border.color: Theme.border

  scale: 0.8
  opacity: 0
  Component.onCompleted: {
    scale = 1.0
    opacity = 1.0
  }

  Behavior on scale {
    enabled: Theme.animationsEnabled
    NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutBack }
  }
  Behavior on opacity {
    enabled: Theme.animationsEnabled
    NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutQuad }
  }

  Text {
    id: label
    anchors.centerIn: parent
    text: root.text.toUpperCase()
    color: _ft
    font.pixelSize: root.fontSize
    font.family: Theme.fontFamilyMono
    font.weight: Font.Medium
    font.letterSpacing: 0.08
    visible: !root.contentItem
  }

  Loader {
    id: customContent
    anchors.centerIn: parent
    sourceComponent: root.contentItem
    visible: root.contentItem !== null

    onLoaded: {
      if (customContent.item && customContent.item.hasOwnProperty('color')) {
        customContent.item.color = _ft
      }
    }
  }

  Connections {
    target: root
    function on_FtChanged() {
      if (customContent.item && customContent.item.hasOwnProperty('color')) {
        customContent.item.color = customContent.item._ft || root._ft
      }
    }
  }

}
