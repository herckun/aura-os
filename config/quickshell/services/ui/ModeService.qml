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

  readonly property int mode: Store.shell.mode >= 0 && Store.shell.mode <= 4 ? Store.shell.mode : ModeService.Default

  readonly property string modeKey: ["default", "zen", "focus", "gaming", "theater"][mode]

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

  readonly property var visualDefaults: ({
            "default": {
                animations: true,
                blur: true,
                transparency: true,
                barFloating: false
            },
            "zen": {
                animations: true,
                blur: true,
                transparency: true,
                barFloating: true
            },
            "focus": {
                animations: true,
                blur: false,
                transparency: false,
                barFloating: false
            },
            "gaming": {
                animations: false,
                blur: false,
                transparency: false,
                barFloating: false
            },
            "theater": {
                animations: true,
                blur: true,
                transparency: true,
                barFloating: true
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
        var preset = visualDefaults[["default", "zen", "focus", "gaming", "theater"][m]];
        Store.shell.mode = m;
        Store.appearance.animations = preset.animations;
        Store.appearance.blur = preset.blur;
        Store.appearance.transparency = preset.transparency;
        Store.appearance.barFloating = preset.barFloating;
    }

    function cycleMode(): void {
        setMode((mode + 1) % 5);
    }
}
