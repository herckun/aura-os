import QtQuick
import Quickshell
import Quickshell.Io
import "../styles"
import "../core"
import "../services"

Item {
  id: root

  // ── Properties ─────────────────────────────────────────────
  property var plugin: null
  property real screenWidth: 0
  property real screenHeight: 0
  property real defaultMargin: Theme.spaceLg
  readonly property real defaultBarOffset: {
    var barH = BarService.barBottom
    if (barH > 0) return barH + Theme.spaceMd
    var h = AppearanceService.barFloating ? Theme.barHeight + Theme.spaceSm : Theme.barHeight
    return h + Theme.spaceMd
  }
  property bool autoPosition: plugin ? (PluginService.getPluginSetting(plugin.id, "autoPosition", "desktop") ?? false) : false
  readonly property bool showBackground: plugin ? (PluginService.getPluginSetting(plugin.id, "showBackground", "desktop") ?? false) : false

  // ── Internal state ─────────────────────────────────────────
  property real _committedX: 0
  property real _committedY: 0

  readonly property bool _draggable: PluginService.getPluginSetting(plugin ? plugin.id : "", "draggable", "desktop") ?? true

  // ── Mode / bar change timers ───────────────────────────────
  Connections {
    target: ModeService
    function onModeChanged(): void {
      _modeChangeTimer.restart()
      _modeChangeTimer2.restart()
      _modeChangeTimer3.restart()
    }
  }

  Connections {
    target: BarService
    function onBarBottomChanged(): void {
      _barChangeTimer.restart()
    }
  }

  Timer { id: _modeChangeTimer;  interval: 200;  repeat: false; onTriggered: root._repositionAfterModeChange() }
  Timer { id: _modeChangeTimer2; interval: 600;  repeat: false; onTriggered: root._repositionAfterModeChange() }
  Timer { id: _modeChangeTimer3; interval: 1500; repeat: false; onTriggered: root._repositionAfterModeChange() }
  Timer { id: _barChangeTimer;   interval: 100;  repeat: false; onTriggered: root._repositionAfterModeChange() }

  function _repositionAfterModeChange(): void {
    if (!widgetLoader.item) return
    var w = widgetLoader.item.width
    var h = widgetLoader.item.height
    if (w <= 0 || h <= 0) return

    var barBottom = root.defaultBarOffset
    if (barBottom <= 0) return

    var margin = Theme.spaceMd
    var newX = widgetLoader.x
    var newY = widgetLoader.y

    if (newY < barBottom) newY = barBottom
    if (newY + h > screenHeight - margin) newY = Math.max(barBottom, screenHeight - margin - h)
    if (newX < margin) newX = margin
    if (newX + w > screenWidth - margin) newX = Math.max(margin, screenWidth - margin - w)
    if (newY + h > screenHeight - margin) newY = Math.max(barBottom, screenHeight - margin - h)

    widgetLoader.x = newX
    widgetLoader.y = newY
    root._committedX = newX
    root._committedY = newY
    Store.desktop.widgets = Store.mapPatch(Store.desktop.widgets, root.plugin.id, {
      x: newX / root.screenWidth,
      y: newY / root.screenHeight
    })
    root._registerMyRegion()
    DesktopLayoutService.requestLayout(root.screenWidth, root.screenHeight)
  }

  // ── Plugin setting changes ─────────────────────────────────
  Connections {
    target: PluginService
    function onPluginSettingChanged(pluginId, key, value, location) {
      if (pluginId !== root.plugin?.id || location !== "desktop") return
      if (key === "autoPosition") root.autoPosition = value
      if (key === "showBackground") root.showBackground = value
      root._registerMyRegion()
      DesktopLayoutService.requestLayout(root.screenWidth, root.screenHeight)
    }
  }

  // ── Background colors ───────────────────────────────────────
  readonly property color widgetBgColor: _widgetBgColor
  readonly property color widgetTextColor: _widgetTextColor
  readonly property color widgetDimColor: _widgetDimColor
  readonly property color widgetAccentColor: _widgetAccentColor

  property color _widgetBgColor: Qt.rgba(0, 0, 0, 1)
  property color _widgetTextColor: Qt.rgba(1, 1, 1, 1)
  property color _widgetDimColor: Qt.rgba(1, 1, 1, 0.5)
  property color _widgetAccentColor: Theme.accent

  // ── Contrast properties (from wallpaper) ────────────────────
  readonly property color textColor: _textColor
  readonly property color shadowColor: _shadowColor
  readonly property color dimColor: _dimColor
  readonly property color bgColor: _bgColor
  readonly property real  bgLuminance: _bgLuminance

  property color _textColor: Qt.rgba(0, 0, 0, 1)
  property color _shadowColor: Qt.rgba(0, 0, 0, 0.12)
  property color _dimColor: Qt.rgba(0, 0, 0, 0.45)
  property color _bgColor: Qt.rgba(0, 0, 0, 1)
  property real  _bgLuminance: 0.0

  // ── Contrast lookup ─────────────────────────────────────────
  function contrastFor(item: Item): var {
    return contrastAt(item.x, item.y, item.width, item.height)
  }

  function contrastAt(localX: real, localY: real, w: real, h: real): var {
    if (root.showBackground) {
      return {
        textColor: root._widgetTextColor,
        shadowColor: Qt.rgba(root._widgetTextColor.r, root._widgetTextColor.g, root._widgetTextColor.b, 0.12),
        bgColor: root._widgetBgColor,
        bgLuminance: WallpaperService.relativeLuminance(root._widgetBgColor)
      }
    }
    return WallpaperService.contrastAt(root._committedX + localX, root._committedY + localY, w, h, root.screenWidth, root.screenHeight)
  }

  function _updateBackground(): void {
    if (!root.showBackground) return
    var wp = WallpaperService.background
    if (!wp || wp.toString() === "#000000") {
      root._widgetBgColor = Theme.backgroundSecondary
    } else {
      var lum = WallpaperService.relativeLuminance(wp)
      var opacity = AppearanceService.transparencyEnabled ? 0.75 : 1.0
      root._widgetBgColor = lum > 0.5 ? Qt.rgba(1, 1, 1, opacity) : Qt.rgba(0, 0, 0, opacity)
    }
    root._widgetTextColor = WallpaperService.contrastTextColor(root._widgetBgColor)
    root._widgetDimColor = Qt.rgba(root._widgetTextColor.r, root._widgetTextColor.g, root._widgetTextColor.b, 0.5)
    var accent = Theme.accent
    var bgLum = WallpaperService.relativeLuminance(root._widgetBgColor)
    var accentLum = WallpaperService.relativeLuminance(accent)
    if ((bgLum > 0.5 && accentLum > 0.5) || (bgLum <= 0.5 && accentLum <= 0.5)) {
      root._widgetAccentColor = bgLum > 0.5 ? Qt.darker(accent, 1.3) : Qt.lighter(accent, 1.3)
    } else {
      root._widgetAccentColor = accent
    }
  }

  function _updateContrast(): void {
    _updateBackground()
    if (!WallpaperService.mapReady) return
    var wItem = widgetLoader.item
    if (!wItem) return
    var c = contrastAt(wItem.width / 2, wItem.height / 2, wItem.width, wItem.height)
    root._bgLuminance = c.bgLuminance
    root._bgColor = c.bgColor
    root._textColor = c.textColor
    root._shadowColor = c.shadowColor
    root._dimColor = Qt.rgba(c.textColor.r, c.textColor.g, c.textColor.b, 0.45)
  }

  // ── Region management ──────────────────────────────────────
  function _registerMyRegion(): void {
    if (!plugin || !widgetLoader.item) return
    var w = widgetLoader.item.width
    var h = widgetLoader.item.height
    if (w > 0 && h > 0) {
      DesktopLayoutService.registerRegion(plugin.id, _committedX, _committedY, w, h)
    }
  }

  // ── Position restore ───────────────────────────────────────
  function _restorePosition(): void {
    var geom = Store.desktop.widgets[plugin.id] || {}
    var sx = geom.x ?? -1
    var sy = geom.y ?? -1
    if (sx >= 0 && sy >= 0) {
      widgetLoader.x = sx * root.screenWidth
      widgetLoader.y = sy * root.screenHeight
    } else {
      widgetLoader.x = root.defaultMargin
      widgetLoader.y = root.defaultBarOffset
    }
    root._committedX = widgetLoader.x
    root._committedY = widgetLoader.y
  }

  // ── Background rectangle ───────────────────────────────────
  Rectangle {
    id: bgRect
    anchors.fill: widgetLoader
    anchors.margins: root.showBackground ? -Theme.spaceMd : 0
    radius: Theme.radiusMedium
    color: {
      if (!root.showBackground) return "transparent"
      var base = root._widgetBgColor
      return Qt.rgba(base.r, base.g, base.b, AppearanceService.transparencyEnabled ? 0.75 : 0.95)
    }
    border.width: root.showBackground ? 1 : 0
    border.color: Qt.rgba(1, 1, 1, 0.1)
    visible: root.showBackground
    z: -1
  }

  // ── Timers ─────────────────────────────────────────────────
  Timer {
    id: _delayedUpdate
    interval: 0
    repeat: false
    onTriggered: {
      root._registerMyRegion()
      root._updateContrast()
    }
  }

  Timer {
    id: _sizeChangeTimer
    interval: 150
    repeat: false
    onTriggered: {
      root._registerMyRegion()
      DesktopLayoutService.requestLayout(root.screenWidth, root.screenHeight)
      Qt.callLater(root._updateContrast)
    }
  }

  onScreenWidthChanged: _screenDimsTimer.restart()
  onScreenHeightChanged: _screenDimsTimer.restart()

  Timer {
    id: _screenDimsTimer
    interval: 250
    repeat: false
    onTriggered: {
      if (root.screenWidth <= 0 || root.screenHeight <= 0) return
      root._restorePosition()
      root._registerMyRegion()
      DesktopLayoutService.requestLayout(root.screenWidth, root.screenHeight)
      Qt.callLater(root._updateContrast)
    }
  }

  // ── Loader ─────────────────────────────────────────────────
  Loader {
    id: widgetLoader
    sourceComponent: plugin ? plugin.desktopComponent : null
    onLoaded: {
      if (item && item.hasOwnProperty("desktopWidget")) {
        item.desktopWidget = root
      }
      _delayedUpdate.restart()
    }
  }

  Connections {
    target: widgetLoader.item
    function onWidthChanged(): void { _sizeChangeTimer.restart() }
    function onHeightChanged(): void { _sizeChangeTimer.restart() }
  }

  // ── Layout signals ─────────────────────────────────────────
  Connections {
    target: WallpaperService
    function onMapReadyChanged() {
      root._updateContrast()
      if (root.autoPosition) {
        Qt.callLater(function() {
          DesktopLayoutService.requestLayout(root.screenWidth, root.screenHeight)
        })
      }
    }
  }

  Connections {
    target: DesktopLayoutService
    function onLayoutComplete() {
      if (!root.autoPosition) return
      var pos = DesktopLayoutService.autoPositions[root.plugin.id]
      if (!pos) return
      widgetLoader.x = pos.x
      widgetLoader.y = pos.y
      root._committedX = pos.x
      root._committedY = pos.y
      root._registerMyRegion()
      Qt.callLater(root._updateContrast)
    }
  }

  Connections {
    target: Theme
    function onAccentChanged() {
      root._updateBackground()
    }
  }

  Connections {
    target: Store.desktop
    function onWidgetsChanged() {
      if (dragArea._dragging) return
      root._restorePosition()
      root._registerMyRegion()
      DesktopLayoutService.requestLayout(root.screenWidth, root.screenHeight)
    }
  }

  // ── Lifecycle ──────────────────────────────────────────────
  Component.onCompleted: {
    _restorePosition()
    _registerMyRegion()
    DesktopLayoutService.requestLayout(root.screenWidth, root.screenHeight)
  }

  Component.onDestruction: {
    DesktopLayoutService.unregisterRegion(plugin.id)
  }

  // ── Drag ───────────────────────────────────────────────────
  MouseArea {
    id: dragArea
    property bool _dragging: false
    property real _dragStartX: 0
    property real _dragStartY: 0
    property real _itemStartX: 0
    property real _itemStartY: 0
    property real _frozenX: 0
    property real _frozenY: 0

    visible: root._draggable && widgetLoader.item !== null
    enabled: root._draggable && widgetLoader.item !== null
    cursorShape: root._draggable ? Qt.SizeAllCursor : Qt.ArrowCursor
    z: 100

    x: _dragging ? _frozenX : widgetLoader.x
    y: _dragging ? _frozenY : widgetLoader.y
    width: widgetLoader.item ? widgetLoader.item.width : 0
    height: widgetLoader.item ? widgetLoader.item.height : 0

    onPressed: function(mouse) {
      _dragging = true
      _frozenX = widgetLoader.x
      _frozenY = widgetLoader.y
      _dragStartX = mouse.x
      _dragStartY = mouse.y
      _itemStartX = widgetLoader.x
      _itemStartY = widgetLoader.y
      mouse.accepted = true
    }

    onPositionChanged: function(mouse) {
      widgetLoader.x = _itemStartX + (mouse.x - _dragStartX)
      widgetLoader.y = _itemStartY + (mouse.y - _dragStartY)
    }

    onReleased: {
      _dragging = false
      var fx = widgetLoader.x / root.screenWidth
      var fy = widgetLoader.y / root.screenHeight
      fx = Math.max(0, Math.min(1, fx))
      fy = Math.max(0, Math.min(1, fy))
      Store.desktop.widgets = Store.mapPatch(Store.desktop.widgets, plugin.id, { x: fx, y: fy })
      root._committedX = widgetLoader.x
      root._committedY = widgetLoader.y
      root._registerMyRegion()
      DesktopLayoutService.requestLayout(root.screenWidth, root.screenHeight)
      Qt.callLater(root._updateContrast)
      if (root.autoPosition) {
        root.autoPosition = false
        PluginService.setPluginSetting(plugin.id, "autoPosition", false, "desktop")
      }
    }
  }
}
