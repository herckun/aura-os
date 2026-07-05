pragma Singleton
import QtQml
import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"
import "../system"

Singleton {
  id: svc

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC STATE
  // ═══════════════════════════════════════════════════════════════

  property string wallpaperPath: ""
  property bool wallpaperReady: false
  property string sourceWallpaperPath: ""

  property color primary: "#FFFFFF"
  property color primaryLight: "#E8E8E8"
  property color primaryDark: "#999999"
  property color primaryMuted: "#666666"
  property color secondary: "#999999"
  property color tertiary: "#666666"
  property color background: "#000000"
  property color surface: "#111111"
  property color accent: "#D71921"
  property list<string> wallpaperAccents: []

  property string downloadStatus: ""
  property bool pickerOpen: false
  property var wallpaperHistory: []
  property bool autoCycle: false
  property int autoCycleMinutes: 30

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════

  function init(): void {}

  function setMonochrome(on: bool): void {
    svc._mono = on
    Store.theme.accentManual = false
    if (!on && wallpaperAccents.length > 0) {
      Store.theme.accent = wallpaperAccents[0]
    } else if (on) {
      Store.theme.accent = "#E8E8E8"
    }
    if (_startupDone) svc._userChangedWallpaper = true
    svc.refresh()
  }

  function refresh(): void {
    if (svc.sourceWallpaperPath.length > 0) {
      svc.setWallpaper(svc.sourceWallpaperPath, true)
    }
  }

  function setWallpaper(path: string, silent: bool): void {
    if (!path || path.length === 0) return
    if (_startupDone) svc._userChangedWallpaper = true

    Store.theme.accentManual = false
    svc.sourceWallpaperPath = path
    svc.addToHistory(path)

    var command = [AppInfo.configHome + "/features/wallpaper/engine.sh"]
    if (svc._mono) command.push("--monochrome")
    command.push(path)

    ProcessPool.runQueued("Set wallpaper", command, {
      id: "set-wallpaper",
      silent: silent || false,
      callback: function() {
        svc._pollWallpaper()
      }
    })
  }

  function cycleWallpaper(): void {
    if (ProcessPool.isBusy("cycle-wallpaper")) return
    var dir = AppInfo.wallpaperDir
    ProcessPool.runTracked("List wallpapers", [
      "sh", "-c", "find '" + dir + "' -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) | sort"
    ], {
      id: "cycle-wallpaper",
      callback: function(r) {
        if (r.exitCode !== 0 || !r.stdout) return
        var files = r.stdout.trim().split("\n").filter(function(f) { return f.length > 0 })
        if (files.length === 0) return
        var current = svc.sourceWallpaperPath || svc.wallpaperPath
        var idx = files.indexOf(current)
        var next = files[(idx + 1) % files.length]
        if (next === current) return
        svc.setWallpaper(next, true)
        if (cycleTimer.running) cycleTimer.restart()
      }
    })
  }

  function setAutoCycle(on: bool): void {
    svc.autoCycle = on
    Store.wallpaper.autoCycle = on
  }

  function setAutoCycleMinutes(minutes: int): void {
    svc.autoCycleMinutes = minutes
    Store.wallpaper.autoCycleMinutes = minutes
    if (cycleTimer.running) cycleTimer.restart()
  }

  function downloadRandom(): void {
    downloadRandomType("random")
  }

  function downloadRandomType(type: string): void {
    var validTypes = ["random", "anime", "monochrome"]
    if (validTypes.indexOf(type) === -1) type = "random"
    downloadStatus = "DOWNLOADING..."

    var _dlTimeout = _startDownloadTimeout()

    var prefix = type === "anime" ? "anime" : type === "monochrome" ? "mono" : "general"
    var apiParams = "categories=111&purity=100&sorting=random&ratios=16x9&atleast=1920x1080"
    if (type === "anime") {
      apiParams = "categories=010&purity=100&sorting=random&ratios=16x9&atleast=1920x1080"
    } else if (type === "monochrome") {
      apiParams += "&q=monochrome+black+white+minimal"
    }

    RequestService.get("https://wallhaven.cc/api/v1/search?" + apiParams, function(resp) {
      if (!resp.ok || !resp.data || !resp.data.data || resp.data.data.length === 0) {
        _fallbackDownload(type, prefix, _dlTimeout)
        return
      }

      var entries = resp.data.data
      var idx = Math.floor(Math.random() * Math.min(entries.length, 50))
      var imgUrl = entries[idx] && entries[idx].path
      if (!imgUrl) {
        _fallbackDownload(type, prefix, _dlTimeout)
        return
      }

      _downloadImage(imgUrl, type, prefix, _dlTimeout)
    })
  }

  function _fallbackDownload(type: string, prefix: string, timeout: var): void {
    var fallbackUrl = type === "monochrome"
      ? "https://picsum.photos/1920/1080?grayscale"
      : "https://picsum.photos/1920/1080"
    _downloadImage(fallbackUrl, type, prefix, timeout)
  }

  function _downloadImage(url: string, type: string, prefix: string, timeout: var): void {
    var dir = AppInfo.wallpaperDir
    var ts = Math.floor(Date.now() / 1000)
    var dest = dir + "/" + prefix + "-" + ts + ".jpg"

    ProcessPool.runTracked("Download wallpaper image", [
      "sh", "-c", "mkdir -p '" + dir + "' && curl -sfL --max-time 30 -o '" + dest + "' '" + url + "' && echo '" + dest + "'"
    ], {
      id: "download-wallpaper",
      callback: function(r) {
        _clearDownloadTimeout(timeout)
        if (r.exitCode !== 0 || !r.stdout || r.stdout.trim().length === 0) {
          svc.downloadStatus = "FAILED"
          svc._clearDownloadStatusLater()
          return
        }

        var path = r.stdout.trim()
        if (path.startsWith("/")) {
          svc.setWallpaper(path)
          svc.downloadStatus = ""
        } else {
          svc.downloadStatus = "FAILED"
          svc._clearDownloadStatusLater()
        }
      }
    })
  }

  property var _downloadTimer: null

  function _startDownloadTimeout(): var {
    var timer = Qt.createQmlObject("import QtQuick; Timer { repeat: false; interval: 45000 }", svc)
    timer.triggered.connect(function() {
      if (svc.downloadStatus === "DOWNLOADING...") {
        svc.downloadStatus = "FAILED"
        svc._clearDownloadStatusLater()
      }
      timer.destroy()
    })
    timer.start()
    return timer
  }

  function _clearDownloadTimeout(timer: var): void {
    if (timer) {
      timer.stop()
      timer.destroy()
    }
  }

  function _clearDownloadStatusLater(): void {
    if (_downloadTimer) { _downloadTimer.stop(); _downloadTimer.destroy() }
    _downloadTimer = Qt.createQmlObject("import QtQuick; Timer { repeat: false; interval: 5000 }", svc)
    _downloadTimer.triggered.connect(function() {
      svc.downloadStatus = ""
      _downloadTimer.destroy()
      _downloadTimer = null
    })
    _downloadTimer.start()
  }

  function pickWallpaper(): void {
    svc.pickerOpen = true
    var wpDir = AppInfo.wallpaperDir
    ProcessPool.runTracked("Pick wallpaper",
      "mkdir -p '" + wpDir + "' && kdialog --getopenfilename '" + wpDir + "' '*.jpg *.png *.jpeg *.webp'",
      {
        id: "pick-wallpaper",
        shell: true,
        callback: function(r) {
          svc.pickerOpen = false
          if (r.exitCode === 0 && r.stdout.trim().length > 0) {
            svc.setWallpaper(r.stdout.trim())
          }
        }
      }
    )
  }

  function addToHistory(path: string): void {
    if (!path || path.length === 0) return
    var history = svc.wallpaperHistory.filter(function(h) { return h.path !== path })
    history.unshift({ path: path, time: Date.now() })
    if (history.length > 12) history = history.slice(0, 12)
    svc.wallpaperHistory = history
    Store.wallpaper.history = history
  }

  function removeFromHistory(path: string): void {
    var history = svc.wallpaperHistory.filter(function(h) { return h.path !== path })
    svc.wallpaperHistory = history
    Store.wallpaper.history = history
  }

  // ═══════════════════════════════════════════════════════════════
  //  INTERNAL STATE
  // ═══════════════════════════════════════════════════════════════

  property bool _mono: false
  property bool _userChangedWallpaper: false
  property bool _startupDone: false

  property var _pollHandle: null
  property var _setHandle: null

  readonly property string _cacheDir: AppInfo.cacheHome

  readonly property int _basePollInterval: 3000
  readonly property int _pollInterval: PerformanceService.scaleInterval(_basePollInterval)

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════

  function _loadHistory(): void {
    var saved = Store.wallpaper.history
    svc.wallpaperHistory = Array.isArray(saved) ? saved.slice() : []
  }

  function _pollWallpaper(): void {
    if (_pollHandle && ProcessPool.isRunning(_pollHandle)) {
      Qt.callLater(svc._pollWallpaper)
      return
    }

    var script = "CACHE=\"" + _cacheDir + "\"; " +
      "P=$(cat \"$CACHE/palette.json\" 2>/dev/null || echo '{}'); " +
      "W=$(cat \"$CACHE/current-wallpaper\" 2>/dev/null || echo ''); " +
      "A=$(cat \"$CACHE/wallpaper-accents.json\" 2>/dev/null || echo '[]'); " +
      "printf '{\"palette\":%s,\"wallpaper\":\"%s\",\"accents\":%s}' \"$P\" \"$(printf '%s' \"$W\" | tr '\\n' ' ')\" \"$A\""

    _pollHandle = ProcessPool.runTracked("Poll wallpaper", script, {
      id: "wallpaper-poll",
      shell: true,
      callback: function(r) {
        _pollHandle = null

        var output = r.stdout
        if (!output || !output.trim()) return

        var data
        try {
          data = JSON.parse(output.trim())
        } catch (e) {
          return
        }

        if (data.palette) {
          try {
            var json = data.palette
            if (json.primary) svc.primary = json.primary
            if (json.primaryLight) svc.primaryLight = json.primaryLight
            if (json.primaryDark) svc.primaryDark = json.primaryDark
            if (json.primaryMuted) svc.primaryMuted = json.primaryMuted
            if (json.secondary) svc.secondary = json.secondary
            if (json.tertiary) svc.tertiary = json.tertiary
            if (json.background) svc.background = json.background
            if (json.surface) svc.surface = json.surface
            svc.accent = svc.primary
          } catch (e) {
          }
        }

        if (data.accents && Array.isArray(data.accents)) {
          svc.wallpaperAccents = data.accents
        }

        svc._startupDone = true

        var wallpaperStr = data.wallpaper || ""
        if (wallpaperStr && wallpaperStr.charAt(0) === "/") {
          var prevSource = svc.sourceWallpaperPath
          var changed = wallpaperStr !== svc.wallpaperPath

          svc.wallpaperPath = wallpaperStr
          svc.wallpaperReady = true

          if (changed) {
          }

          if (prevSource.length === 0) {
            svc.sourceWallpaperPath = wallpaperStr
            if (svc._mono) svc.refresh()
          }
        }
      }
    })
  }

  // ═══════════════════════════════════════════════════════════════
  //  SYSTEM INTEGRATION
  // ═══════════════════════════════════════════════════════════════

  onWallpaperAccentsChanged: {
    if (wallpaperAccents.length > 0 && _userChangedWallpaper && !Store.theme.accentManual) {
      _userChangedWallpaper = false
      Store.theme.accent = _mono ? "#E8E8E8" : wallpaperAccents[0]
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  TIMERS
  // ═══════════════════════════════════════════════════════════════

  Timer {
    id: pollTimer
    interval: svc._pollInterval
    running: false
    repeat: false
    onTriggered: svc._pollWallpaper()
  }

  Timer {
    id: cycleTimer
    interval: Math.max(1, svc.autoCycleMinutes) * 60000
    running: svc.autoCycle
    repeat: true
    onTriggered: svc.cycleWallpaper()
  }

  Timer {
    id: startupTimer
    interval: svc._pollInterval
    running: true
    repeat: false
    onTriggered: {
      if (!svc.wallpaperReady) svc.wallpaperReady = true
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  WALLPAPER SAMPLING (color / luminance / contrast)
  // ═══════════════════════════════════════════════════════════════

  readonly property bool mapReady: _colorMap !== null && _colorMap.length > 0
  readonly property real dynamicRange: _dynamicRange
  readonly property int mapGridSize: _mapGridSize

  function colorAt(absX: real, absY: real, screenW: real, screenH: real): color {
    if (!mapReady || !_colorMap || _colorMap.length === 0)
      return Qt.rgba(0, 0, 0, 1);
    var normX = Math.max(0, Math.min(0.9999, absX / screenW));
    var normY = Math.max(0, Math.min(0.9999, absY / screenH));
    var rows = _colorMap.length;
    var cols = _colorMap[0] ? _colorMap[0].length : 1;
    var fx = normX * (cols - 1);
    var fy = normY * (rows - 1);
    var x0 = Math.floor(fx);
    var y0 = Math.floor(fy);
    var x1 = Math.min(x0 + 1, cols - 1);
    var y1 = Math.min(y0 + 1, rows - 1);
    var wx = fx - x0;
    var wy = fy - y0;
    var c00 = _colorMap[y0] ? _colorMap[y0][x0] : 0;
    var c10 = _colorMap[y0] ? _colorMap[y0][x1] : 0;
    var c01 = _colorMap[y1] ? _colorMap[y1][x0] : 0;
    var c11 = _colorMap[y1] ? _colorMap[y1][x1] : 0;
    var r = _lerp2d((c00 >> 16) & 255, (c10 >> 16) & 255, (c01 >> 16) & 255, (c11 >> 16) & 255, wx, wy);
    var g = _lerp2d((c00 >> 8) & 255, (c10 >> 8) & 255, (c01 >> 8) & 255, (c11 >> 8) & 255, wx, wy);
    var b = _lerp2d(c00 & 255, c10 & 255, c01 & 255, c11 & 255, wx, wy);
    return Qt.rgba(r / 255, g / 255, b / 255, 1);
  }

  function luminanceAt(absX: real, absY: real, screenW: real, screenH: real): real {
    if (!mapReady || !_luminanceMap || _luminanceMap.length === 0)
      return 0.0;
    var normX = Math.max(0, Math.min(0.9999, absX / screenW));
    var normY = Math.max(0, Math.min(0.9999, absY / screenH));
    var rows = _luminanceMap.length;
    var cols = _luminanceMap[0] ? _luminanceMap[0].length : 1;
    var fx = normX * (cols - 1);
    var fy = normY * (rows - 1);
    var x0 = Math.floor(fx);
    var y0 = Math.floor(fy);
    var x1 = Math.min(x0 + 1, cols - 1);
    var y1 = Math.min(y0 + 1, rows - 1);
    var wx = fx - x0;
    var wy = fy - y0;
    var l00 = _luminanceMap[y0] ? _luminanceMap[y0][x0] : 0;
    var l10 = _luminanceMap[y0] ? _luminanceMap[y0][x1] : 0;
    var l01 = _luminanceMap[y1] ? _luminanceMap[y1][x0] : 0;
    var l11 = _luminanceMap[y1] ? _luminanceMap[y1][x1] : 0;
    var top = l00 + (l10 - l00) * wx;
    var bot = l01 + (l11 - l01) * wx;
    return top + (bot - top) * wy;
  }

  function areaLuminanceAt(absX: real, absY: real, w: real, h: real, screenW: real, screenH: real): real {
    if (!mapReady || !_luminanceMap || _luminanceMap.length === 0)
      return 0.0;
    if (w * h < 400)
      return luminanceAt(absX + w / 2, absY + h / 2, screenW, screenH);
    var rows = _luminanceMap.length;
    var cols = _luminanceMap[0] ? _luminanceMap[0].length : 1;
    if (rows === 0 || cols === 0)
      return 0.0;
    var x0 = Math.max(0, absX);
    var y0 = Math.max(0, absY);
    var x1 = Math.min(screenW, absX + w);
    var y1 = Math.min(screenH, absY + h);
    if (x0 >= x1 || y0 >= y1)
      return luminanceAt(absX + w / 2, absY + h / 2, screenW, screenH);
    var stepX = Math.max(1, Math.floor((x1 - x0) / 4));
    var stepY = Math.max(1, Math.floor((y1 - y0) / 4));
    var sum = 0.0;
    var count = 0;
    for (var sy = y0; sy < y1; sy += stepY) {
      for (var sx = x0; sx < x1; sx += stepX) {
        sum += luminanceAt(sx, sy, screenW, screenH);
        count++;
      }
    }
    return count > 0 ? sum / count : luminanceAt(absX + w / 2, absY + h / 2, screenW, screenH);
  }

  function contrastTextColor(c: color): color {
    return relativeLuminance(c) > 0.36 ? Qt.rgba(0, 0, 0, 1) : Qt.rgba(1, 1, 1, 1);
  }

  function contrastAt(absX: real, absY: real, w: real, h: real, screenW: real, screenH: real): var {
    if (!mapReady)
      return {
        textColor: Qt.rgba(0, 0, 0, 1),
        shadowColor: Qt.rgba(0, 0, 0, 0.12),
        bgColor: Qt.rgba(0, 0, 0, 1),
        bgLuminance: 0.0
      };
    var Y = areaLuminanceAt(absX, absY, w, h, screenW, screenH);
    var bg = colorAt(absX + w / 2, absY + h / 2, screenW, screenH);
    var tc = contrastTextColor(bg);
    var so = 0.06 + Math.min(_dynamicRange, 0.8) * 0.15;
    return {
      textColor: tc,
      shadowColor: Qt.rgba(tc.r, tc.g, tc.b, so),
      bgColor: bg,
      bgLuminance: Y
    };
  }

  function regionVariance(gx: real, gy: real, gw: real, gh: real): real {
    return _computeRegionVariance(gx, gy, gw, gh);
  }

  readonly property int _mapGridSize: 512
  property var _colorMap: null
  property var _luminanceMap: null
  property var _integralMap: null
  property real _lumMin: 1.0
  property real _lumMax: 0.0
  property real _dynamicRange: 0.0
  property real _lumMean: 0.0

  function _lerp2d(v00, v10, v01, v11, wx, wy): real {
    var top = v00 + (v10 - v00) * wx;
    var bot = v01 + (v11 - v01) * wx;
    return top + (bot - top) * wy;
  }

  function _linearize(c: real): real {
    return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
  }

  function relativeLuminance(c: color): real {
    return 0.2126 * _linearize(c.r) + 0.7152 * _linearize(c.g) + 0.0722 * _linearize(c.b);
  }

  function _computeRegionVariance(gx, gy, gw, gh): real {
    var integral = _integralMap;
    if (!integral)
      return Infinity;
    var mapRows = _luminanceMap ? _luminanceMap.length : 0;
    var mapCols = mapRows > 0 && _luminanceMap[0] ? _luminanceMap[0].length : 0;
    if (mapRows === 0 || mapCols === 0)
      return Infinity;
    var x0 = Math.max(0, gx);
    var y0 = Math.max(0, gy);
    var x1 = Math.min(gx + gw, mapCols);
    var y1 = Math.min(gy + gh, mapRows);
    if (x0 >= x1 || y0 >= y1)
      return Infinity;
    var count = (x1 - x0) * (y1 - y0);
    var sum = integral[y1][x1] - integral[y0][x1] - integral[y1][x0] + integral[y0][x0];
    var sumSq = 0.0;
    for (var y = y0; y < y1; y++) {
      var row = _luminanceMap[y];
      if (!row)
        continue;
      for (var x = x0; x < x1; x++) {
        var lum = row[x];
        sumSq += lum * lum;
      }
    }
    var mean = sum / count;
    return sumSq / count - mean * mean;
  }

  function _setIlluminanceMap(raw): void {
    if (!raw || !raw.b || raw.w === 0 || raw.h === 0) {
      _colorMap = null;
      _luminanceMap = null;
      _integralMap = null;
      return;
    }
    var rows = raw.h, cols = raw.w;
    var decoded = _base64Decode(raw.b);
    if (!decoded || decoded.length < rows * cols * 3) {
      _colorMap = null;
      _luminanceMap = null;
      _integralMap = null;
      return;
    }
    var colorRows = new Array(rows);
    var luminanceRows = new Array(rows);
    var lumMin = 1.0, lumMax = 0.0, lumSum = 0.0, offset = 0;
    for (var y = 0; y < rows; y++) {
      var colors = new Uint32Array(cols);
      var luminance = new Float32Array(cols);
      for (var x = 0; x < cols; x++) {
        var r = decoded[offset], g = decoded[offset + 1], b = decoded[offset + 2];
        offset += 3;
        colors[x] = (r << 16) | (g << 8) | b;
        var lum = r * 0.2126 + g * 0.7152 + b * 0.0722;
        luminance[x] = lum;
        if (lum < lumMin)
          lumMin = lum;
        if (lum > lumMax)
          lumMax = lum;
        lumSum += lum;
      }
      colorRows[y] = colors;
      luminanceRows[y] = luminance;
    }
    _colorMap = colorRows;
    _luminanceMap = luminanceRows;
    _lumMin = lumMin;
    _lumMax = lumMax;
    _dynamicRange = lumMax - lumMin;
    _lumMean = raw.n > 0 ? lumSum / raw.n : 0.5;
    _buildIntegralMap(luminanceRows, rows, cols);
  }

  function _base64Decode(str: string): var {
    if (!str || str.length === 0)
      return new Uint8Array(0);
    var b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    var lookup = new Uint8Array(128);
    for (var i = 0; i < 64; i++)
      lookup[b64.charCodeAt(i)] = i;
    var len = str.length;
    while (len > 0 && str.charCodeAt(len - 1) === 61)
      len--;
    var outLen = Math.floor(len * 3 / 4);
    var out = new Uint8Array(outLen);
    var j = 0;
    for (var i = 0; i < len; i += 4) {
      var a = lookup[str.charCodeAt(i)] || 0;
      var b = (i + 1 < len) ? (lookup[str.charCodeAt(i + 1)] || 0) : 0;
      var c = (i + 2 < len) ? (lookup[str.charCodeAt(i + 2)] || 0) : 0;
      var d = (i + 3 < len) ? (lookup[str.charCodeAt(i + 3)] || 0) : 0;
      var triple = (a << 18) | (b << 12) | (c << 6) | d;
      if (j < outLen)
        out[j++] = (triple >> 16) & 255;
      if (j < outLen)
        out[j++] = (triple >> 8) & 255;
      if (j < outLen)
        out[j++] = triple & 255;
    }
    return out;
  }

  function _buildIntegralMap(lumRows, rows, cols): void {
    var integral = new Array(rows + 1);
    integral[0] = new Float64Array(cols + 1);
    for (var y = 0; y < rows; y++) {
      var prevRow = integral[y];
      var curRow = new Float64Array(cols + 1);
      var srcRow = lumRows[y];
      if (!srcRow) {
        integral[y + 1] = curRow;
        continue;
      }
      var rowSum = 0.0;
      curRow[0] = 0.0;
      for (var x = 0; x < cols; x++) {
        rowSum += srcRow[x];
        curRow[x + 1] = prevRow[x + 1] + rowSum;
      }
      integral[y + 1] = curRow;
    }
    _integralMap = integral;
  }

  function _clearIlluminanceMap(): void {
    _colorMap = null;
    _luminanceMap = null;
    _integralMap = null;
    _lumMin = 1.0;
    _lumMax = 0.0;
    _dynamicRange = 0.0;
    _lumMean = 0.5;
  }

  function _computeIlluminanceMap(): void {
    if (ProcessPool.isBusy("illuminance-map"))
      return;
    var wp = svc.wallpaperPath;
    if (!wp || wp.length === 0)
      return;
    var script = AppInfo.configHome + "/features/wallpaper/effects/sample-wallpaper-fast.py";
    var cmd = ["python3", script, wp, "full", String(_mapGridSize), String(_mapGridSize)];
    var requestedWallpaper = wp;
    ProcessPool.runTracked("Illuminance map", cmd, {
      id: "illuminance-map",
      callback: function (r) {
        if (svc.wallpaperPath !== requestedWallpaper) {
          _computeIlluminanceMap();
          return;
        }
        if (r.exitCode === 0) {
          try {
            var parsed = JSON.parse(r.stdout.trim());
            _setIlluminanceMap(parsed);
          } catch (e) {}
        }
      }
    });
  }

  onWallpaperPathChanged: {
    svc._clearIlluminanceMap()
    svc._computeIlluminanceMap()
  }

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════

  function _loadCycleSettings(): void {
    svc.autoCycle = Store.wallpaper.autoCycle
    svc.autoCycleMinutes = Store.wallpaper.autoCycleMinutes
  }

  Connections {
    target: Store.theme
    function onMonochromeChanged() {
      svc.setMonochrome(Store.theme.monochrome)
    }
  }

  Component.onCompleted: {
    svc._mono = Store.theme.monochrome
    svc._loadHistory()
    svc._loadCycleSettings()
    svc._pollWallpaper()
    svc._computeIlluminanceMap()
  }
}
