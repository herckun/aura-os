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
  pluginId: "desktopclock"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Desktop Clock",
    description: "Large clock widget for the desktop",
    icon: "clock",
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
        key: "clockStyle",
        label: "CLOCK STYLE",
        description: "Digital or analog display",
        type: "select",
        options: ["digital", "analog"],
        default: "digital",
        controlSize: "sm"
      },
      {
        key: "format24h",
        label: "24-HOUR FORMAT",
        description: "Use 24-hour time instead of 12-hour",
        type: "toggle",
        default: true
      },
      {
        key: "showSeconds",
        label: "SHOW SECONDS",
        description: "Display seconds in the clock",
        type: "toggle",
        default: false
      },
      {
        key: "showDate",
        label: "SHOW DATE",
        description: "Display the date beneath the clock",
        type: "toggle",
        default: true
      },
      {
        key: "clockSize",
        label: "CLOCK SIZE",
        description: "Scale of the clock",
        type: "stepper",
        min: 80,
        max: 150,
        step: 5,
        unit: "%",
        default: 100
      },
      {
        key: "clockLayout",
        label: "LAYOUT",
        description: "Vertical or horizontal arrangement",
        type: "select",
        options: ["vertical", "horizontal"],
        default: "vertical",
        controlSize: "sm"
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
    id: clockContainer
    width: clockContainer._isAnalog ? analogCol.implicitWidth
      : (clockContainer._isVertical ? clockCol.implicitWidth : clockRow.implicitWidth)
    height: clockContainer._isAnalog ? analogCol.implicitHeight
      : (clockContainer._isVertical ? clockCol.implicitHeight : clockRow.implicitHeight)

    property bool _isAnalog: PluginService.getPluginSetting("desktopclock", "clockStyle", "desktop") === "analog"
    property bool _isVertical: PluginService.getPluginSetting("desktopclock", "clockLayout", "desktop") !== "horizontal"
    property bool _format24h: PluginService.getPluginSetting("desktopclock", "format24h", "desktop") ?? true
    property bool _showSeconds: PluginService.getPluginSetting("desktopclock", "showSeconds", "desktop") ?? false
    property bool _showDate: PluginService.getPluginSetting("desktopclock", "showDate", "desktop") ?? true
    property real _clockSize: PluginService.getPluginSetting("desktopclock", "clockSize", "desktop") ?? 100
    readonly property real _scale: clockContainer._clockSize / 100

    // ── DesktopWidget bridge ──────────────────────────────────
    property var desktopWidget: null

    readonly property bool _autoPos: PluginService.getPluginSetting("desktopclock", "autoPosition", "desktop") ?? false

    on_AutoPosChanged: {
      if (clockContainer.desktopWidget) {
        clockContainer.desktopWidget.autoPosition = clockContainer._autoPos
      }
    }
    onDesktopWidgetChanged: {
      if (clockContainer.desktopWidget) {
        clockContainer.desktopWidget.autoPosition = clockContainer._autoPos
      }
    }

    // ── Palette hooks ──────────────────────────────────────────
    function _updateClockText() {
      var now = DateTimeService.currentDate
      var is24 = clockContainer._format24h

      if (!clockContainer._isAnalog && clockContainer._isVertical) {
        timeHH.text = Qt.formatDateTime(now, is24 ? "HH" : "h")
        timeMM.text = Qt.formatDateTime(now, "mm")
        if (clockContainer._showSeconds) timeSS.text = Qt.formatDateTime(now, "ss")
        if (!is24) timeAMPM.text = Qt.formatDateTime(now, "AP")
        dayText.text = Qt.formatDateTime(now, "dddd").toUpperCase()
        if (clockContainer._showDate) dateText.text = Qt.formatDateTime(now, "MMMM d").toUpperCase()
      }

      if (!clockContainer._isAnalog && !clockContainer._isVertical) {
        dayTextH.text = Qt.formatDateTime(now, "dddd").toUpperCase()
        if (clockContainer._showDate) dateTextH.text = Qt.formatDateTime(now, "MMMM d").toUpperCase()
        timeLabelH.text = Qt.formatDateTime(now, is24 ? "HH:mm" : "h:mm")
        if (!is24) {
          var ampmText = Qt.formatDateTime(now, "AP")
          ampmLabelH.text = ampmText
        }
        if (clockContainer._showSeconds) secLabelH.text = Qt.formatDateTime(now, "ss")
      }
    }

    property int _cfgVersion: 0
    readonly property color _bgColor: {
      var _v = _cfgVersion
      var sampled = Store.get("desktop.desktopclock.bgColor", "")
      if (sampled.length > 0) {
        var c = Qt.color(sampled)
        if (c.valid) return c
      }
      var bg = WallpaperService.background
      if (!bg || bg.toString() === "#000000") bg = Theme.background
      return bg
    }

    readonly property color _accentContrast: {
      var accent = Theme.accent
      var bgText = Theme.contrastTextColor(clockContainer._bgColor)
      var accentText = Theme.contrastTextColor(accent)
      if (bgText.toString() === accentText.toString()) {
        return bgText.toString() === "#FFFFFF"
          ? Qt.lighter(accent, 1.35)
          : Qt.darker(accent, 1.35)
      }
      return accent
    }
    readonly property color _surfaceColor: clockContainer._accentContrast

    ColumnLayout {
      id: clockCol
      visible: !clockContainer._isAnalog && clockContainer._isVertical
      spacing: 0

      ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.bottomMargin: Theme.spaceSm
        spacing: 0

        Text {
          id: timeHH
          text: ""
          font.family: Theme.fontFamilyMono
          font.pixelSize: Math.round(Theme.fontSizeDisplayXl * clockContainer._scale)
          font.weight: Font.Bold
          font.letterSpacing: 4
          Layout.alignment: Qt.AlignHCenter
          property var _c: clockContainer.desktopWidget ? clockContainer.desktopWidget.contrastFor(this) : null
          color: _c ? _c.textColor : "white"

          Text {
            x: 1; y: 2
            text: timeHH.text
            font: timeHH.font
            color: timeHH._c ? timeHH._c.shadowColor : "black"
            z: -1
          }
        }

        Text {
          id: timeMM
          text: ""
          font.family: Theme.fontFamilyMono
          font.pixelSize: Math.round(Theme.fontSizeDisplayXl * clockContainer._scale)
          font.weight: Font.Bold
          font.letterSpacing: 4
          Layout.alignment: Qt.AlignHCenter
          property var _c: clockContainer.desktopWidget ? clockContainer.desktopWidget.contrastFor(this) : null
          color: _c ? _c.textColor : "white"

          Text {
            x: 1; y: 2
            text: timeMM.text
            font: timeMM.font
            color: timeMM._c ? timeMM._c.shadowColor : "black"
            z: -1
          }
        }

        Text {
          id: timeSS
          visible: clockContainer._showSeconds
          text: ""
          font.family: Theme.fontFamilyMono
          font.pixelSize: Math.round(Theme.fontSizeSubhead * clockContainer._scale)
          font.weight: Font.Medium
          font.letterSpacing: 8
          Layout.alignment: Qt.AlignHCenter
          Layout.topMargin: Theme.spaceXs
          property var _c: clockContainer.desktopWidget ? clockContainer.desktopWidget.contrastFor(this) : null
          color: _c ? _c.textColor : "white"
        }

        Text {
          id: timeAMPM
          visible: !clockContainer._format24h
          text: ""
          font.family: Theme.fontFamilyMono
          font.pixelSize: Math.round(Theme.fontSizeSubhead * clockContainer._scale)
          font.weight: Font.Medium
          font.letterSpacing: 2
          Layout.alignment: Qt.AlignHCenter
          Layout.topMargin: Theme.spaceXs
          property var _c: clockContainer.desktopWidget ? clockContainer.desktopWidget.contrastFor(this) : null
          color: _c ? Qt.rgba(_c.textColor.r, _c.textColor.g, _c.textColor.b, 0.45) : "white"
        }
      }

      Text {
        id: dayText
        text: ""
        font.family: Theme.fontFamilyDisplay
        font.pixelSize: Math.round(Theme.fontSizeHeading * clockContainer._scale)
        font.weight: Font.Bold
        font.letterSpacing: 8
        horizontalAlignment: Text.AlignHCenter
        Layout.alignment: Qt.AlignHCenter
        Layout.bottomMargin: Theme.spaceXs
        property var _c: clockContainer.desktopWidget ? clockContainer.desktopWidget.contrastFor(this) : null
        color: _c ? _c.textColor : "white"
      }

      Text {
        id: dateText
        visible: clockContainer._showDate
        text: ""
        font.family: Theme.fontFamilyMono
        font.pixelSize: Math.round(Theme.fontSizeLabel * clockContainer._scale)
        font.weight: Font.Medium
        font.letterSpacing: 6
        horizontalAlignment: Text.AlignHCenter
        Layout.alignment: Qt.AlignHCenter
        property var _c: clockContainer.desktopWidget ? clockContainer.desktopWidget.contrastFor(this) : null
        color: _c ? Qt.rgba(_c.textColor.r, _c.textColor.g, _c.textColor.b, 0.45) : "white"
      }
    }

    // ── Digital horizontal ─────────────────────────────────────
    RowLayout {
      id: clockRow
      visible: !clockContainer._isAnalog && !clockContainer._isVertical
      spacing: Theme.spaceLg
      Layout.alignment: Qt.AlignHCenter

      ColumnLayout {
        spacing: 0
        Layout.alignment: Qt.AlignVCenter

        Text {
          id: dayTextH
          text: ""
          font.family: Theme.fontFamilyDisplay
          font.pixelSize: Math.round(Theme.fontSizeDisplay * clockContainer._scale)
          font.weight: Font.Bold
          font.letterSpacing: 6
          Layout.bottomMargin: Theme.spaceXs
          property var _c: clockContainer.desktopWidget ? clockContainer.desktopWidget.contrastFor(this) : null
          color: _c ? _c.textColor : "white"

          Text {
            x: 1; y: 2
            text: dayTextH.text
            font: dayTextH.font
            color: dayTextH._c ? dayTextH._c.shadowColor : "black"
            z: -1
          }
        }

        Text {
          id: dateTextH
          visible: clockContainer._showDate
          text: ""
          font.family: Theme.fontFamilyMono
          font.pixelSize: Math.round(Theme.fontSizeLabel * clockContainer._scale)
          font.weight: Font.Medium
          font.letterSpacing: 4
          property var _c: clockContainer.desktopWidget ? clockContainer.desktopWidget.contrastFor(this) : null
          color: _c ? Qt.rgba(_c.textColor.r, _c.textColor.g, _c.textColor.b, 0.45) : "white"
        }
      }

      Rectangle {
        visible: clockContainer._showDate
        width: 1
        Layout.fillHeight: true
        Layout.preferredHeight: Theme.fontSizeDisplay * clockContainer._scale
        property var _c: clockContainer.desktopWidget ? clockContainer.desktopWidget.contrastFor(this) : null
        color: _c ? Qt.rgba(_c.textColor.r, _c.textColor.g, _c.textColor.b, 0.45) : "white"
        Layout.alignment: Qt.AlignVCenter
      }

      ColumnLayout {
        spacing: 0
        Layout.alignment: Qt.AlignVCenter

        Row {
          spacing: Theme.spaceSm
          Layout.alignment: Qt.AlignHCenter

          Text {
            id: dashLeft
            text: "-"
            font.family: Theme.fontFamilyMono
            font.pixelSize: Math.round(Theme.fontSizeHeading * clockContainer._scale)
            font.weight: Font.Light
            property var _c: clockContainer.desktopWidget ? clockContainer.desktopWidget.contrastFor(this) : null
            color: _c ? Qt.rgba(_c.textColor.r, _c.textColor.g, _c.textColor.b, 0.45) : "white"
          }

          Text {
            id: timeLabelH
            text: ""
            font.family: Theme.fontFamilyMono
            font.pixelSize: Math.round(Theme.fontSizeHeading * clockContainer._scale)
            font.weight: Font.Bold
            font.letterSpacing: 4
            property var _c: clockContainer.desktopWidget ? clockContainer.desktopWidget.contrastFor(this) : null
            color: _c ? _c.textColor : "white"
          }

          Text {
            id: dashRight
            text: "-"
            font.family: Theme.fontFamilyMono
            font.pixelSize: Math.round(Theme.fontSizeHeading * clockContainer._scale)
            font.weight: Font.Light
            property var _c: clockContainer.desktopWidget ? clockContainer.desktopWidget.contrastFor(this) : null
            color: _c ? Qt.rgba(_c.textColor.r, _c.textColor.g, _c.textColor.b, 0.45) : "white"
          }

          Text {
            id: ampmLabelH
            visible: !clockContainer._format24h
            text: ""
            font.family: Theme.fontFamilyMono
            font.pixelSize: Math.round(Theme.fontSizeCaption * clockContainer._scale)
            font.weight: Font.Medium
            font.letterSpacing: 2
            property var _c: clockContainer.desktopWidget ? clockContainer.desktopWidget.contrastFor(this) : null
            color: _c ? Qt.rgba(_c.textColor.r, _c.textColor.g, _c.textColor.b, 0.45) : "white"
            anchors.baseline: timeLabelH.baseline
            anchors.baselineOffset: -Theme.spaceXs
          }
        }

        Text {
          id: secLabelH
          visible: clockContainer._showSeconds
          text: ""
          color: clockContainer._accentContrast
          font.family: Theme.fontFamilyMono
          font.pixelSize: Math.round(Theme.fontSizeSubhead * clockContainer._scale)
          font.weight: Font.Medium
          font.letterSpacing: 8
          horizontalAlignment: Text.AlignHCenter
          Layout.alignment: Qt.AlignHCenter
          Layout.topMargin: Theme.spaceXs
        }
      }
    }

    Column {
      id: analogCol
      visible: clockContainer._isAnalog
      spacing: Theme.spaceSm

      Canvas {
        id: analogClock
        readonly property int _size: Math.round(240 * clockContainer._scale)
        width: _size
        height: _size
        implicitWidth: _size
        implicitHeight: _size
        antialiasing: true

        onPaint: {
          var ctx = getContext("2d")
          var S = _size
          var cx = S / 2
          var cy = S / 2
          var R = cx - Theme.spaceSm
          ctx.clearRect(0, 0, S, S)

          var now = DateTimeService.currentDate
          if (!now) return
          var hours = now.getHours() % 12
          var minutes = now.getMinutes()
          var seconds = now.getSeconds()
          var millis = now.getMilliseconds()

          var _c = clockContainer.desktopWidget ? clockContainer.desktopWidget.contrastFor(analogCol) : null
          var text = _c ? _c.textColor : "white"
          var dim = _c ? Qt.rgba(_c.textColor.r, _c.textColor.g, _c.textColor.b, 0.45) : "white"
          var accent = clockContainer._accentContrast

          ctx.save()
          ctx.shadowColor = "rgba(0,0,0,0.25)"
          ctx.shadowBlur = 12
          ctx.shadowOffsetX = 0
          ctx.shadowOffsetY = 4

          ctx.beginPath()
          ctx.arc(cx, cy, R, 0, 2 * Math.PI)
          ctx.fillStyle = clockContainer._surfaceColor
          ctx.fill()
          ctx.restore()

          ctx.beginPath()
          ctx.arc(cx, cy, R - 1, 0, 2 * Math.PI)
          ctx.strokeStyle = Qt.rgba(text.r, text.g, text.b, 0.08)
          ctx.lineWidth = 1
          ctx.stroke()

          var tickR = R - Theme.spaceXs
          for (var i = 0; i < 60; i++) {
            var a = (i * 6 - 90) * Math.PI / 180
            var isHour = i % 5 === 0
            var innerR = tickR - (isHour ? Theme.spaceSm : Theme.spaceXs)
            var x1 = cx + innerR * Math.cos(a)
            var y1 = cy + innerR * Math.sin(a)
            var x2 = cx + tickR * Math.cos(a)
            var y2 = cy + tickR * Math.sin(a)

            ctx.beginPath()
            ctx.moveTo(x1, y1)
            ctx.lineTo(x2, y2)
            ctx.strokeStyle = isHour ? text : dim
            ctx.lineWidth = isHour ? 2 : 1
            ctx.lineCap = "round"
            ctx.stroke()
          }

          var smoothSeconds = seconds + millis / 1000
          var smoothMinutes = minutes + smoothSeconds / 60
          var smoothHours = hours + smoothMinutes / 60

          var hourAngle = (smoothHours * 30 - 90) * Math.PI / 180
          var minuteAngle = (smoothMinutes * 6 - 90) * Math.PI / 180
          var secondAngle = (smoothSeconds * 6 - 90) * Math.PI / 180

          ctx.save()
          ctx.translate(cx, cy)
          ctx.rotate(hourAngle)
          ctx.beginPath()
          ctx.moveTo(-Theme.spaceXs, 0)
          ctx.lineTo(R * 0.06, -3)
          ctx.lineTo(R * 0.5, -1.5)
          ctx.lineTo(R * 0.5, 1.5)
          ctx.lineTo(R * 0.06, 3)
          ctx.closePath()
          ctx.fillStyle = text
          ctx.fill()
          ctx.restore()

          ctx.save()
          ctx.translate(cx, cy)
          ctx.rotate(minuteAngle)
          ctx.beginPath()
          ctx.moveTo(-5, 0)
          ctx.lineTo(R * 0.06, -2.2)
          ctx.lineTo(R * 0.75, -1)
          ctx.lineTo(R * 0.75, 1)
          ctx.lineTo(R * 0.06, 2.2)
          ctx.closePath()
          ctx.fillStyle = text
          ctx.fill()
          ctx.restore()

          ctx.save()
          ctx.translate(cx, cy)
          ctx.rotate(secondAngle)

          ctx.beginPath()
          ctx.moveTo(0, 0)
          ctx.lineTo(-R * 0.15, 0)
          ctx.strokeStyle = accent
          ctx.lineWidth = 1.5
          ctx.lineCap = "round"
          ctx.stroke()

          ctx.beginPath()
          ctx.moveTo(0, 0)
          ctx.lineTo(R * 0.82, 0)
          ctx.strokeStyle = accent
          ctx.lineWidth = 1.5
          ctx.lineCap = "round"
          ctx.stroke()
          ctx.restore()

          ctx.beginPath()
          ctx.arc(cx, cy, Theme.spaceXs, 0, 2 * Math.PI)
          ctx.fillStyle = accent
          ctx.fill()
          ctx.beginPath()
          ctx.arc(cx, cy, Theme.spaceXs / 2, 0, 2 * Math.PI)
          ctx.fillStyle = text
          ctx.fill()
        }

        onVisibleChanged: if (visible) requestPaint()
        Component.onCompleted: requestPaint()
      }

      Text {
        id: analogDateText
        visible: clockContainer._showDate
        text: Qt.formatDateTime(DateTimeService.currentDate, "dddd").toUpperCase()
          + "  " + Qt.formatDateTime(DateTimeService.currentDate, "MMMM d").toUpperCase()
        font.family: Theme.fontFamilyMono
        font.pixelSize: Math.round(Theme.fontSizeLabel * clockContainer._scale)
        font.letterSpacing: 4
        horizontalAlignment: Text.AlignHCenter
        anchors.horizontalCenter: parent.horizontalCenter
        property var _c: clockContainer.desktopWidget ? clockContainer.desktopWidget.contrastFor(this) : null
        color: _c ? Qt.rgba(_c.textColor.r, _c.textColor.g, _c.textColor.b, 0.45) : "white"
      }
    }

    Component.onCompleted: {
      clockContainer._updateClockText()
    }

    Connections {
      target: WallpaperService
      function onMapReadyChanged() {
        if (clockContainer._isAnalog) Qt.callLater(function() { analogClock.requestPaint() })
      }
    }

    Connections {
      target: DateTimeService
      function onCurrentDateChanged() {
        clockContainer._updateClockText()
        if (clockContainer._isAnalog) analogClock.requestPaint()
      }
    }
  }
}
