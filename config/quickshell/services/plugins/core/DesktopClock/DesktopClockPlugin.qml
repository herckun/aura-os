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
    defaultLayout: { "desktop": { order: 10, position: { x: 0.72, y: 0.07 }, settings: { showBackground: false } } },
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
        description: "Vertical, minimal, or horizontal arrangement",
        type: "select",
        options: ["vertical", "minimal", "horizontal"],
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
      : clockContainer._isMinimal ? minimalCol.implicitWidth
      : (clockContainer._isVertical ? clockCol.implicitWidth : clockRow.implicitWidth)
    height: clockContainer._isAnalog ? analogCol.implicitHeight
      : clockContainer._isMinimal ? minimalCol.implicitHeight
      : (clockContainer._isVertical ? clockCol.implicitHeight : clockRow.implicitHeight)

    property bool _isAnalog: PluginService.getPluginSetting("desktopclock", "clockStyle", "desktop") === "analog"
    property string _layout: PluginService.getPluginSetting("desktopclock", "clockLayout", "desktop") ?? "vertical"
    property bool _isMinimal: _layout === "minimal"
    property bool _isVertical: _layout !== "horizontal" && _layout !== "minimal"
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
      var h12 = now.getHours() % 12
      if (h12 === 0) h12 = 12
      var mm = Qt.formatDateTime(now, "mm")
      var hh = is24 ? Qt.formatDateTime(now, "HH") : String(h12).padStart(2, "0")

      if (!clockContainer._isAnalog && clockContainer._isVertical) {
        timeHH.text = hh
        timeMM.text = mm
        if (clockContainer._showSeconds) timeSS.text = Qt.formatDateTime(now, "ss")
        if (!is24) timeAMPM.text = Qt.formatDateTime(now, "AP")
        dayText.text = Qt.formatDateTime(now, "dddd").toUpperCase()
        if (clockContainer._showDate) dateText.text = Qt.formatDateTime(now, "MMMM d").toUpperCase()
      }

      if (!clockContainer._isAnalog && clockContainer._isMinimal) {
        timeTextM.text = hh + ":" + mm
        if (clockContainer._showSeconds) timeSSM.text = Qt.formatDateTime(now, "ss")
        if (!is24) timeAMPMM.text = Qt.formatDateTime(now, "AP")
        dayTextM.text = Qt.formatDateTime(now, "dddd").toUpperCase()
        if (clockContainer._showDate) dateTextM.text = Qt.formatDateTime(now, "MMMM d").toUpperCase()
      }

      if (!clockContainer._isAnalog && !clockContainer._isVertical && !clockContainer._isMinimal) {
        dayTextH.text = Qt.formatDateTime(now, "dddd").toUpperCase()
        if (clockContainer._showDate) dateTextH.text = Qt.formatDateTime(now, "MMMM d").toUpperCase()
        timeLabelH.text = hh + ":" + mm
        if (!is24) ampmLabelH.text = Qt.formatDateTime(now, "AP")
        if (clockContainer._showSeconds) secLabelH.text = Qt.formatDateTime(now, "ss")
      }
    }

    property int _cfgVersion: 0
    readonly property color _bgColor: {
      var _v = _cfgVersion
      var sampled = (Store.desktop.widgets["desktopclock"] || {}).bgColor || ""
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
          Layout.topMargin: -Math.round(timeHH.font.pixelSize * 0.22)
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
          color: clockContainer._accentContrast
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

      Rectangle {
        Layout.alignment: Qt.AlignHCenter
        Layout.bottomMargin: Theme.spaceSm
        width: Math.round(36 * clockContainer._scale)
        height: 3
        radius: 1.5
        color: clockContainer._accentContrast
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

    ColumnLayout {
      id: minimalCol
      visible: !clockContainer._isAnalog && clockContainer._isMinimal
      spacing: 0

      Text {
        id: timeTextM
        text: ""
        font.family: Theme.fontFamilyDisplay
        font.pixelSize: Math.round(Theme.fontSizeDisplayXl * clockContainer._scale)
        font.weight: Font.Bold
        font.letterSpacing: 2
        Layout.alignment: Qt.AlignHCenter
        property var _c: clockContainer.desktopWidget ? clockContainer.desktopWidget.contrastFor(this) : null
        color: _c ? _c.textColor : "white"

        Text {
          x: 1; y: 2
          text: timeTextM.text
          font: timeTextM.font
          color: timeTextM._c ? timeTextM._c.shadowColor : "black"
          z: -1
        }
      }

      Row {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Theme.spaceXs
        spacing: Theme.spaceSm
        visible: clockContainer._showSeconds || !clockContainer._format24h

        Text {
          id: timeSSM
          visible: clockContainer._showSeconds
          text: ""
          font.family: Theme.fontFamilyMono
          font.pixelSize: Math.round(Theme.fontSizeSubhead * clockContainer._scale)
          font.weight: Font.Medium
          font.letterSpacing: 8
          color: clockContainer._accentContrast
        }

        Text {
          id: timeAMPMM
          visible: !clockContainer._format24h
          text: ""
          font.family: Theme.fontFamilyMono
          font.pixelSize: Math.round(Theme.fontSizeSubhead * clockContainer._scale)
          font.weight: Font.Medium
          font.letterSpacing: 2
          property var _c: clockContainer.desktopWidget ? clockContainer.desktopWidget.contrastFor(this) : null
          color: _c ? Qt.rgba(_c.textColor.r, _c.textColor.g, _c.textColor.b, 0.45) : "white"
        }
      }

      Text {
        id: dayTextM
        text: ""
        font.family: Theme.fontFamilyDisplay
        font.pixelSize: Math.round(Theme.fontSizeHeading * clockContainer._scale)
        font.weight: Font.Bold
        font.letterSpacing: 8
        horizontalAlignment: Text.AlignHCenter
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Theme.spaceSm
        Layout.bottomMargin: Theme.spaceXs
        property var _c: clockContainer.desktopWidget ? clockContainer.desktopWidget.contrastFor(this) : null
        color: _c ? _c.textColor : "white"
      }

      Text {
        id: dateTextM
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
      visible: !clockContainer._isAnalog && !clockContainer._isVertical && !clockContainer._isMinimal
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
        width: 3
        radius: 1.5
        Layout.fillHeight: true
        Layout.preferredHeight: Theme.fontSizeDisplay * clockContainer._scale
        color: clockContainer._accentContrast
        Layout.alignment: Qt.AlignVCenter
      }

      ColumnLayout {
        spacing: 0
        Layout.alignment: Qt.AlignVCenter

        Row {
          spacing: Theme.spaceSm
          Layout.alignment: Qt.AlignHCenter

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

          var face = Theme.backgroundSecondary
          var text = Theme.contrastTextColor(face)
          var dim = Qt.rgba(text.r, text.g, text.b, 0.35)
          var accent = Theme.accent

          ctx.save()
          ctx.shadowColor = "rgba(0,0,0,0.35)"
          ctx.shadowBlur = 16
          ctx.shadowOffsetX = 0
          ctx.shadowOffsetY = 4

          ctx.beginPath()
          ctx.arc(cx, cy, R, 0, 2 * Math.PI)
          ctx.fillStyle = Qt.rgba(face.r, face.g, face.b, 0.96)
          ctx.fill()
          ctx.restore()

          var dotRing = R * 0.85
          for (var i = 0; i < 12; i++) {
            var a = (i * 30 - 90) * Math.PI / 180
            var isQuarter = i % 3 === 0
            ctx.beginPath()
            ctx.arc(cx + dotRing * Math.cos(a), cy + dotRing * Math.sin(a),
                    R * (isQuarter ? 0.035 : 0.02), 0, 2 * Math.PI)
            ctx.fillStyle = isQuarter ? text : dim
            ctx.fill()
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
          ctx.moveTo(0, 0)
          ctx.lineTo(R * 0.42, 0)
          ctx.strokeStyle = text
          ctx.lineWidth = Math.max(5, R * 0.075)
          ctx.lineCap = "round"
          ctx.stroke()
          ctx.restore()

          ctx.save()
          ctx.translate(cx, cy)
          ctx.rotate(minuteAngle)
          ctx.beginPath()
          ctx.moveTo(0, 0)
          ctx.lineTo(R * 0.62, 0)
          ctx.strokeStyle = text
          ctx.lineWidth = Math.max(4, R * 0.055)
          ctx.lineCap = "round"
          ctx.stroke()
          ctx.restore()

          ctx.save()
          ctx.translate(cx, cy)
          ctx.rotate(secondAngle)
          ctx.beginPath()
          ctx.moveTo(-R * 0.1, 0)
          ctx.lineTo(R * 0.72, 0)
          ctx.strokeStyle = accent
          ctx.lineWidth = Math.max(1.5, R * 0.012)
          ctx.lineCap = "round"
          ctx.stroke()
          ctx.restore()

          ctx.beginPath()
          ctx.arc(cx, cy, Math.max(5, R * 0.055), 0, 2 * Math.PI)
          ctx.fillStyle = Qt.rgba(text.r, text.g, text.b, 0.9)
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
