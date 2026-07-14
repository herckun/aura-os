pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"

Singleton {
    id: svc

    // ═══════════════════════════════════════════════════════════════
    //  PUBLIC STATE
    // ═══════════════════════════════════════════════════════════════

    property var monitors: []
    property var configEntries: []
    property bool loaded: false
    property bool detecting: false

    property bool hasPending: false
    property bool pendingApply: false
    property int countdownRemaining: 0
    property var _previousConfig: null
    property var _applyContent: ""

    // ═══════════════════════════════════════════════════════════════
    //  PUBLIC API
    // ═══════════════════════════════════════════════════════════════

    readonly property string primaryOutput: {
        var stored = Store.display.primary;
        for (var i = 0; i < monitors.length; i++) {
            if (stored && monitors[i].name === stored)
                return stored;
        }
        for (var j = 0; j < monitors.length; j++) {
            if (monitors[j].focused)
                return monitors[j].name;
        }
        return monitors.length > 0 ? (monitors[0].name || "") : "";
    }

    function detectMonitors(): void {
        detecting = true;
        HyprlandService.hyprctlJson("monitors all", "monitor-detect", function (data, r) {
            detecting = false;
            if (Array.isArray(data)) {
                monitors = data;
                _syncConfigFromMonitors();
            } else {
                Logger.warn("display", "Failed to parse monitor data");
            }
        });
    }

    function monitorByName(name: string): var {
        for (var i = 0; i < monitors.length; i++) {
            if (monitors[i].name === name)
                return monitors[i];
        }
        return null;
    }

    function updateMonitor(output: string, patch: var): void {
        _snapshotIfNeeded();
        var copy = [];
        var found = false;
        for (var i = 0; i < configEntries.length; i++) {
            var entry = Object.assign({}, configEntries[i]);
            if (entry.output === output) {
                entry = Object.assign(entry, patch);
                found = true;
            }
            copy.push(entry);
        }
        if (!found) {
            copy.push(Object.assign(_entryDefaults(output), patch));
        }
        configEntries = copy;
        hasPending = true;
    }

    function setPrimary(output: string): void {
        Store.display.primary = output;
        var mon = monitorByName(output);
        if (!mon)
            return;
        var dx = -(mon.x || 0);
        var dy = -(mon.y || 0);
        if (dx === 0 && dy === 0)
            return;
        for (var i = 0; i < monitors.length; i++) {
            var m = monitors[i];
            if (m.disabled)
                continue;
            updateMonitor(m.name, {
                position: ((m.x || 0) + dx) + "x" + ((m.y || 0) + dy)
            });
        }
    }

    function removeMonitorConfig(output: string): void {
        _snapshotIfNeeded();
        var copy = [];
        for (var i = 0; i < configEntries.length; i++) {
            if (configEntries[i].output !== output) {
                copy.push(configEntries[i]);
            }
        }
        configEntries = copy;
        hasPending = true;
    }

    function resetToDefaults(): void {
        _snapshotIfNeeded();
        configEntries = [_entryBase()];
        hasPending = true;
    }

    function applyPending(): void {
        if (!_previousConfig)
            return;
        var content = _buildConfigContent(configEntries);
        _applyContent = content;
        pendingApply = true;
        countdownRemaining = 10;
        _writeConfig(content, function () {
            _countdownTimer.restart();
            _redetectTimer.restart();
        });
    }

    function confirmApply(): void {
        _countdownTimer.stop();
        pendingApply = false;
        countdownRemaining = 0;
        _previousConfig = null;
        _applyContent = "";
        hasPending = false;
    }

    function revert(): void {
        _countdownTimer.stop();
        pendingApply = false;
        countdownRemaining = 0;
        if (_previousConfig) {
            configEntries = _previousConfig.map(function (e) {
                return Object.assign({}, e);
            });
            var content = _buildConfigContent(configEntries);
            _writeConfig(content, function () {
                _previousConfig = null;
                _applyContent = "";
                hasPending = false;
                _redetectTimer.restart();
            });
        } else {
            _previousConfig = null;
            _applyContent = "";
            hasPending = false;
        }
    }

    function getConfigForOutput(output: string): var {
        for (var i = 0; i < configEntries.length; i++) {
            if (configEntries[i].output === output)
                return configEntries[i];
        }
        return null;
    }

    function getCurrentMode(monitor: var): string {
        if (!monitor)
            return "";
        var w = monitor.width || 0;
        var h = monitor.height || 0;
        var rr = monitor.refreshRate || 0;
        if (w > 0 && h > 0) {
            return w + "x" + h + "@" + Math.round(rr) + "Hz";
        }
        return "";
    }

    function _findMatchingMode(monitor: var): string {
        if (!monitor || !monitor.availableModes)
            return "";
        var w = monitor.width || 0;
        var h = monitor.height || 0;
        var rr = monitor.refreshRate || 0;
        if (w <= 0 || h <= 0)
            return "";
        for (var i = 0; i < monitor.availableModes.length; i++) {
            var parsed = _parseModeString(monitor.availableModes[i]);
            if (parsed && parsed.width === w && parsed.height === h && (rr === 0 || Math.abs(parsed.refreshRate - rr) < 1)) {
                return monitor.availableModes[i];
            }
        }
        return "";
    }

    function getAvailableModes(monitor: var): var {
        if (!monitor || !monitor.availableModes)
            return [];
        var modes = [];
        var seenValues = ({});
        for (var i = 0; i < monitor.availableModes.length; i++) {
            var modeStr = monitor.availableModes[i];
            if (seenValues[modeStr])
                continue;
            seenValues[modeStr] = true;
            var parsed = _parseModeString(modeStr);
            if (parsed)
                modes.push(parsed);
        }

        var labelCounts = ({});
        for (var j = 0; j < modes.length; j++)
            labelCounts[modes[j].label] = (labelCounts[modes[j].label] || 0) + 1;
        for (var k = 0; k < modes.length; k++) {
            if (labelCounts[modes[k].label] > 1 && modes[k].refreshRate > 0)
                modes[k].label = modes[k].width + "x" + modes[k].height + "@" + modes[k].refreshRate.toFixed(2) + "Hz";
        }

        modes.sort(function (a, b) {
            if (a.width !== b.width)
                return b.width - a.width;
            if (a.height !== b.height)
                return b.height - a.height;
            return b.refreshRate - a.refreshRate;
        });
        return modes;
    }

    function _parseModeString(modeStr: string): var {
        var atIdx = modeStr.indexOf("@");
        if (atIdx < 0)
            return null;

        var resPart = modeStr.substring(0, atIdx);
        var rrPart = modeStr.substring(atIdx + 1);

        var xIdx = resPart.indexOf("x");
        if (xIdx < 0)
            return null;

        var w = parseInt(resPart.substring(0, xIdx));
        var h = parseInt(resPart.substring(xIdx + 1));
        var rr = parseFloat(rrPart);

        if (isNaN(w) || isNaN(h) || w <= 0 || h <= 0)
            return null;

        var label = w + "x" + h;
        if (!isNaN(rr) && rr > 0)
            label += "@" + Math.round(rr) + "Hz";

        return {
            label: label,
            value: modeStr,
            width: w,
            height: h,
            refreshRate: isNaN(rr) ? 0 : rr
        };
    }

    property bool identifyVisible: false

    function identify(): void {
        identifyVisible = true;
        _identifyTimer.restart();
    }

    property Timer _identifyTimer: Timer {
        interval: 2500
        repeat: false
        onTriggered: svc.identifyVisible = false
    }

    function getResolutionOptions(monitor: var): var {
        var out = [
            { label: "PREFERRED", value: "preferred" },
            { label: "HIGHEST RESOLUTION", value: "highres" },
            { label: "HIGHEST REFRESH", value: "highrr" }
        ];
        var modes = getAvailableModes(monitor);
        var seen = ({});
        for (var i = 0; i < modes.length; i++) {
            var key = modes[i].width + "x" + modes[i].height;
            if (seen[key])
                continue;
            seen[key] = true;
            out.push({ label: key, value: key });
        }
        return out;
    }

    function getRefreshOptions(monitor: var, res: string): var {
        var modes = getAvailableModes(monitor);
        var out = [];
        var seen = ({});
        for (var i = 0; i < modes.length; i++) {
            var key = modes[i].width + "x" + modes[i].height;
            if (key !== res)
                continue;
            var lbl = Math.round(modes[i].refreshRate * 100) / 100 + " HZ";
            if (seen[lbl])
                continue;
            seen[lbl] = true;
            out.push({ label: lbl, value: modes[i].value });
        }
        return out;
    }

    function bestModeForResolution(monitor: var, res: string): string {
        var opts = getRefreshOptions(monitor, res);
        return opts.length > 0 ? opts[0].value : "preferred";
    }

    function getTransformOptions(): var {
        return [
            { label: "NORMAL", value: 0 },
            { label: "90°", value: 1 },
            { label: "180°", value: 2 },
            { label: "270°", value: 3 },
            { label: "FLIPPED", value: 4 },
            { label: "FLIPPED 90°", value: 5 },
            { label: "FLIPPED 180°", value: 6 },
            { label: "FLIPPED 270°", value: 7 }
        ];
    }

    function getVrrOptions(): var {
        return [
            { label: "OFF", value: 0 },
            { label: "ON", value: 1 },
            { label: "FULLSCREEN ONLY", value: 2 },
            { label: "FULLSCREEN MEDIA", value: 3 }
        ];
    }

    function getBitdepthOptions(): var {
        return [
            { label: "8-BIT", value: 8 },
            { label: "10-BIT", value: 10 }
        ];
    }

    function getCmOptions(): var {
        return [
            { label: "SRGB (DEFAULT)", value: "" },
            { label: "AUTO", value: "auto" },
            { label: "DCI-P3", value: "dcip3" },
            { label: "APPLE P3", value: "dp3" },
            { label: "ADOBE RGB", value: "adobe" },
            { label: "WIDE GAMUT", value: "wide" },
            { label: "EDID", value: "edid" },
            { label: "HDR", value: "hdr" },
            { label: "HDR EDID", value: "hdredid" }
        ];
    }

    function getMirrorOptions(forOutput: string): var {
        var opts = [{ label: "NONE", value: "" }];
        for (var i = 0; i < monitors.length; i++) {
            var name = monitors[i].name || "";
            if (name && name !== forOutput)
                opts.push({ label: name, value: name });
        }
        return opts;
    }

    function getScaleOptions(): var {
        return [
            {
                label: "1.0",
                value: "1.0"
            },
            {
                label: "1.25",
                value: "1.25"
            },
            {
                label: "1.5",
                value: "1.5"
            },
            {
                label: "1.75",
                value: "1.75"
            },
            {
                label: "2.0",
                value: "2.0"
            },
            {
                label: "2.5",
                value: "2.5"
            },
            {
                label: "3.0",
                value: "3.0"
            }
        ];
    }

    // ═══════════════════════════════════════════════════════════════
    //  PRIVATE HELPERS
    // ═══════════════════════════════════════════════════════════════

    function _entryBase(): var {
        return {
            output: "",
            mode: "preferred",
            position: "auto",
            scale: "1.0",
            transform: 0,
            mirror: "",
            disabled: false,
            vrr: 0,
            bitdepth: 8,
            cm: "",
            sdrbrightness: 1.0,
            sdrsaturation: 1.0
        };
    }

    function _entryDefaults(output: string): var {
        var entry = _entryBase();
        entry.output = output;
        var mon = monitorByName(output);
        if (!mon)
            return entry;
        var rawMode = _findMatchingMode(mon);
        entry.mode = rawMode || "preferred";
        entry.position = (mon.x || 0) + "x" + (mon.y || 0);
        entry.scale = String(mon.scale || 1).replace(/^(\d+)$/, "$1.0");
        entry.transform = mon.transform || 0;
        entry.mirror = mon.mirrorOf && mon.mirrorOf !== "none" ? mon.mirrorOf : "";
        entry.disabled = !!mon.disabled;
        entry.vrr = mon.vrr ? 1 : 0;
        entry.bitdepth = mon.currentFormat && mon.currentFormat.indexOf("2101010") >= 0 ? 10 : 8;
        entry.cm = mon.colorManagementPreset && mon.colorManagementPreset !== "srgb" ? mon.colorManagementPreset : "";
        entry.sdrbrightness = mon.sdrBrightness || 1.0;
        entry.sdrsaturation = mon.sdrSaturation || 1.0;
        return entry;
    }

    function _snapshotIfNeeded(): void {
        if (!_previousConfig && hasPending === false) {
            _previousConfig = configEntries.map(function (e) {
                return Object.assign({}, e);
            });
        }
    }

    function _syncConfigFromMonitors(): void {
        var existing = configEntries.slice();
        var merged = [];

        for (var i = 0; i < monitors.length; i++) {
            var mon = monitors[i];
            var output = mon.name || "";
            var existingConfig = null;

            for (var j = 0; j < existing.length; j++) {
                if (existing[j].output === output) {
                    existingConfig = existing[j];
                    break;
                }
            }

            if (existingConfig) {
                merged.push(Object.assign(_entryBase(), existingConfig));
            } else {
                merged.push(_entryDefaults(output));
            }
        }

        for (var k = 0; k < existing.length; k++) {
            var found = false;
            for (var l = 0; l < merged.length; l++) {
                if (merged[l].output === existing[k].output) {
                    found = true;
                    break;
                }
            }
            if (!found)
                merged.push(existing[k]);
        }

        configEntries = merged;
    }

    function _buildConfigContent(entries: var): string {
        var lines = ["-- @managed: display-settings", ""];
        for (var i = 0; i < entries.length; i++) {
            var e = entries[i];
            lines.push('hl.monitor({');
            lines.push('  output   = "' + (e.output || "") + '",');
            if (e.disabled) {
                lines.push('  disabled = true,');
            } else {
                lines.push('  mode     = "' + (e.mode || "preferred") + '",');
                lines.push('  position = "' + (e.position || "auto") + '",');
                lines.push('  scale    = "' + (e.scale || "1.0") + '",');
                if (e.mirror)
                    lines.push('  mirror   = "' + e.mirror + '",');
                if (e.transform)
                    lines.push('  transform = ' + e.transform + ',');
                if (e.vrr)
                    lines.push('  vrr      = ' + e.vrr + ',');
                if (e.bitdepth === 10)
                    lines.push('  bitdepth = 10,');
                if (e.cm)
                    lines.push('  cm       = "' + e.cm + '",');
                if (e.sdrbrightness !== undefined && Math.abs(e.sdrbrightness - 1.0) > 0.001)
                    lines.push('  sdrbrightness = ' + Number(e.sdrbrightness).toFixed(2) + ',');
                if (e.sdrsaturation !== undefined && Math.abs(e.sdrsaturation - 1.0) > 0.001)
                    lines.push('  sdrsaturation = ' + Number(e.sdrsaturation).toFixed(2) + ',');
            }
            lines.push('})');
            if (i < entries.length - 1)
                lines.push('');
        }

        var hasFallback = false;
        for (var j = 0; j < entries.length; j++) {
            if (entries[j].output === "") {
                hasFallback = true;
                break;
            }
        }
        if (!hasFallback) {
            if (entries.length > 0)
                lines.push('');
            lines.push('-- Fallback for unconfigured monitors');
            lines.push('hl.monitor({');
            lines.push('  output   = "",');
            lines.push('  mode     = "preferred",');
            lines.push('  position = "auto",');
            lines.push('  scale    = "1.0",');
            lines.push('})');
        }
        return lines.join("\n");
    }

    function _writeConfig(content: string, callback: var): void {
        var path = AppInfo.hyprDir + "/monitors.lua";
        HyprlandService.writeAndReload(path, content, function (r) {
            if (r.exitCode !== 0) {
                Logger.warn("display", "Failed to write monitors.lua: " + (r.stderr || ""));
            }

            if (callback)
                callback();
        });
    }

    function _loadCurrentConfig(): void {
        var path = AppInfo.hyprDir + "/monitors.lua";
        ProcessPool.runQueued("Load monitors config", ["cat", path], {
            id: "monitors-load",
            silent: true,
            callback: function (r) {
                if (r.exitCode !== 0) {
                    configEntries = [_entryBase()];
                    loaded = true;
                    return;
                }
                _parseConfig(r.stdout || "");
                loaded = true;
            }
        });
    }

    function _parseConfig(content: string): void {
        var entries = [];
        var blocks = content.split("hl.monitor(");

        for (var i = 1; i < blocks.length; i++) {
            var block = blocks[i];
            var entry = _entryBase();

            var outputMatch = block.match(/output\s*=\s*"([^"]*)"/);
            if (outputMatch)
                entry.output = outputMatch[1];

            var modeMatch = block.match(/mode\s*=\s*"([^"]*)"/);
            if (modeMatch)
                entry.mode = modeMatch[1];

            var posMatch = block.match(/position\s*=\s*"([^"]*)"/);
            if (posMatch)
                entry.position = posMatch[1];

            var scaleMatch = block.match(/scale\s*=\s*"([^"]*)"/);
            if (scaleMatch)
                entry.scale = scaleMatch[1];

            var trMatch = block.match(/transform\s*=\s*(\d+)/);
            if (trMatch)
                entry.transform = parseInt(trMatch[1]);

            var mirMatch = block.match(/mirror\s*=\s*"([^"]*)"/);
            if (mirMatch)
                entry.mirror = mirMatch[1];

            if (block.match(/disabled\s*=\s*true/))
                entry.disabled = true;

            var vrrMatch = block.match(/vrr\s*=\s*(\d+)/);
            if (vrrMatch)
                entry.vrr = parseInt(vrrMatch[1]);

            var bdMatch = block.match(/bitdepth\s*=\s*(\d+)/);
            if (bdMatch)
                entry.bitdepth = parseInt(bdMatch[1]);

            var cmMatch = block.match(/cm\s*=\s*"([^"]*)"/);
            if (cmMatch)
                entry.cm = cmMatch[1];

            var sbMatch = block.match(/sdrbrightness\s*=\s*([\d.]+)/);
            if (sbMatch)
                entry.sdrbrightness = parseFloat(sbMatch[1]);

            var ssMatch = block.match(/sdrsaturation\s*=\s*([\d.]+)/);
            if (ssMatch)
                entry.sdrsaturation = parseFloat(ssMatch[1]);

            entries.push(entry);
        }

        if (entries.length > 0) {
            configEntries = entries;
        } else {
            configEntries = [_entryBase()];
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  COUNTDOWN TIMER
    // ═══════════════════════════════════════════════════════════════

    property Timer _countdownTimer: Timer {
        interval: 1000
        repeat: true
        onTriggered: {
            countdownRemaining--;
            if (countdownRemaining <= 0) {
                revert();
            }
        }
    }

    property Timer _redetectTimer: Timer {
        interval: 700
        repeat: false
        onTriggered: svc.detectMonitors()
    }

    Connections {
        target: HyprlandService
        function onMonitorLayoutChanged() {
            svc._redetectTimer.restart();
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  LIFECYCLE
    // ═══════════════════════════════════════════════════════════════

    Component.onCompleted: {
        _loadCurrentConfig();
        detectMonitors();
    }
}
