
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire

import "styles"
import "core"
import "services"

import "panels/bar"
import "panels/sidebars"
import "panels/overview"
import "overlays/calendar"
import "overlays/cheatsheet"
import "overlays/dev"
import "overlays/desktop"
import "overlays/appswitch"
import "settings"

ShellRoot {
    id: root
    settings.watchFiles: true

    // ── Global Shortcuts ─────────────────────────────────────────
    GlobalShortcut {
        name: "appswitch"
        description: "Alt+Tab window switcher"
        onPressed: {
            if (!appSwitchLoader.active) {
                appSwitchLoader.active = true;
                Qt.callLater(function () {
                    if (appSwitchLoader.item)
                        appSwitchLoader.item.press();
                });
                return;
            }
            if (appSwitchLoader.item)
                appSwitchLoader.item.press();
        }
        onReleased: {
            if (appSwitchLoader.item)
                appSwitchLoader.item.release();
        }
    }

    // ── Helpers ──────────────────────────────────────────────────
    function toggleLoaded(loader: var): void {
        if (!loader.active) {
            loader.active = true;
            Qt.callLater(function () {
                if (loader.item && loader.item.toggle)
                    loader.item.toggle();
                else if (loader.item)
                    loader.item.visible = true;
            });
            return;
        }
        if (!loader.item)
            return;
        if (loader.item.toggle)
            loader.item.toggle();
        else
            loader.item.visible = !loader.item.visible;
    }

    // ── Plugin Discovery ───────────────────────────────────────
    Item {
        id: pluginDiscovery
        visible: false

        Component.onCompleted: {
            ProcessPool.runTracked("Plugin scan", "find \"${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/services/plugins\" -name '*Plugin.qml' -not -name 'ExamplePlugin.qml' -not -name '_*' | sort", {
                id: "plugin-scan",
                shell: true,
                callback: function (r2) {
                    var lines = r2.stdout.trim().split("\n").filter(function (l) {
                        return l.length > 0;
                    });
                    var prefix = AppInfo.configHome + "/quickshell/services/plugins/";

                    PluginService.beginBatch();

                    for (var i = 0; i < lines.length; i++) {
                        var fullPath = lines[i].trim();
                        var relPath = fullPath.substring(prefix.length);
                        var comp = Qt.createComponent("services/plugins/" + relPath);

                        if (comp.status !== Component.Ready) {
                            if (PluginService.debug)
                                Logger.warn("plugins", "Failed to load " + relPath + ": " + comp.errorString().trim());
                            continue;
                        }
                        var inst = null;
                        try {
                            inst = comp.createObject(pluginDiscovery);
                        } catch (e) {
                            if (PluginService.debug)
                                Logger.warn("plugins", "Threw while instantiating " + relPath + ": " + e);
                            continue;
                        }
                        if (!inst || !inst.id || !inst.manifest) {
                            if (PluginService.debug)
                                Logger.warn("plugins", relPath + " loaded but is missing id/manifest — not a plugin?");
                            if (inst)
                                inst.destroy();
                            continue;
                        }

                        try {
                            PluginService.registerPlugin(inst);
                        } catch (e) {
                            if (PluginService.debug)
                                Logger.warn("plugins", "registerPlugin failed for " + relPath + ": " + e);
                        }
                    }
                    PluginService.endBatch();
                    if (PluginService.debug)
                        Logger.info("plugins", "Scan complete: " + PluginService.plugins.length + " plugin(s) registered");
                }
            });
        }
    }

    // ── Desktop Layer ────────────────────────────────────────────
    Variants {
        model: Quickshell.screens

        DesktopLayer {}
    }

    // ── Bar ──────────────────────────────────────────────────────
    Variants {
        model: Quickshell.screens

        Bar {
            visible: ModeService.barActuallyVisible
        }
    }

    // ── Panel Loaders ────────────────────────────────────────────

    LazyLoader {
        id: ccLoader
        active: false

        ControlCenter {
            visible: false
            onVisibleChanged: {
                ControlCenterService.visible = visible;
                if (!visible)
                    ccLoader.active = false;
            }
        }
    }

    LazyLoader {
        id: settingsLoader
        active: false

        SettingsWindow {
            visible: false
            onVisibleChanged: {
                SettingsService.visible = visible;
                if (!visible)
                    settingsLoader.active = false;
            }
        }
    }

    LazyLoader {
        id: overviewLoader
        active: false

        Overview {
            onVisibleChanged: {
                OverviewService.visible = visible;
                if (!visible)
                    overviewLoader.active = false;
            }
        }
    }

    LazyLoader {
        id: cheatsheetLoader
        active: false

        KeybindCheatsheet {
            visible: false
            onVisibleChanged: {
                CheatsheetService.visible = visible;
                if (!visible)
                    cheatsheetLoader.active = false;
            }
        }
    }

    LazyLoader {
        id: devOverlayLoader
        active: false

        DevOverlay {
            visible: false
            onVisibleChanged: {
                DevOverlayService.visible = visible;
                if (!visible)
                    devOverlayLoader.active = false;
            }
        }
    }

    LazyLoader {
        id: appSwitchLoader
        active: false

        AppSwitch {
            visible: true
            onVisibleChanged: AppSwitchService.visible = visible
        }
    }

    HotAreas {}

    // ── Init & Panel Registration ────────────────────────────────
    Component.onCompleted: {
        var _kb = KeybindingService;
        var _ms = ModeService;

        IpcService.registerPanel("controlcenter", function () {
            if (!ccLoader.active) {
                ccLoader.active = true;
                Qt.callLater(function () {
                    if (ccLoader.item) {
                        ccLoader.item.visible = true;
                        ControlCenterService.visible = true;
                    }
                });
                return;
            }
            if (ccLoader.item) {
                ccLoader.item.toggle();
                ControlCenterService.visible = ccLoader.item.visible;
            }
        });

        IpcService.registerPanel("settings", function () {
            root.toggleLoaded(settingsLoader);
        });
        IpcService.registerNav("settings", function (pane) {
            if (!settingsLoader.active) {
                settingsLoader.active = true;
                Qt.callLater(function () {
                    if (settingsLoader.item)
                        settingsLoader.item.navigate(pane);
                });
            } else if (settingsLoader.item) {
                settingsLoader.item.navigate(pane);
            }
        });
        IpcService.registerPanel("overview", function () {
            root.toggleLoaded(overviewLoader);
        });
        IpcService.registerPanel("cheatsheet", function () {
            root.toggleLoaded(cheatsheetLoader);
        });
        IpcService.registerPanel("devoverlay", function () {
            root.toggleLoaded(devOverlayLoader);
        });
        IpcService.registerPanel("appswitch", function () {
            if (!appSwitchLoader.active) {
                appSwitchLoader.active = true;
                return;
            }
            if (appSwitchLoader.item)
                appSwitchLoader.item.press();
        });
        DefaultLayoutService.init();
        AppearanceService.init();
        WallpaperService.init();
        MediaService.init();
        TimerService.init();
        AudioService.init();
        SfxService.init();
        DefaultAppsService.init();

        Logger.info("shell", AppInfo.displayName + " Shell v" + AppInfo.version);
        Logger.info("shell", "Monitors: " + Quickshell.screens.length);
    }

}
