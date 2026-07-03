pragma ComponentBehavior: Bound

import QtQuick
import QtQml
import QtQuick.Layouts
import "../../../../styles"
import "../../../../services"
import "../../../../core"

BasePlugin {
  id: root

  // ── Manifest ────────────────────────────────────────────────────
  pluginId: "audioviz"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Audio Visualizer",
    description: "Desktop audio spectrum visualizer",
    icon: "speaker-high",
    locations: ["desktop"],
    settings: [
      {
        key: "draggable",
        label: "DRAGGABLE",
        description: "Allow repositioning by dragging",
        type: "toggle",
        default: true
      },
      {
        key: "autoPosition",
        label: "AUTO POSITION",
        description: "Find best position on wallpaper automatically",
        type: "toggle",
        default: false
      },
      {
        key: "vizStyle",
        label: "VISUALIZER STYLE",
        description: "Shape of the frequency bars",
        type: "select",
        options: ["bars", "dots", "wave"],
        default: "bars",
        controlSize: "sm"
      },
      {
        key: "barWidth",
        label: "BAR WIDTH",
        description: "Width of the frequency bars",
        type: "stepper",
        min: 4,
        max: 24,
        step: 2,
        unit: "px",
        default: 8
      },
      {
        key: "barSpacing",
        label: "BAR SPACING",
        description: "Space between frequency bars",
        type: "stepper",
        min: 2,
        max: 16,
        step: 2,
        unit: "px",
        default: 4
      },
      {
        key: "vizHeight",
        label: "VISUALIZER HEIGHT",
        description: "Maximum height of the visualizer",
        type: "stepper",
        min: 40,
        max: 120,
        step: 10,
        unit: "px",
        default: 64
      },
      {
        key: "useAccent",
        label: "USE ACCENT COLOR",
        description: "Color bars with the theme accent",
        type: "toggle",
        default: true
      },
      {
        key: "reflection",
        label: "REFLECTION",
        description: "Show a faded reflection below",
        type: "toggle",
        default: true
      },
      {
        key: "showWhenPaused",
        label: "SHOW WHEN PAUSED",
        description: "Keep visible when music is paused",
        type: "toggle",
        default: false
      },
      {
        key: "showBackground",
        label: "BACKGROUND",
        description: "Show background behind widget",
        type: "toggle",
        default: false
      }
    ]
  })

  // ── Public state ─────────────────────────────────────────────────

  // ── Internal state ───────────────────────────────────────────────

  // ── Signal handlers ──────────────────────────────────────────────

  // ── Public API ───────────────────────────────────────────────────

  // ── Helpers ──────────────────────────────────────────────────────

  // ── Timers ───────────────────────────────────────────────────────

  // ── Lifecycle ────────────────────────────────────────────────────

  // ── UI components ────────────────────────────────────────────────
  property Component desktopComponent: Item {
    id: vizContainer

    // ── Settings Bindings ────────────────────────────────────
    property bool _isDots: PluginService.getPluginSetting("audioviz", "vizStyle", "desktop") === "dots"
    property bool _isWave: PluginService.getPluginSetting("audioviz", "vizStyle", "desktop") === "wave"
    property int _barW: PluginService.getPluginSetting("audioviz", "barWidth", "desktop") ?? 8
    property int _barS: PluginService.getPluginSetting("audioviz", "barSpacing", "desktop") ?? 4
    property int _vizH: PluginService.getPluginSetting("audioviz", "vizHeight", "desktop") ?? 64
    property bool _useAccent: PluginService.getPluginSetting("audioviz", "useAccent", "desktop") ?? true
    property bool _reflection: PluginService.getPluginSetting("audioviz", "reflection", "desktop") ?? true
    property bool _showWhenPaused: PluginService.getPluginSetting("audioviz", "showWhenPaused", "desktop") ?? false

    readonly property int _numBands: 7
    readonly property int _totalWidth: _numBands * _barW + (_numBands - 1) * _barS
    readonly property int _totalHeight: _vizH + (_reflection ? _vizH * 0.4 : 0)

    width: _totalWidth
    height: _totalHeight

    // ── DesktopWidget bridge ──────────────────────────────────
    property var desktopWidget: null

    readonly property bool _autoPos: PluginService.getPluginSetting("audioviz", "autoPosition", "desktop") ?? false

    on_AutoPosChanged: {
      if (vizContainer.desktopWidget) {
        vizContainer.desktopWidget.autoPosition = vizContainer._autoPos
      }
    }
    onDesktopWidgetChanged: {
      if (vizContainer.desktopWidget) {
        vizContainer.desktopWidget.autoPosition = vizContainer._autoPos
      }
    }

    // ── Color Hooks ───────────────────────────────────────────
    readonly property color _vizColor: {
      var _v = _cfgVersion
      if (_useAccent) {
        var bg = WallpaperService.background
        if (!bg || bg.toString() === "#000000") bg = Theme.background
        return Theme.contrastTextColor(bg).toString() === "#000000" ? Qt.lighter(Theme.accent, 1.35) : Theme.accent
      }

      var _c = vizContainer.desktopWidget ? vizContainer.desktopWidget.contrastFor(vizContainer) : null
      return _c ? _c.textColor : "white"
    }

    readonly property color _vizDimColor: Qt.rgba(_vizColor.r, _vizColor.g, _vizColor.b, 0.25)

    property int _cfgVersion: 0

    // ── Visibility State ──────────────────────────────────────
    property bool _isActive: MediaService.hasPlayer && (MediaService.playbackStatus === "Playing" || _showWhenPaused)
    property bool _hasAudio: false

    opacity: _isActive ? 1.0 : 0.0
    visible: opacity > 0

    Behavior on opacity {
      enabled: Theme.animationsEnabled
      NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutQuad }
    }

    Connections {
      target: MediaService
      function onEqBandsChanged() {
        var hasAudio = MediaService.eqBands.some(function(b) { return b > 0 })
        vizContainer._hasAudio = hasAudio
      }
    }

    // ── Visualizer Canvas ─────────────────────────────────────
    Canvas {
      id: vizCanvas
      width: vizContainer._totalWidth
      height: vizContainer._totalHeight
      antialiasing: true

      onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        var bands = MediaService.eqBands
        var w = vizContainer._barW
        var s = vizContainer._barS
        var h = vizContainer._vizH
        var isDots = vizContainer._isDots
        var isWave = vizContainer._isWave
        var hasReflection = vizContainer._reflection
        var colorStr = vizContainer._vizColor.toString()
        var dimColorStr = vizContainer._vizDimColor.toString()

        if (isWave) {
          // ── WAVE RENDERING ────────────────────────────────
          ctx.beginPath()
          ctx.moveTo(0, h)

          for (var i = 0; i < 7; i++) {
            var val = bands[i] || 0
            var x = i * (w + s) + (w / 2)
            var y = h - (val * h)

            if (i === 0) {
              ctx.lineTo(x, y)
            } else {
              var prevX = (i - 1) * (w + s) + (w / 2)
              var prevY = h - ((bands[i-1] || 0) * h)
              var cpX = (prevX + x) / 2
              ctx.bezierCurveTo(cpX, prevY, cpX, y, x, y)
            }
          }

          ctx.lineTo((6 * (w + s) + w), h)
          ctx.closePath()

          var grad = ctx.createLinearGradient(0, 0, 0, h)
          grad.addColorStop(0, colorStr)
          grad.addColorStop(1, dimColorStr)
          ctx.fillStyle = grad
          ctx.fill()

          if (hasReflection) {
            ctx.save()
            ctx.translate(0, h * 2)
            ctx.scale(1, -0.4)
            ctx.globalAlpha = 0.15

            ctx.beginPath()
            ctx.moveTo(0, h)
            for (var j = 0; j < 7; j++) {
              var v2 = bands[j] || 0
              var x2 = j * (w + s) + (w / 2)
              var y2 = h - (v2 * h)
              if (j === 0) ctx.lineTo(x2, y2)
              else {
                var pX = (j - 1) * (w + s) + (w / 2)
                var pY = h - ((bands[j-1] || 0) * h)
                var cX = (pX + x2) / 2
                ctx.bezierCurveTo(cX, pY, cX, y2, x2, y2)
              }
            }
            ctx.lineTo((6 * (w + s) + w), h)
            ctx.closePath()
            ctx.fillStyle = colorStr
            ctx.fill()
            ctx.restore()
          }
        } else {
          // ── BARS / DOTS RENDERING ─────────────────────────
          for (var k = 0; k < 7; k++) {
            var valB = bands[k] || 0
            var xB = k * (w + s)
            var yB = h - (valB * h)
            var barH = valB * h

            if (isDots) {
              var dotR = w / 2
              var numDots = Math.max(1, Math.round(barH / (dotR * 2.2)))

              for (var d = 0; d < numDots; d++) {
                var dY = h - (d * dotR * 2.2) - dotR
                var alpha = 1.0 - (d * 0.12)
                if (alpha < 0.2) alpha = 0.2

                ctx.beginPath()
                ctx.arc(xB + dotR, dY, dotR * 0.8, 0, 2 * Math.PI)
                ctx.fillStyle = Qt.rgba(vizContainer._vizColor.r, vizContainer._vizColor.g, vizContainer._vizColor.b, alpha)
                ctx.fill()
              }
            } else {
              var radius = w / 2

              if (barH > radius * 2) {
                ctx.beginPath()
                ctx.moveTo(xB, h)
                ctx.lineTo(xB, yB + radius)
                ctx.arc(xB + radius, yB + radius, radius, Math.PI, 0, false)
                ctx.lineTo(xB + w, h)
                ctx.closePath()

                var barGrad = ctx.createLinearGradient(0, yB, 0, h)
                barGrad.addColorStop(0, colorStr)
                barGrad.addColorStop(1, dimColorStr)
                ctx.fillStyle = barGrad
                ctx.fill()
              } else if (barH > 0) {
                ctx.beginPath()
                ctx.rect(xB, yB, w, barH)
                ctx.fillStyle = colorStr
                ctx.fill()
              }

              if (hasReflection && barH > 0) {
                ctx.save()
                ctx.translate(0, h * 2)
                ctx.scale(1, -0.4)
                ctx.globalAlpha = 0.15

                ctx.beginPath()
                ctx.rect(xB, h - barH, w, barH)
                ctx.fillStyle = colorStr
                ctx.fill()
                ctx.restore()
              }
            }
          }
        }
      }

      Connections {
        target: MediaService
        function onEqBandsChanged() { vizCanvas.requestPaint() }
      }
    }

    // ── Lifecycle ─────────────────────────────────────────────
    Component.onCompleted: {
    }

    Connections {
      target: WallpaperService
      function onMapReadyChanged() {
        vizContainer._cfgVersion++
        vizCanvas.requestPaint()
      }
    }
  }
}
