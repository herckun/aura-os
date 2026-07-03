pragma Singleton
import QtQuick
import Quickshell
import "../../core"
import "../../styles"
import ".."

Singleton {
    id: svc

    // ═══════════════════════════════════════════════════════════════
    //  AUTO-POSITIONING
    // ═══════════════════════════════════════════════════════════════

    signal layoutComplete()

    property var autoPositions: ({})
    property var _regions: []
    property real _layoutScreenW: 0
    property real _layoutScreenH: 0

    Timer {
        id: _layoutTimer
        interval: 50
        repeat: false
        onTriggered: svc._doLayout()
    }

    function requestLayout(screenW: real, screenH: real): void {
        if (screenW > 0) _layoutScreenW = screenW;
        if (screenH > 0) _layoutScreenH = screenH;
        _layoutTimer.restart();
    }

    function _doLayout(): void {
        var screenW = _layoutScreenW;
        var screenH = _layoutScreenH;
        if (screenW <= 0 || screenH <= 0) return;

        autoPositions = {};

        var plugins = PluginService.getPluginsForLocation("desktop");
        var autoIds = [];
        for (var i = 0; i < plugins.length; i++) {
            var p = plugins[i];
            if (!PluginService.isPluginEnabledForLocation(p.id, "desktop"))
                continue;
            if (PluginService.getPluginSetting(p.id, "autoPosition", "desktop") ?? false)
                autoIds.push(p.id);
        }

        for (var j = 0; j < autoIds.length; j++) {
            var id = autoIds[j];
            var w = 0, h = 0;
            var reg = _findRegion(id);
            if (reg) {
                w = reg.w;
                h = reg.h;
            } else {
                w = Store.get("desktop." + id + ".w", 200);
                h = Store.get("desktop." + id + ".h", 120);
            }
            if (w <= 0 || h <= 0) continue;

            var pos = getAutoPosition(w, h, screenW, screenH, id);
            if (pos.x < 0 || pos.y < 0) continue;

            registerRegion(id, pos.x, pos.y, w, h);
            autoPositions[id] = pos;
            Store.set("desktop." + id + ".x", pos.x / screenW);
            Store.set("desktop." + id + ".y", pos.y / screenH);
            Store.set("desktop." + id + ".w", w);
            Store.set("desktop." + id + ".h", h);
        }

        layoutComplete();
    }

    // ── Region management ──────────────────────────────────────

    function _findRegion(id: string): var {
        for (var i = 0; i < _regions.length; i++) {
            if (_regions[i].id === id) return _regions[i];
        }
        return null;
    }

    function registerRegion(id: string, x: real, y: real, w: real, h: real): void {
        var filtered = _regions.filter(function(r) { return r.id !== id; });
        filtered.push({ id: id, x: x, y: y, w: w, h: h });
        _regions = filtered;
    }

    function unregisterRegion(id: string): void {
        _regions = _regions.filter(function(r) { return r.id !== id; });
        requestLayout(_layoutScreenW, _layoutScreenH);
    }

    function isRegionOccupied(sx: real, sy: real, sw: real, sh: real, excludeId: string): bool {
        return _isRegionOccupied(sx, sy, sw, sh, excludeId);
    }

    function _isRegionOccupied(sx, sy, sw, sh, excludeId): bool {
        for (var i = 0; i < _regions.length; i++) {
            var r = _regions[i];
            if (r.id === excludeId)
                continue;
            if (sx < r.x + r.w && sx + sw > r.x && sy < r.y + r.h && sy + sh > r.y)
                return true;
        }
        return false;
    }

    // ═══════════════════════════════════════════════════════════════
    //  POSITION-FINDING ALGORITHM
    // ═══════════════════════════════════════════════════════════════

    function getAutoPosition(widgetW: real, widgetH: real, screenW: real, screenH: real, excludeId: string): var {
        if (widgetW <= 0 || widgetH <= 0)
            return { x: -1, y: -1 };

        var barBottom = BarService.barBottom || (BarService.barHeight || Theme.barHeight);
        var margin = Theme.spaceLg;
        var spacing = Theme.spaceLg;

        if (widgetW + margin * 2 > screenW || widgetH + barBottom + margin * 2 > screenH)
            return { x: -1, y: -1 };

        var grid = WallpaperService.mapGridSize;
        var gw = Math.ceil(widgetW / screenW * grid);
        var gh = Math.ceil(widgetH / screenH * grid);

        function isValid(x, y) {
            if (x < margin || y < barBottom + margin) return false;
            if (x + widgetW > screenW - margin || y + widgetH > screenH - margin) return false;
            for (var i = 0; i < _regions.length; i++) {
                var r = _regions[i];
                if (r.id === excludeId) continue;
                var rx = r.x - spacing, ry = r.y - spacing;
                var rw = r.w + spacing * 2, rh = r.h + spacing * 2;
                if (x < rx + rw && x + widgetW > rx && y < ry + rh && y + widgetH > ry)
                    return false;
            }
            return true;
        }

        function score(x, y) {
            var gx = Math.round(x / screenW * grid);
            var gy = Math.round(y / screenH * grid);
            return WallpaperService.regionVariance(gx, gy, gw, gh);
        }

        var right = screenW - widgetW - margin;
        var bottom = screenH - widgetH - margin;
        var midY = (barBottom + margin + bottom) / 2;
        var midX = (margin + right) / 2;
        var candidates = [
            { x: margin,  y: barBottom + margin },
            { x: right,   y: barBottom + margin },
            { x: margin,  y: bottom },
            { x: right,   y: bottom },
            { x: margin,  y: midY },
            { x: right,   y: midY },
            { x: midX,    y: barBottom + margin },
            { x: midX,    y: bottom }
        ];

        var bestPos = null, bestScore = Infinity;

        for (var i = 0; i < candidates.length; i++) {
            var c = candidates[i];
            if (!isValid(c.x, c.y)) continue;
            var s = score(c.x, c.y);
            if (s < bestScore) {
                bestScore = s;
                bestPos = c;
            }
        }

        if (!bestPos) {
            var stride = 8;
            var mgx = Math.ceil(margin / screenW * grid);
            var mgy = Math.ceil((barBottom + margin) / screenH * grid);
            var mgb = Math.ceil(margin / screenH * grid);
            var maxGX = grid - gw - mgx;
            var maxGY = grid - gh - mgb;

            for (var gy2 = mgy; gy2 <= maxGY; gy2 += stride) {
                for (var gx2 = mgx; gx2 <= maxGX; gx2 += stride) {
                    var sx = gx2 / grid * screenW;
                    var sy = gy2 / grid * screenH;
                    if (!isValid(sx, sy)) continue;
                    var s2 = WallpaperService.regionVariance(gx2, gy2, gw, gh);
                    if (s2 < bestScore) {
                        bestScore = s2;
                        bestPos = { x: sx, y: sy };
                    }
                }
            }
        }

        if (!bestPos) return { x: -1, y: -1 };

        return {
            x: Math.max(margin, Math.min(bestPos.x, screenW - widgetW - margin)),
            y: Math.max(barBottom + margin, Math.min(bestPos.y, screenH - widgetH - margin))
        };
    }
}
