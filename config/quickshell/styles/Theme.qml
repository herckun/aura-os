pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../core"
import "../services"

Singleton {
  id: root

  readonly property bool darkMode: _relativeLuminance(background) < 0.5

  property var _data: ({})
  property var _theme: ({})

  readonly property string themeId: Store.theme.name || "aura"
  readonly property string themeName: _theme.name || "AURA"

  readonly property color background: _c("background")
  readonly property color backgroundSecondary: _c("backgroundSecondary")
  readonly property color backgroundTertiary: _c("backgroundTertiary")
  readonly property color border: _c("border")
  readonly property color borderVisible: _c("borderVisible")

  readonly property color panelBackground: transparencyEnabled ? Qt.rgba(background.r, background.g, background.b, 0.85) : background
  readonly property color panelBackgroundSecondary: transparencyEnabled ? Qt.rgba(backgroundSecondary.r, backgroundSecondary.g, backgroundSecondary.b, 0.85) : backgroundSecondary

  readonly property color textDisplay: _c("textDisplay")
  readonly property color textPrimary: _c("textPrimary")
  readonly property color textSecondary: _c("textSecondary")
  readonly property color textDisabled: _c("textDisabled")

  readonly property color success: _c("success")
  readonly property color warning: _c("warning")
  readonly property color error: _c("error")
  readonly property color interactive: _c("interactive")

  readonly property bool monochrome: Store.theme.monochrome
  property var predefinedAccents: [
    { color: "#D71921", name: "RED" },
    { color: "#E85D04", name: "ORANGE" },
    { color: "#D4A843", name: "GOLD" },
    { color: "#4A9E5C", name: "GREEN" },
    { color: "#5B9BF6", name: "BLUE" },
    { color: "#7B2FBE", name: "PURPLE" },
    { color: "#E84393", name: "PINK" },
    { color: "#FFFFFF", name: "WHITE" }
  ]

  readonly property var accentColors: {
    var result = predefinedAccents.slice()
    var wpAccents = WallpaperService.wallpaperAccents || []
    for (var i = 0; i < wpAccents.length; i++) {
      result.push({ color: wpAccents[i], name: "WALL" + (i + 1) })
    }
    return result
  }

  readonly property color monoAccent: _theme.monoAccent ? Qt.color(_theme.monoAccent) : Qt.color("#E8E8E8")
  readonly property color accentPure: _ensureVisibleAccent(Qt.color(Store.theme.accent))
  readonly property color accent: monochrome ? monoAccent : accentPure

  readonly property color controlBackground: _c("controlBackground")
  readonly property color controlBackgroundHover: _c("controlBackgroundHover")
  readonly property color controlBackgroundPressed: _c("controlBackgroundPressed")

  readonly property color controlBorder: _c("controlBorder")
  readonly property color controlBorderHover: _c("controlBorderHover")
  readonly property color controlBorderPressed: _c("controlBorderPressed")
  readonly property color buttonHoverOverlay: _c("buttonHoverOverlay")
  readonly property color buttonBorderHover: _c("buttonBorderHover")
  readonly property color buttonBorderPressed: _c("buttonBorderPressed")
  readonly property color hoverOverlay: _c("hoverOverlay")

  readonly property color separator: _c("separator")

  readonly property color workspaceActive: _c("workspaceActive")
  readonly property color workspaceInactive: _c("workspaceInactive")
  readonly property color controlBackgroundActive: _c("controlBackgroundActive")
  readonly property color borderActive: _c("borderActive")

  readonly property bool animationsEnabled: AppearanceService.animationsEnabled
  readonly property bool blurEnabled: AppearanceService.blurEnabled
  readonly property bool transparencyEnabled: AppearanceService.transparencyEnabled
  readonly property int shellMode: ModeService.mode

  readonly property string _styleKey: ModeService.modeKey
  readonly property var _style: _data.styles ? _data.styles[_styleKey] || _data.styles["default"] || {} : {}
  readonly property var _mode: _style.mode || {}

  readonly property int toastDuration: _mode.toastDuration || 5000
  readonly property int toastWidth: _mode.toastWidth || 300
  readonly property int hyprOuterGap: _mode.hyprOuterGap || 8
  readonly property string hyprInnerGap: _mode.hyprInnerGap || "4,8"

  readonly property int spaceXxs: _s("xxs")
  readonly property int space2: _s("2")
  readonly property int spaceXs: _s("xs")
  readonly property int spaceSm: _s("sm")
  readonly property int spaceMd: _s("md")
  readonly property int spaceLg: _s("lg")
  readonly property int spaceXl: _s("xl")
  readonly property int space2xl: _s("2xl")

  readonly property int radiusXs: _r("xs")
  readonly property int radiusSmall: _r("sm")
  readonly property int radiusMedium: _r("md")
  readonly property int radiusLarge: _r("lg")
  readonly property int radiusXLarge: _r("xl")
  readonly property int radiusPill: 999
  readonly property int radiusUI: _r("ui")

  readonly property int controlHeight: _sz("controlHeight")
  readonly property int controlHeightSmall: _sz("controlHeightSmall")
  readonly property int controlWidth: _sz("controlWidth")
  readonly property int controlSpacing: _sz("controlSpacing")
  readonly property int controlPadding: _sz("controlPadding")
  readonly property int barHeight: _sz("barHeight")
  readonly property int controlCenterWidth: _sz("controlCenterWidth")
  readonly property int cardPadding: _sz("cardPadding")
  readonly property int cardSpacing: _sz("cardSpacing")

  readonly property int borderWidth: _b("width")
  readonly property real borderAlpha: _b("alpha")

  readonly property int animationFast: animationsEnabled ? _a("fast") : 0
  readonly property int animationNormal: animationsEnabled ? _a("normal") : 0
  readonly property int animationSlow: animationsEnabled ? _a("slow") : 0
  readonly property int animationVerySlow: (animationsEnabled ? _a("slow") : 0) * 10

  readonly property string fontFamily: _userFont(Store.appearance.fontUi, "fontFamily")
  readonly property string fontFamilyDisplay: _userFont(Store.appearance.fontDisplay, "fontFamilyDisplay")
  readonly property string fontFamilyDeco: _t("fontFamilyDeco")
  readonly property string fontFamilyMono: _userFont(Store.appearance.fontMono, "fontFamilyMono")
  readonly property string fontFamilyIcons: _t("fontFamilyIcons")

  readonly property int fontSizeMicro: _ts("micro")
  readonly property int fontSizeCaption: _ts("caption")
  readonly property int fontSizeLabel: _ts("label")
  readonly property int fontSizeBody: _ts("body")
  readonly property int fontSizeSubhead: _ts("subhead")
  readonly property int fontSizeTitle: _ts("title")
  readonly property int fontSizeTitle2: _ts("title2")
  readonly property int fontSizeHeading: _ts("heading")
  readonly property int fontSizeDisplay: _ts("display")
  readonly property int fontSizeDisplayLarge: _ts("displayLarge")
  readonly property int fontSizeDisplayXl: _ts("displayXl")


  readonly property var sizePresets: {
    var raw = _data.sizes || {}
    var scale = (_style.typography && _style.typography.fontSizeScale ? _style.typography.fontSizeScale : 1.0) * fontUserScale
    var out = {}
    for (var k in raw) {
      var p = raw[k]
      out[k] = {
        fontSize: Math.round(p.fontSize * scale),
        iconSize: p.iconSize,
        dim: Math.round(p.dim * scale),
        padding: Math.round(p.padding * scale)
      }
    }
    return out
  }

  function _c(key: string): color {
    var p = root._theme.colors
    if (p && p[key]) return Qt.color(p[key])
    var v = _data.colors ? _data.colors[key] : null
    return v ? Qt.color(v) : "#000000"
  }

  function _s(key: string): int {
    return _style.spacing ? (_style.spacing[key] ?? 0) : 0
  }

  function _r(key: string): int {
    return _style.radius ? (_style.radius[key] ?? 0) : 0
  }

  function _sz(key: string): int {
    return _style.sizing ? (_style.sizing[key] ?? 0) : 0
  }

  function _b(key: string): var {
    return _style.border ? (_style.border[key] ?? 0) : 0
  }

  function _a(key: string): int {
    return _style.animation ? (_style.animation[key] ?? 0) : 0
  }

  readonly property var _installedFonts: Qt.fontFamilies()

  function _t(key: string): string {
    var f = root._theme.fonts
    var raw = (f && f[key]) || (_data.typography ? (_data.typography[key] || "") : "")
    return _firstAvailableFamily(raw)
  }

  function _userFont(pref: string, key: string): string {
    if (pref && root._installedFonts.indexOf(pref) >= 0) return pref
    return _t(key)
  }

  readonly property real fontUserScale: Math.max(0.7, Math.min(1.4, Store.appearance.fontScale || 1.0))

  function _firstAvailableFamily(raw: string): string {
    if (!raw) return ""
    var parts = raw.split(",")
    var first = ""
    for (var i = 0; i < parts.length; i++) {
      var name = parts[i].trim().replace(/^["']+|["']+$/g, "")
      if (!name || name === "sans-serif" || name === "monospace" || name === "system-ui" || name === "serif")
        continue
      if (!first) first = name
      if (root._installedFonts.indexOf(name) >= 0) return name
    }
    return first
  }

  function _ts(key: string): int {
    var base = _data.typography && _data.typography.sizes ? (_data.typography.sizes[key] ?? 11) : 11
    var scale = _style.typography && _style.typography.fontSizeScale ? _style.typography.fontSizeScale : 1.0
    return Math.round(base * scale * fontUserScale)
  }

  function _luminance(c: color): real {
    return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
  }

  function _linearize(c: real): real {
    return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4)
  }

  function _relativeLuminance(c: color): real {
    return 0.2126 * _linearize(c.r) + 0.7152 * _linearize(c.g) + 0.0722 * _linearize(c.b)
  }

  function contrastTextColor(bgColor: color): color {
    return _relativeLuminance(bgColor) > 0.36 ? Qt.color("#000000") : Qt.color("#FFFFFF")
  }

  function overlay(alpha: real): color {
    var t = textPrimary
    return Qt.rgba(t.r, t.g, t.b, alpha)
  }

  function variantColor(variant: string): color {
    switch (variant) {
    case "success": return success
    case "warning": return warning
    case "error": return error
    case "interactive": return interactive
    default: return accent
    }
  }

  function _ensureVisibleAccent(c: color): color {
    var lum = _luminance(c)
    if (!darkMode) {
      if (lum <= 0.8) return c
      var darkened = Qt.hsla(c.hslHue, c.hslSaturation, Math.min(c.hslLightness, 0.4), 1)
      return _luminance(darkened) <= 0.8 ? darkened : Qt.color("#000000")
    }
    if (lum >= 0.2) return c
    var brightened = Qt.hsla(c.hslHue, c.hslSaturation, Math.max(c.hslLightness, 0.45), 1)
    var lum2 = _luminance(brightened)
    if (lum2 >= 0.2) return brightened
    return Qt.color("#FFFFFF")
  }

  function setAccent(hex: string): void {
    Store.theme.accent = _ensureVisibleAccent(Qt.color(hex)).toString()
    Store.theme.accentManual = true
  }

  function setMonochrome(on: bool): void {
    Store.theme.monochrome = on
  }

  Process {
    id: _dataLoader
    command: ["cat", Qt.resolvedUrl("theme.json").toString().replace("file://", "")]
    stdout: StdioCollector { waitForEnd: true }
    onExited: {
      try {
        root._data = JSON.parse(stdout.text)
      } catch(e) {
        root._data = {
          colors: {
            background: "#000000", backgroundSecondary: "#111111", backgroundTertiary: "#1A1A1A",
            border: "#222222", borderVisible: "#333333",
            textDisplay: "#FFFFFF", textPrimary: "#E8E8E8", textSecondary: "#999999", textDisabled: "#666666",
            success: "#4A9E5C", warning: "#D4A843", error: "#D44A4A", interactive: "#5B9BF6",
            controlBackground: "#111111", controlBackgroundHover: "#1A1A1A", controlBackgroundPressed: "#222222",
            controlBackgroundActive: "#1A1A1A", controlBorder: "#222222", controlBorderHover: "#333333",
            controlBorderPressed: "#444444", separator: "#222222", workspaceActive: "#FFFFFF",
            workspaceInactive: "#333333", borderActive: "#444444",
            buttonHoverOverlay: "#282828", buttonBorderHover: "#3A3A3A", buttonBorderPressed: "#4A4A4A",
    hoverOverlay: "#0AFFFFFF"
          },
          typography: {
            fontFamily: "Space Grotesk", fontFamilyDisplay: "Doto", fontFamilyMono: "Space Mono",
            fontFamilyIcons: "JetBrainsMono Nerd Font Mono"
          }
        }
      }
    }
  }

  onThemeIdChanged: _themeReload.restart()

  Timer {
    id: _themeReload
    interval: 1
    repeat: false
    onTriggered: {
      _themeLoader.running = false
      _themeLoader.running = true
    }
  }

  Process {
    id: _themeLoader
    command: ["cat", Qt.resolvedUrl("themes/").toString().replace("file://", "") + root.themeId + ".json"]
    stdout: StdioCollector { waitForEnd: true }
    onExited: {
      try {
        root._theme = JSON.parse(stdout.text)
      } catch(e) {
        root._theme = ({})
      }
    }
  }

  Component.onCompleted: {
    _dataLoader.running = true
    _themeLoader.running = true
  }
}
