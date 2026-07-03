pragma Singleton
import QtQml
import QtQuick
import Quickshell
import "../../core"

Singleton {
    id: svc

    // ═══════════════════════════════════════════════════════════════
    //  SHELL MODE
    // ═══════════════════════════════════════════════════════════════
    enum Mode {
        Default = 0,
        Zen = 1,
        Focus = 2,
        Gaming = 3,
        Theater = 4
    }

  property int mode: ModeService.Default

  readonly property var modeInfo: ({
            0: {
                name: "DEFAULT",
                icon: "device-desktop",
                description: "Full desktop with bar and hot areas"
            },
            1: {
                name: "ZEN",
                icon: "sun",
                description: "Clean canvas — panels appear on demand"
            },
            2: {
                name: "FOCUS",
                icon: "target",
                description: "Productivity — simplified, distraction-free"
            },
            3: {
                name: "GAMING",
                icon: "zap",
                description: "Full-screen — minimal overlays"
            },
            4: {
                name: "THEATER",
                icon: "moon",
                description: "Media-centric — large widgets, dark chrome"
            }
        })

  readonly property bool showBar: mode !== ModeService.Gaming
  readonly property bool showHotAreas: mode === ModeService.Default || mode === ModeService.Zen
  readonly property bool minimalBar: mode === ModeService.Focus
  readonly property bool fullScreenChrome: mode === ModeService.Gaming
  readonly property bool mediaChrome: mode === ModeService.Theater

  readonly property bool barActuallyVisible: showBar

    // ═══════════════════════════════════════════════════════════════
    //  PUBLIC API
    // ═══════════════════════════════════════════════════════════════
    function setMode(m: int): void {
        if (mode === m)
            return;
        mode = m;
        Store.set("shell.mode", m);
        _applyVisualPreset(m);
    }

    function cycleMode(): void {
        var next = (mode + 1) % 5;
        setMode(next);
    }

    // ═══════════════════════════════════════════════════════════════
    //  VISUAL PRESETS
    // ═══════════════════════════════════════════════════════════════

    function _applyVisualPreset(m: int): void {
        var nextAnimations = true;
        var nextBlur = true;
        var nextTransparency = true;
        var nextFloating = false;

        switch (m) {
        case ModeService.Default:
            break;
        case ModeService.Zen:
            nextFloating = true;
            break;
        case ModeService.Focus:
            nextBlur = false;
            nextTransparency = false;
            break;
        case ModeService.Gaming:
            nextAnimations = false;
            nextBlur = false;
            nextTransparency = false;
            break;
        case ModeService.Theater:
            nextFloating = true;
            break;
        }

        Store.setBatch({
            "performance.animations": nextAnimations,
            "appearance.blur": nextBlur,
            "appearance.transparency": nextTransparency,
            "appearance.barFloating": nextFloating
        });
    }

    // ═══════════════════════════════════════════════════════════════
    //  PRIVATE HELPERS
    // ═══════════════════════════════════════════════════════════════
    function _syncFromStore(): void {
        mode = Store.getInt("shell.mode", ModeService.Default);
    }

    // ═══════════════════════════════════════════════════════════════
    //  LIFECYCLE
    // ═══════════════════════════════════════════════════════════════
    Component.onCompleted: {
        Store.loadedLater(10, function () {
            svc._syncFromStore();
        });

        Store.watch("shell.mode", function (_, value) {
            svc.mode = value;
        });
    }
}
