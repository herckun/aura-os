import QtQuick
import QtQuick.Layouts
import "../../styles"
import "../../core"
import "../../services"
import "../../components"

Column {
    id: root
    spacing: Theme.spaceLg
    width: parent.width

    property int selectedMonitor: 0

    readonly property var _mons: DisplayService.monitors || []

    Connections {
        target: DisplayService
        function onMonitorsChanged() {
            if (root.selectedMonitor >= (DisplayService.monitors || []).length)
                root.selectedMonitor = 0;
        }
    }

    readonly property int _enabledCount: {
        var dep = DisplayService.configEntries;
        var n = 0;
        for (var i = 0; i < _mons.length; i++) {
            var cfg = DisplayService.getConfigForOutput(_mons[i].name || "");
            var dis = cfg ? !!cfg.disabled : !!_mons[i].disabled;
            if (!dis)
                n++;
        }
        return n;
    }

    readonly property var _layoutRects: {
        var dep = DisplayService.configEntries;
        var rects = [];
        for (var i = 0; i < _mons.length; i++) {
            var m = _mons[i];
            var cfg = DisplayService.getConfigForOutput(m.name || "");
            var dis = cfg ? !!cfg.disabled : !!m.disabled;
            var mir = cfg ? (cfg.mirror || "") : (m.mirrorOf && m.mirrorOf !== "none" ? m.mirrorOf : "");
            if (dis || mir)
                continue;
            var scale = m.scale || 1;
            if (cfg && parseFloat(cfg.scale) > 0)
                scale = parseFloat(cfg.scale);
            var tr = cfg && cfg.transform !== undefined ? cfg.transform : (m.transform || 0);
            var w = m.width || 1920;
            var h = m.height || 1080;
            if (cfg && cfg.mode) {
                var mm = cfg.mode.match(/^(\d+)x(\d+)/);
                if (mm) {
                    w = parseInt(mm[1]);
                    h = parseInt(mm[2]);
                }
            }
            var lw = Math.max(1, Math.round((tr % 2 ? h : w) / scale));
            var lh = Math.max(1, Math.round((tr % 2 ? w : h) / scale));
            var px = m.x || 0;
            var py = m.y || 0;
            if (cfg && cfg.position) {
                var pm = cfg.position.match(/^(-?\d+)x(-?\d+)$/);
                if (pm) {
                    px = parseInt(pm[1]);
                    py = parseInt(pm[2]);
                }
            }
            rects.push({
                name: m.name || "",
                index: i,
                x: px,
                y: py,
                w: lw,
                h: lh,
                res: w + "x" + h,
                scale: scale
            });
        }
        return rects;
    }

    PageHeader {
        title: "DISPLAY"
        description: "Arrange displays, resolution, mirroring and color"
    }

    // ── Pending banner ──────────────────────────────────────────
    Surface {
        width: parent.width
        height: pendingCol.implicitHeight + Theme.spaceMd * 2
        radius: Theme.radiusMedium
        antialiasing: true
        color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.06)
        border.color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.25)
        visible: DisplayService.pendingApply

        Column {
            id: pendingCol
            anchors.fill: parent
            anchors.margins: Theme.spaceMd
            spacing: Theme.spaceSm

            RowLayout {
                width: parent.width
                spacing: Theme.spaceSm

                Icon {
                    source: Icons.get("alert")
                    size: 14
                    color: Theme.warning
                }

                Text {
                    text: "CONFIRM DISPLAY SETTINGS"
                    color: Theme.warning
                    font.pixelSize: Theme.fontSizeMicro
                    font.family: Theme.fontFamilyMono
                    font.weight: Font.Bold
                    font.letterSpacing: 0.06
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: DisplayService.countdownRemaining + "s"
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontSizeCaption
                    font.family: Theme.fontFamilyMono
                    font.weight: Font.Bold
                }
            }

            ProgressBar {
                width: parent.width
                barHeight: 3
                barColor: Theme.warning
                value: DisplayService.countdownRemaining / 10
            }

            Row {
                spacing: Theme.spaceSm
                anchors.right: parent.right
                Button {
                    text: "REVERT"
                    size: "sm"
                    icon: "arrow-clockwise"
                    onClicked: DisplayService.revert()
                }
                Button {
                    text: "KEEP"
                    size: "sm"
                    icon: "check"
                    variant: "accent"
                    onClicked: DisplayService.confirmApply()
                }
            }
        }
    }

    // ── Empty state ─────────────────────────────────────────────
    Surface {
        width: parent.width
        height: emptyCol.implicitHeight + Theme.spaceXl * 2
        radius: Theme.radiusMedium
        antialiasing: true
        border.color: Theme.border
        visible: !DisplayService.detecting && root._mons.length === 0

        Column {
            id: emptyCol
            anchors.centerIn: parent
            spacing: Theme.spaceMd
            Icon {
                source: Icons.get("monitor")
                size: 36
                color: Theme.textDisabled
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: "NO DISPLAYS FOUND"
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSizeLabel
                font.family: Theme.fontFamilyMono
                font.weight: Font.Bold
                font.letterSpacing: 0.08
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: "Click DETECT to scan"
                color: Theme.textDisabled
                font.pixelSize: Theme.fontSizeCaption
                font.family: Theme.fontFamilyMono
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    // ── Arrangement hero ────────────────────────────────────────
    Card {
        width: parent.width
        visible: root._mons.length > 0

        Column {
            width: parent.width
            spacing: Theme.spaceMd

            RowLayout {
                width: parent.width
                spacing: Theme.spaceMd

                Column {
                    Layout.fillWidth: true
                    spacing: Theme.spaceXxs

                    Row {
                        spacing: Theme.spaceSm

                        Text {
                            text: root._mons.length
                            color: Theme.textDisplay
                            font.pixelSize: Theme.fontSizeDisplay
                            font.family: Theme.fontFamilyDisplay
                            font.weight: Font.Bold
                        }

                        Column {
                            spacing: 0
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: "DISPLAY" + (root._mons.length !== 1 ? "S" : "") + (root._mons.length - root._enabledCount > 0 ? " · " + (root._mons.length - root._enabledCount) + " OFF" : "")
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeLabel
                                font.family: Theme.fontFamilyMono
                                font.weight: Font.Bold
                                font.letterSpacing: 0.08
                            }

                            Text {
                                text: {
                                    if (DisplayService.pendingApply)
                                        return "Confirm in " + DisplayService.countdownRemaining + "s or auto-revert";
                                    if (DisplayService.detecting)
                                        return "Scanning...";
                                    if (DisplayService.hasPending)
                                        return "Unsaved changes — hit APPLY";
                                    return "Drag to arrange · click to select";
                                }
                                color: DisplayService.pendingApply ? Theme.warning : DisplayService.hasPending ? Theme.accent : Theme.textSecondary
                                font.pixelSize: Theme.fontSizeMicro
                                font.family: Theme.fontFamilyMono
                            }
                        }
                    }
                }

                Button {
                    text: "DETECT"
                    size: "sm"
                    shape: "link"
                    icon: "refresh"
                    busy: DisplayService.detecting
                    enabled: !DisplayService.pendingApply
                    onClicked: DisplayService.detectMonitors()
                }

                Button {
                    text: "RESET"
                    size: "sm"
                    shape: "link"
                    icon: "arrow-clockwise"
                    enabled: !DisplayService.pendingApply
                    onClicked: DisplayService.resetToDefaults()
                }

                Button {
                    text: "APPLY"
                    size: "sm"
                    icon: "check"
                    variant: "accent"
                    enabled: DisplayService.hasPending && !DisplayService.pendingApply
                    onClicked: DisplayService.applyPending()
                }
            }

            Surface {
                width: parent.width
                height: 230
                radius: Theme.radiusMedium
                antialiasing: true
                color: Theme.background
                border.color: Theme.border
                visible: root._layoutRects.length > 0

                DotMatrixBackground {
                    anchors.fill: parent
                }

                Button {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: Theme.spaceSm
                    z: 20
                    text: "IDENTIFY"
                    size: "sm"
                    shape: "link"
                    icon: "target"
                    onClicked: DisplayService.identify()
                }

                Text {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.margins: Theme.spaceSm
                    z: 20
                    text: stage.dragLabel
                    visible: stage.dragLabel !== ""
                    color: Theme.accent
                    font.pixelSize: Theme.fontSizeCaption
                    font.family: Theme.fontFamilyMono
                    font.weight: Font.Bold
                }

                Item {
                    id: stage
                    anchors.fill: parent
                    anchors.margins: Theme.spaceSm

                    property string dragLabel: ""

                    readonly property var rects: root._layoutRects
                    readonly property var bbox: {
                        var r = rects;
                        if (!r.length)
                            return { x: 0, y: 0, w: 1, h: 1 };
                        var minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
                        for (var i = 0; i < r.length; i++) {
                            minX = Math.min(minX, r[i].x);
                            minY = Math.min(minY, r[i].y);
                            maxX = Math.max(maxX, r[i].x + r[i].w);
                            maxY = Math.max(maxY, r[i].y + r[i].h);
                        }
                        return { x: minX, y: minY, w: Math.max(1, maxX - minX), h: Math.max(1, maxY - minY) };
                    }
                    readonly property real s: Math.min((width - 48) / bbox.w, (height - 32) / bbox.h)
                    readonly property real ox: (width - bbox.w * s) / 2
                    readonly property real oy: (height - bbox.h * s) / 2

                    function drop(md, sx, sy) {
                        var lx = Math.round((sx - ox) / s + bbox.x);
                        var ly = Math.round((sy - oy) / s + bbox.y);
                        var thr = 20 / s;

                        var bestX = null, bestY = null;
                        for (var i = 0; i < rects.length; i++) {
                            var o = rects[i];
                            if (o.name === md.name)
                                continue;
                            var xc = [o.x + o.w, o.x - md.w, o.x, o.x + o.w - md.w];
                            var yc = [o.y + o.h, o.y - md.h, o.y, o.y + o.h - md.h];
                            for (var j = 0; j < xc.length; j++) {
                                if (Math.abs(lx - xc[j]) <= thr && (bestX === null || Math.abs(lx - xc[j]) < Math.abs(lx - bestX)))
                                    bestX = xc[j];
                            }
                            for (var k = 0; k < yc.length; k++) {
                                if (Math.abs(ly - yc[k]) <= thr && (bestY === null || Math.abs(ly - yc[k]) < Math.abs(ly - bestY)))
                                    bestY = yc[k];
                            }
                        }
                        if (bestX !== null)
                            lx = bestX;
                        if (bestY !== null)
                            ly = bestY;

                        for (var n = 0; n < rects.length; n++) {
                            var ob = rects[n];
                            if (ob.name === md.name)
                                continue;
                            var overlapX = lx < ob.x + ob.w && lx + md.w > ob.x;
                            var overlapY = ly < ob.y + ob.h && ly + md.h > ob.y;
                            if (overlapX && overlapY) {
                                var pushes = [
                                    { ax: "x", v: ob.x + ob.w },
                                    { ax: "x", v: ob.x - md.w },
                                    { ax: "y", v: ob.y + ob.h },
                                    { ax: "y", v: ob.y - md.h }
                                ];
                                var best = null, bestDist = Infinity;
                                for (var p = 0; p < pushes.length; p++) {
                                    var cur = pushes[p].ax === "x" ? lx : ly;
                                    var d = Math.abs(cur - pushes[p].v);
                                    if (d < bestDist) {
                                        bestDist = d;
                                        best = pushes[p];
                                    }
                                }
                                if (best) {
                                    if (best.ax === "x")
                                        lx = best.v;
                                    else
                                        ly = best.v;
                                }
                            }
                        }

                        DisplayService.updateMonitor(md.name, { position: lx + "x" + ly });
                    }

                    Repeater {
                        model: stage.rects

                        delegate: Rectangle {
                            id: monRect
                            required property var modelData
                            readonly property bool isSel: root.selectedMonitor === modelData.index
                            readonly property bool isPrimary: DisplayService.primaryOutput === modelData.name

                            width: Math.max(36, modelData.w * stage.s)
                            height: Math.max(24, modelData.h * stage.s)
                            radius: Theme.radiusSmall
                            antialiasing: true
                            color: isSel ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16) : Theme.backgroundSecondary
                            border.width: isSel ? 2 : Theme.borderWidth
                            border.color: isSel ? Theme.accent : (dragArea.containsMouse ? Theme.borderActive : Theme.borderVisible)
                            z: dragArea.drag.active ? 10 : (isSel ? 2 : 1)

                            Behavior on border.color {
                                enabled: Theme.animationsEnabled
                                ColorAnimation {
                                    duration: Theme.animationFast
                                }
                            }

                            Binding on x {
                                value: stage.ox + (monRect.modelData.x - stage.bbox.x) * stage.s
                                when: !dragArea.drag.active
                                restoreMode: Binding.RestoreBindingOrValue
                            }
                            Binding on y {
                                value: stage.oy + (monRect.modelData.y - stage.bbox.y) * stage.s
                                when: !dragArea.drag.active
                                restoreMode: Binding.RestoreBindingOrValue
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 2
                                width: parent.width - Theme.spaceSm * 2

                                Text {
                                    text: monRect.modelData.name.toUpperCase()
                                    color: monRect.isSel ? Theme.accent : Theme.textPrimary
                                    font.pixelSize: Theme.fontSizeMicro
                                    font.family: Theme.fontFamilyMono
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                Text {
                                    text: monRect.modelData.res + (monRect.modelData.scale !== 1 ? " · " + monRect.modelData.scale + "x" : "")
                                    color: Theme.textDisabled
                                    font.pixelSize: Theme.fontSizeMicro
                                    font.family: Theme.fontFamilyMono
                                    elide: Text.ElideRight
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    visible: monRect.height > 44
                                }
                            }

                            Badge {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: Theme.spaceSm
                                text: "P"
                                size: "xs"
                                visible: monRect.isPrimary
                            }

                            MouseArea {
                                id: dragArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                drag.target: !DisplayService.pendingApply && stage.rects.length > 1 ? monRect : null

                                property bool dragging: false
                                property real lastX: 0
                                property real lastY: 0

                                onPressed: root.selectedMonitor = monRect.modelData.index
                                onPositionChanged: {
                                    if (drag.active) {
                                        dragging = true;
                                        lastX = monRect.x;
                                        lastY = monRect.y;
                                        var lx = Math.round((monRect.x - stage.ox) / stage.s + stage.bbox.x);
                                        var ly = Math.round((monRect.y - stage.oy) / stage.s + stage.bbox.y);
                                        stage.dragLabel = monRect.modelData.name.toUpperCase() + " → " + lx + "x" + ly;
                                    }
                                }
                                onReleased: {
                                    if (dragging)
                                        stage.drop(monRect.modelData, lastX, lastY);
                                    dragging = false;
                                    stage.dragLabel = "";
                                }
                            }
                        }
                    }
                }
            }

            Flow {
                width: parent.width
                spacing: Theme.spaceSm
                visible: root._mons.length > 1

                Repeater {
                    model: root._mons

                    delegate: Chip {
                        required property var modelData
                        required property int index
                        readonly property bool isOff: {
                            var dep = DisplayService.configEntries;
                            var cfg = DisplayService.getConfigForOutput(modelData.name || "");
                            return cfg ? !!cfg.disabled : !!modelData.disabled;
                        }
                        icon: "monitor"
                        label: (modelData.name || "?").toUpperCase() + (isOff ? " · OFF" : "")
                        selected: root.selectedMonitor === index
                        onClicked: root.selectedMonitor = index
                    }
                }
            }
        }
    }

    // ── Selected monitor settings ───────────────────────────────
    Card {
        id: monCard
        width: parent.width
        visible: monitor !== null

        readonly property var monitor: root._mons.length > 0 ? root._mons[Math.min(root.selectedMonitor, root._mons.length - 1)] : null
        readonly property string outputName: monitor ? (monitor.name || "") : ""
        readonly property var config: {
            var dep = DisplayService.configEntries;
            return DisplayService.getConfigForOutput(outputName);
        }
        readonly property bool isPrimary: DisplayService.primaryOutput === outputName
        readonly property bool isDisabled: config ? !!config.disabled : !!(monitor && monitor.disabled)
        readonly property string mirrorOf: config ? (config.mirror || "") : ""

        onConfigChanged: _syncPos()
        onOutputNameChanged: _syncPos()
        Component.onCompleted: _syncPos()

        function _syncPos() {
            if (!posInput)
                return;
            var val = (config && config.position) ? config.position : (monitor ? ((monitor.x || 0) + "x" + (monitor.y || 0)) : "auto");
            if (!posInput.input.activeFocus)
                posInput.input.text = val;
        }

        Column {
            width: parent.width
            spacing: Theme.spaceMd
            enabled: !DisplayService.pendingApply

            RowLayout {
                width: parent.width
                spacing: Theme.spaceSm

                Surface {
                    width: 44
                    height: 44
                    radius: Theme.radiusMedium
                    antialiasing: true
                    bordered: false
                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)

                    Icon {
                        anchors.centerIn: parent
                        source: Icons.get("monitor")
                        size: 20
                        color: Theme.accent
                    }
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: monCard.monitor ? (monCard.monitor.name || "?").toUpperCase() : ""
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontSizeHeading
                        font.family: Theme.fontFamilyMono
                        font.weight: Font.Bold
                        font.letterSpacing: 0.06
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Text {
                        text: monCard.monitor ? (monCard.monitor.description || monCard.monitor.model || "Unknown display") : ""
                        color: Theme.textDisabled
                        font.pixelSize: Theme.fontSizeCaption
                        font.family: Theme.fontFamilyMono
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }

                Column {
                    spacing: 2
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: "ACTIVE MODE"
                        color: Theme.textDisabled
                        font.pixelSize: Theme.fontSizeMicro
                        font.family: Theme.fontFamilyMono
                        font.letterSpacing: 0.1
                        anchors.right: parent.right
                        visible: !monCard.isDisabled
                    }

                    Text {
                        text: monCard.isDisabled ? "OFF" : (DisplayService.getCurrentMode(monCard.monitor) || "---")
                        color: monCard.isDisabled ? Theme.error : Theme.textPrimary
                        font.pixelSize: Theme.fontSizeLabel
                        font.family: Theme.fontFamilyMono
                        font.weight: Font.Bold
                        anchors.right: parent.right
                    }
                }
            }

            RowLayout {
                width: parent.width
                spacing: Theme.spaceSm

                Flow {
                    Layout.fillWidth: true
                    spacing: Theme.spaceXs

                    Badge {
                        text: "PRIMARY"
                        variant: "accent"
                        size: "sm"
                        visible: monCard.isPrimary
                    }

                    Badge {
                        text: "DISABLED"
                        variant: "error"
                        size: "sm"
                        visible: monCard.isDisabled
                    }

                    Badge {
                        text: "MIRRORS " + monCard.mirrorOf.toUpperCase()
                        variant: "warning"
                        size: "sm"
                        visible: monCard.mirrorOf !== ""
                    }

                    Badge {
                        text: (monCard.monitor && monCard.monitor.make) ? monCard.monitor.make.toUpperCase() : ""
                        variant: "default"
                        size: "sm"
                        visible: !!(monCard.monitor && monCard.monitor.make)
                    }

                    Badge {
                        text: monCard.monitor ? ((monCard.monitor.physicalWidth || "?") + "x" + (monCard.monitor.physicalHeight || "?") + "MM") : ""
                        variant: "default"
                        size: "sm"
                        visible: !!(monCard.monitor && monCard.monitor.physicalWidth)
                    }
                }

                Button {
                    text: "SET AS PRIMARY"
                    size: "sm"
                    shape: "link"
                    icon: "monitor"
                    visible: !monCard.isPrimary && !monCard.isDisabled
                    onClicked: DisplayService.setPrimary(monCard.outputName)
                }
            }

            Divider {
                width: parent.width
            }

            Column {
                width: parent.width
                spacing: 0

                SectionLabel {
                    label: "OUTPUT"
                }

                SettingRow {
                    width: parent.width
                    label: "ENABLED"
                    description: "Disabling moves windows to the remaining displays"
                    Toggle {
                        toggleWidth: 38
                        toggleHeight: 20
                        checked: !monCard.isDisabled
                        enabled: monCard.isDisabled || root._enabledCount > 1
                        opacity: enabled ? 1 : 0.4
                        onToggled: (v) => DisplayService.updateMonitor(monCard.outputName, { disabled: !v })
                    }
                }

                Divider {
                    width: parent.width
                }

                SettingRow {
                    width: parent.width
                    label: "MIRROR"
                    description: "Duplicate another display's image"
                    SelectDropdown {
                        width: 180
                        enabled: !monCard.isDisabled
                        opacity: enabled ? 1 : 0.4
                        placeholder: "NONE"
                        items: DisplayService.getMirrorOptions(monCard.outputName)
                        value: monCard.mirrorOf
                        onItemSelected: (item) => DisplayService.updateMonitor(monCard.outputName, { mirror: item.value })
                    }
                }

                Item {
                    width: parent.width
                    height: Theme.spaceMd
                }

                SectionLabel {
                    label: "MODE"
                }

                SettingRow {
                    width: parent.width
                    label: "RESOLUTION"
                    SelectDropdown {
                        width: 220
                        enabled: !monCard.isDisabled
                        opacity: enabled ? 1 : 0.4
                        placeholder: "Select resolution..."
                        items: DisplayService.getResolutionOptions(monCard.monitor)
                        value: {
                            if (!monCard.config)
                                return "";
                            var m = (monCard.config.mode || "").match(/^(\d+x\d+)/);
                            return m ? m[1] : monCard.config.mode;
                        }
                        onItemSelected: (item) => {
                            var mode = item.value.match(/^\d+x\d+$/)
                                ? DisplayService.bestModeForResolution(monCard.monitor, item.value)
                                : item.value;
                            DisplayService.updateMonitor(monCard.outputName, { mode: mode });
                        }
                    }
                }

                Divider {
                    width: parent.width
                    visible: refreshRow.visible
                }

                SettingRow {
                    id: refreshRow
                    width: parent.width
                    label: "REFRESH RATE"
                    visible: !!(monCard.config && /^\d+x\d+@/.test(monCard.config.mode || ""))
                    SelectDropdown {
                        width: 160
                        enabled: !monCard.isDisabled
                        opacity: enabled ? 1 : 0.4
                        placeholder: "Refresh..."
                        items: {
                            if (!monCard.config)
                                return [];
                            var m = (monCard.config.mode || "").match(/^(\d+x\d+)/);
                            return m ? DisplayService.getRefreshOptions(monCard.monitor, m[1]) : [];
                        }
                        value: monCard.config ? monCard.config.mode : ""
                        onItemSelected: (item) => DisplayService.updateMonitor(monCard.outputName, { mode: item.value })
                    }
                }

                Divider {
                    width: parent.width
                }

                SettingRow {
                    width: parent.width
                    label: "SCALE"
                    SelectDropdown {
                        width: 140
                        enabled: !monCard.isDisabled
                        opacity: enabled ? 1 : 0.4
                        placeholder: "Scale..."
                        items: DisplayService.getScaleOptions()
                        value: monCard.config ? monCard.config.scale : "1.0"
                        onItemSelected: (item) => DisplayService.updateMonitor(monCard.outputName, { scale: item.value })
                    }
                }

                Divider {
                    width: parent.width
                }

                SettingRow {
                    width: parent.width
                    label: "ROTATION"
                    SelectDropdown {
                        width: 180
                        enabled: !monCard.isDisabled
                        opacity: enabled ? 1 : 0.4
                        placeholder: "NORMAL"
                        items: DisplayService.getTransformOptions()
                        value: monCard.config ? (monCard.config.transform || 0) : 0
                        onItemSelected: (item) => DisplayService.updateMonitor(monCard.outputName, { transform: item.value })
                    }
                }

                Item {
                    width: parent.width
                    height: Theme.spaceMd
                }

                SectionLabel {
                    label: "LAYOUT"
                }

                SettingRow {
                    width: parent.width
                    label: "POSITION"
                    description: monCard.mirrorOf !== "" ? "Not used while mirroring" : "Drag in the arrangement above, or set manually"
                    Input {
                        id: posInput
                        width: 180
                        enabled: !monCard.isDisabled && monCard.mirrorOf === ""
                        opacity: enabled ? 1 : 0.4
                        placeholder: "auto"
                        iconName: "map-pin"
                        onAccepted: DisplayService.updateMonitor(monCard.outputName, { position: input.text || "auto" })
                    }
                }
            }

            CollapsibleHeader {
                id: advHeader
                width: parent.width
                expanded: false
                onToggled: expanded = !expanded

                Text {
                    text: "ADVANCED"
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontSizeCaption
                    font.family: Theme.fontFamilyMono
                    font.weight: Font.Bold
                    font.letterSpacing: 0.08
                }
            }

            Collapsible {
                width: parent.width
                expanded: advHeader.expanded
                animated: false

                Column {
                    width: parent.width
                    spacing: 0

                    SettingRow {
                        width: parent.width
                        label: "VARIABLE REFRESH"
                        description: "Adaptive sync / FreeSync / G-Sync"
                        SelectDropdown {
                            width: 180
                            enabled: !monCard.isDisabled
                            opacity: enabled ? 1 : 0.4
                            placeholder: "OFF"
                            items: DisplayService.getVrrOptions()
                            value: monCard.config ? (monCard.config.vrr || 0) : 0
                            onItemSelected: (item) => DisplayService.updateMonitor(monCard.outputName, { vrr: item.value })
                        }
                    }

                    Divider {
                        width: parent.width
                    }

                    SettingRow {
                        width: parent.width
                        label: "BIT DEPTH"
                        description: "10-bit may break some screen capture"
                        SelectDropdown {
                            width: 140
                            enabled: !monCard.isDisabled
                            opacity: enabled ? 1 : 0.4
                            placeholder: "8-BIT"
                            items: DisplayService.getBitdepthOptions()
                            value: monCard.config ? (monCard.config.bitdepth || 8) : 8
                            onItemSelected: (item) => DisplayService.updateMonitor(monCard.outputName, { bitdepth: item.value })
                        }
                    }

                    Divider {
                        width: parent.width
                    }

                    SettingRow {
                        width: parent.width
                        label: "COLOR PROFILE"
                        description: "Color management preset"
                        SelectDropdown {
                            width: 180
                            enabled: !monCard.isDisabled
                            opacity: enabled ? 1 : 0.4
                            placeholder: "SRGB (DEFAULT)"
                            items: DisplayService.getCmOptions()
                            value: monCard.config ? (monCard.config.cm || "") : ""
                            onItemSelected: (item) => DisplayService.updateMonitor(monCard.outputName, { cm: item.value })
                        }
                    }

                    Item {
                        width: parent.width
                        height: Theme.spaceMd
                    }

                    SliderControl {
                        width: parent.width
                        enabled: !monCard.isDisabled
                        opacity: enabled ? 1 : 0.4
                        label: "SDR BRIGHTNESS"
                        from: 0.5
                        to: 2.0
                        stepSize: 0.05
                        displayMin: 50
                        displayMax: 200
                        unit: "%"
                        value: monCard.config ? (monCard.config.sdrbrightness || 1.0) : 1.0
                        onMoved: (v) => DisplayService.updateMonitor(monCard.outputName, { sdrbrightness: Math.round(v * 100) / 100 })
                    }

                    Item {
                        width: parent.width
                        height: Theme.spaceMd
                    }

                    SliderControl {
                        width: parent.width
                        enabled: !monCard.isDisabled
                        opacity: enabled ? 1 : 0.4
                        label: "SDR SATURATION"
                        from: 0.5
                        to: 2.0
                        stepSize: 0.05
                        displayMin: 50
                        displayMax: 200
                        unit: "%"
                        value: monCard.config ? (monCard.config.sdrsaturation || 1.0) : 1.0
                        onMoved: (v) => DisplayService.updateMonitor(monCard.outputName, { sdrsaturation: Math.round(v * 100) / 100 })
                    }
                }
            }
        }
    }

    // ── Fallback ────────────────────────────────────────────────
    Card {
        id: fallbackCard
        width: parent.width
        title: "FALLBACK"
        description: "Default for unconfigured displays"

        readonly property var fallbackConfig: {
            var dep = DisplayService.configEntries;
            return DisplayService.getConfigForOutput("");
        }

        Column {
            width: parent.width
            spacing: 0
            enabled: !DisplayService.pendingApply

            SettingRow {
                width: parent.width
                label: "DEFAULT SCALE"
                SelectDropdown {
                    width: 140
                    placeholder: "Scale..."
                    items: DisplayService.getScaleOptions()
                    value: fallbackCard.fallbackConfig ? fallbackCard.fallbackConfig.scale : "1.0"
                    onItemSelected: (item) => DisplayService.updateMonitor("", { scale: item.value })
                }
            }
        }
    }
}
