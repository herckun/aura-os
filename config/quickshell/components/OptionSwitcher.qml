import QtQuick
import QtQuick.Layouts
import "../styles"

RowLayout {
  id: root

  property var options: []
  property int currentIndex: 0
  property string variant: "accent"
  property color selectedColor: "transparent"
  property color selectedTextColor: "transparent"
  property string size: "md"
  property int controlHeight: size === "xs" ? Theme.controlHeightSmall - 4 : size === "sm" ? Theme.controlHeightSmall : Theme.controlHeight
  property int controlFontSize: size === "xs" ? Theme.fontSizeMicro : size === "sm" ? Theme.fontSizeCaption : Theme.fontSizeLabel
  property int controlPadding: size === "xs" ? Theme.spaceXs : size === "sm" ? Theme.spaceSm : Theme.spaceMd
  property string currentOption: currentIndex >= 0 && currentIndex < options.length ? options[currentIndex] : ""

  signal selected(int index)

  readonly property color _sc: selectedColor.a > 0 ? selectedColor : Theme.variantColor(variant)

  readonly property color _st: selectedTextColor.a > 0 ? selectedTextColor :
    Theme.contrastTextColor(_sc)

  property int _maxContentWidth: 0

  function _remeasure(): void {
    var max = 0
    for (var i = 0; i < options.length; i++) {
      _measureText.text = options[i].toUpperCase()
      if (_measureText.width > max) max = _measureText.width
    }
    _maxContentWidth = Math.ceil(max + controlPadding * 2 + 8)
  }

  onOptionsChanged: _remeasure()
  onControlFontSizeChanged: _remeasure()
  Component.onCompleted: _remeasure()

  Text {
    id: _measureText
    visible: false
    font.pixelSize: controlFontSize
    font.family: Theme.fontFamilyMono
    font.weight: Font.Medium
  }

  spacing: Theme.spaceXs

  Repeater {
    model: root.options

    delegate: Button {
      required property string modelData
      required property int index

      shape: "default"
      size: root.size
      Layout.fillWidth: true
      Layout.minimumWidth: root._maxContentWidth
      buttonHeight: root.controlHeight
      fontSize: root.controlFontSize
      padding: root.controlPadding
      text: modelData
      active: index === root.currentIndex
      bgColor: index === root.currentIndex ? root._sc : Theme.backgroundTertiary
      bgHoverColor: Theme.controlBackgroundHover
      color: index === root.currentIndex ? root._st : Theme.textSecondary
      hoverEffect: true
      onClicked: root.selected(index)
    }
  }
}
