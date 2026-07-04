import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import "../styles"
import "../core"
import "../services"

Item {
  id: root

  // ── Properties ─────────────────────────────────────────────
  property string shape: "default"

  property string actionId: ""
  property bool busy: false
  property int busyTimeout: 35000
  property string icon: ""
  property string text: ""
  property bool hoverEffect: true
  property alias label: root.text

  property string variant: "default"
  property variant size: "md"
  property bool small: size === "sm" || size === "xs"
  property int fontSize: _sizePreset.fontSize
  property color color: shape === "icon" ? Theme.textPrimary : "transparent"
  property color hoverColor: shape === "icon" ? Theme.controlBackgroundHover : "transparent"
  property color bgColor: shape === "circle" ? Theme.controlBackground : "transparent"
  property color bgHoverColor: "transparent"
  property color bgPressedColor: "transparent"

  property color iconColor: Theme.textDisplay
  property int sizeDim: _sizePreset.dim
  property int buttonWidth: sizeDim
  property int buttonHeight: sizeDim
  property int iconSize: _sizePreset.iconSize
  property string labelFontFamily: Theme.fontFamilyMono

  property int radius: shape === "tile" ? Theme.radiusMedium : shape === "icon" ? Theme.radiusSmall : Theme.radiusMedium
  property color pressedColor: Theme.controlBackgroundPressed
  property int bgRadius: Theme.radiusSmall
  property bool showBackground: false
  property bool active: false
  property alias tooltip: tooltipLabel.text
  property bool labelCaps: false
  property color overlayColor: _isDefaultShape && _isAccent ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.85) :
    shape === "tile" && active ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.85) :
    Theme.panelBackgroundSecondary

  // ── Internal state ─────────────────────────────────────────
  readonly property var _sizePreset: {
    if (typeof size === "number") return { fontSize: Theme.fontSizeLabel, iconSize: 14, dim: size, padding: Theme.spaceMd }
    var presets = Theme.sizePresets
    var p = presets[size] || presets["md"] || { fontSize: Theme.fontSizeLabel, iconSize: 14, dim: 28, padding: Theme.spaceMd }
    return { fontSize: p.fontSize, iconSize: p.iconSize, dim: p.dim, padding: p.padding }
  }

  // ── Signals ────────────────────────────────────────────────
  signal clicked()
  signal rightClicked()

  onBusyChanged: {
    if (busy && busyTimeout > 0)
      _busyFailsafe.restart()
    else
      _busyFailsafe.stop()
  }

  Timer {
    id: _busyFailsafe
    interval: root.busyTimeout
    repeat: false
    onTriggered: {
      if (root.busy) {
        if (root.actionId === "" || !ProcessPool.isBusy(root.actionId))
          root.busy = false
        else
          restart()
      }
    }
  }

  Connections {
    target: ProcessPool
    enabled: root.actionId !== ""
    function onBusyChanged(id: string, active: bool): void {
      if (id === root.actionId) {
        root.busy = active
      }
    }
  }

  readonly property string _v: variant
  readonly property bool _isAccent: _v === "accent"
  readonly property bool _isDefault: _v === "default"
  readonly property bool _isHovered: mouseArea.containsMouse
  readonly property bool _isPressed: mouseArea.pressed
  readonly property bool _isDefaultShape: shape === "default"
  readonly property bool _isFlat: shape === "link" || shape === "icon"
  readonly property bool _hasIcon: icon !== ""

  readonly property color _ft: Theme.contrastTextColor(_bgColor)
  readonly property color _fh: Theme.contrastTextColor(_fbh)
  readonly property color _fb: bgColor.a > 0 ? bgColor :
    _isAccent ? Theme.accent : Theme.backgroundTertiary
  readonly property color _fbh: bgHoverColor.a > 0 ? bgHoverColor :
    _isAccent ? Qt.lighter(Theme.accent, 1.08) : Theme.controlBackgroundHover
  readonly property color _fbp: bgPressedColor.a > 0 ? bgPressedColor :
    _isAccent ? Qt.darker(Theme.accent, 1.15) : Theme.controlBackgroundPressed

  property bool fillWidth: false

  // ── Geometry ───────────────────────────────────────────────
  width: {
    if (fillWidth) return -1
    if (shape === "circle" || shape === "icon") return buttonWidth
    if (shape === "tile") return Math.max(80, _tileColumn.implicitWidth + Theme.spaceSm * 2)
    if (shape === "link") return _linkLabel.implicitWidth
    var cw = _hasIcon ? (_defaultIcon.width + Theme.spaceXs + _defaultLabel.width) : _defaultLabel.width
    var px = paddingX >= 0 ? paddingX : padding
    return Math.max(cw + px * 2, buttonHeight * 1.4)
  }

  height: {
    if (shape === "circle" || shape === "icon") return buttonHeight
    if (shape === "tile") return Math.max(60, _tileColumn.implicitHeight + Theme.spaceSm * 2)
    if (shape === "link") return buttonHeight
    var py = paddingY >= 0 ? paddingY : padding
    return Math.max(_defaultLabel.height + py * 2, buttonHeight)
  }
  implicitWidth: width
  implicitHeight: height

  property int padding: _sizePreset.padding
  property int paddingX: -1
  property int paddingY: -1

  property color _bgColor: {
    if (_isDefaultShape) {
      if (_isPressed) return _fbp
      if (_isHovered) return _fbh
      if (active) return Theme.accent
      return _fb
    }
    if (shape === "link") return "transparent"
    if (shape === "circle") {
      if (_isPressed) return Theme.controlBackgroundPressed
      if (_isHovered && hoverEffect) return Theme.controlBackgroundHover
      return bgColor
    }
    if (shape === "icon") {
      if (_isPressed) return pressedColor
      if (_isHovered && hoverEffect) return Theme.buttonHoverOverlay
      return bgColor
    }
    if (active) return Theme.accent
    if (_isAccent) return Theme.accent
    if (_isHovered && hoverEffect) return Theme.buttonHoverOverlay
    return Theme.backgroundTertiary
  }

  property color _borderColor: {
    if (_isFlat) return "transparent"
    if (_isDefaultShape) {
      if (!_isDefault) return "transparent"
      if (_isPressed) return Theme.buttonBorderPressed
      if (_isHovered && hoverEffect) return Theme.buttonBorderHover
      return Theme.borderVisible
    }
    if (shape === "circle") {
      return _isHovered ? (hoverEffect ? Theme.buttonBorderHover : Theme.border) : Theme.border
    }
    if (active) return Theme.accent
    if (_isHovered && hoverEffect) return Theme.buttonBorderHover
    return Theme.controlBorder
  }

  property bool _showBorder: {
    if (_isFlat) return false
    if (_isDefaultShape && !_isDefault) return false
    return true
  }

  // ── Children ───────────────────────────────────────────────
  Item {
    id: contentLayer
    anchors.fill: parent
    layer.enabled: busy && Theme.blurEnabled
    layer.effect: MultiEffect {
      blurEnabled: busy
      blur: 1.0
      blurMax: 16
      autoPaddingEnabled: false
    }

    Rectangle {
      id: bg
      anchors.fill: parent
      radius: shape === "icon" ? bgRadius : root.radius
      visible: shape === "link" ? false : (shape !== "icon" || showBackground || _isHovered || _isPressed || active)

      color: _bgColor

      border.width: _showBorder ? Theme.borderWidth : 0
      border.color: _borderColor

      scale: {
        if (busy) return 1.0
        if (!_isDefaultShape) return 1.0
        return _isPressed ? 0.96 : 1.0
      }

      Behavior on color {
        enabled: Theme.animationsEnabled
        ColorAnimation { duration: Theme.animationNormal; easing.type: Easing.OutQuad }
      }
      Behavior on scale {
        enabled: Theme.animationsEnabled
        NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutQuad }
      }
      Behavior on border.color {
        enabled: Theme.animationsEnabled
        ColorAnimation { duration: Theme.animationNormal; easing.type: Easing.OutQuad }
      }
    }

    Row {
      id: _defaultRow
      anchors.centerIn: parent
      spacing: Theme.spaceXs
      visible: _isDefaultShape

      Icon {
        id: _defaultIcon
        source: _hasIcon ? Icons.get(icon) : ""
        size: small ? 12 : 14
        color: _isHovered ? _fh : _ft
        visible: _hasIcon
        width: _hasIcon ? (small ? 12 : 14) : 0
        anchors.verticalCenter: parent.verticalCenter

        Behavior on color {
          enabled: Theme.animationsEnabled
          ColorAnimation { duration: Theme.animationFast; easing.type: Easing.OutQuad }
        }
      }

      Text {
        id: _defaultLabel
        text: root.text.toUpperCase()
        color: _isHovered ? _fh : _ft
        font.pixelSize: root.fontSize
        font.family: Theme.fontFamilyMono
        font.weight: Font.Medium
        font.letterSpacing: 0.06
        visible: root.text !== ""
        anchors.verticalCenter: parent.verticalCenter

        Behavior on color {
          enabled: Theme.animationsEnabled
          ColorAnimation { duration: Theme.animationFast; easing.type: Easing.OutQuad }
        }
      }
    }

    Text {
      id: _linkLabel
      anchors.centerIn: parent
      text: root.text.toUpperCase()
      color: _isHovered ? Theme.textDisplay : Theme.textDisabled
      font.pixelSize: root.fontSize
      font.family: Theme.fontFamilyMono
      font.weight: Font.Medium
      font.letterSpacing: 0.06
      font.underline: _isHovered
      visible: shape === "link" && root.text !== ""

      Behavior on color {
        enabled: Theme.animationsEnabled
        ColorAnimation { duration: Theme.animationFast; easing.type: Easing.OutQuad }
      }
    }

    Icon {
      anchors.centerIn: parent
      source: Icons.get(icon)
      size: root.iconSize
      color: Theme.contrastTextColor(_bgColor)
      visible: shape === "circle" && icon !== ""

      Behavior on color {
        enabled: Theme.animationsEnabled
        ColorAnimation { duration: Theme.animationFast }
      }
    }

    Text {
      anchors.centerIn: parent
      text: root.text
      color: Theme.contrastTextColor(_bgColor)
      font.pixelSize: root.iconSize
      font.family: labelFontFamily
      visible: shape === "circle" && root.text !== "" && icon === ""
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter

      Behavior on color {
        enabled: Theme.animationsEnabled
        ColorAnimation { duration: Theme.animationFast }
      }
    }

    Row {
      id: _iconRow
      anchors.centerIn: parent
      spacing: root.text ? Theme.spaceXs : 0
      visible: shape === "icon"

      Icon {
        anchors.verticalCenter: parent.verticalCenter
        source: icon ? Icons.get(icon) : ""
        size: root.iconSize
        color: root.color
        visible: icon !== ""
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: labelCaps ? root.text.toUpperCase() : root.text
        color: root.color
        font.pixelSize: root.fontSize
        font.family: labelCaps ? Theme.fontFamilyMono : Theme.fontFamily
        visible: root.text !== ""
      }
    }

    Column {
      id: _tileColumn
      anchors.centerIn: parent
      spacing: Theme.spaceXs
      visible: shape === "tile"

      Item {
        width: 18; height: 18
        anchors.horizontalCenter: parent.horizontalCenter

        Spinner {
          anchors.centerIn: parent
          spinnerSize: 16
          spinnerColor: Theme.contrastTextColor(_bgColor)
          visible: busy
        }

        Icon {
          anchors.centerIn: parent
          source: Icons.get(icon)
          size: 18
          color: Theme.contrastTextColor(_bgColor)
          visible: !busy
        }
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.text.toUpperCase()
        color: Theme.contrastTextColor(_bgColor)
        font.pixelSize: Theme.fontSizeMicro
        font.family: Theme.fontFamilyMono
        font.letterSpacing: 0.08
      }
    }

    MouseArea {
      id: mouseArea
      anchors.fill: parent
      preventStealing: true
      hoverEnabled: !busy
      cursorShape: busy ? Qt.WaitCursor : Qt.PointingHandCursor
      acceptedButtons: shape === "icon" ? (Qt.LeftButton | Qt.RightButton) : Qt.LeftButton
      onClicked: (mouse) => {
        if (busy) return
        if (root.actionId !== "") root.busy = true
        if (shape === "icon" && mouse.button === Qt.RightButton) root.rightClicked()
        else root.clicked()
      }
    }
  }

  BusyOverlay {
    anchors.fill: parent
    busy: root.busy
    radius: root.radius
    overlayColor: root.overlayColor
    spinnerColor: Theme.contrastTextColor(_bgColor)
    z: 1
  }

  HoverHandler {
    enabled: root.tooltip !== ""
    onHoveredChanged: tooltipPopup.visible = hovered && root.tooltip !== ""
  }

  Popup {
    id: tooltipPopup
    x: (root.width - width) / 2
    y: root.height + Theme.spaceXs
    width: tooltipLabel.implicitWidth + 16
    height: tooltipLabel.implicitHeight + 8
    visible: false
    closePolicy: Popup.NoAutoClose

    background: Rectangle {
      radius: Theme.radiusSmall
      color: Theme.backgroundTertiary
      border.width: Theme.borderWidth
      border.color: Theme.border
    }

    contentItem: Text {
      id: tooltipLabel
      text: root.tooltip
      color: Theme.textPrimary
      font.pixelSize: Theme.fontSizeCaption
      font.family: Theme.fontFamilyMono
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
    }
  }
}
