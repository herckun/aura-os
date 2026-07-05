pragma Singleton
import QtQml
import QtQuick
import Quickshell
import "../../core"
import "../"

// ═══════════════════════════════════════════════════════════════════
//  SearchService — unified, provider-driven search results.
//  SearchService.submit(queryId, providerId, rows) for async results.
// ═══════════════════════════════════════════════════════════════════

Singleton {
    id: svc

    // ═══════════════════════════════════════════════════════════════
    //  PUBLIC STATE
    // ═══════════════════════════════════════════════════════════════
    property var results: ([])
    property string query: ""

    // Emitted when a result wants to rewrite the search box (e.g. a /command hint
    // completing to "/find "). The launcher input binds this to prefill itself.
    signal fillRequested(string text)

    // ═══════════════════════════════════════════════════════════════
    //  PUBLIC API
    // ═══════════════════════════════════════════════════════════════
    function registerProvider(provider): void {
        if (!provider || !provider.id)
            return;
        var next = svc._providers.slice();
        var replaced = false;
        for (var i = 0; i < next.length; i++) {
            if (next[i].id === provider.id) {
                next[i] = provider;
                replaced = true;
                break;
            }
        }
        if (!replaced)
            next.push(provider);
        svc._providers = next;
        svc._sortProviders();
    }

    function isProviderEnabled(providerId: string): bool {
        return Store.search.disabled.indexOf(providerId) < 0;
    }

    function setProviderEnabled(providerId: string, on: bool): void {
        var list = Store.search.disabled.filter(function (id) {
            return id !== providerId;
        });
        if (!on)
            list.push(providerId);
        Store.search.disabled = list;
    }

    readonly property var _builtinMeta: ({
            apps: {
                label: "Applications",
                description: "Installed application launcher",
                icon: "squares-four"
            },
            calc: {
                label: "Calculator",
                description: "Inline math with = prefix",
                icon: "calculator"
            },
            commands: {
                label: "Command hints",
                description: "Suggests /commands as you type",
                icon: "terminal"
            }
        })

    readonly property var catalog: {
        var disabled = Store.search.disabled;
        var plugins = PluginService.plugins || [];
        var out = [];
        for (var i = 0; i < svc._providers.length; i++) {
            var p = svc._providers[i];
            var meta = svc._builtinMeta[p.id];
            var entry = {
                id: p.id,
                label: meta ? meta.label : p.id,
                description: meta ? meta.description : "",
                icon: meta ? meta.icon : "magnifying-glass",
                builtin: !!meta,
                prefixes: [],
                enabled: disabled.indexOf(p.id) < 0
            };
            if (!meta) {
                for (var j = 0; j < plugins.length; j++) {
                    var pl = plugins[j];
                    if (pl && pl.searchProvider && pl.searchProvider.id === p.id) {
                        entry.label = pl.manifest.name || p.id;
                        entry.description = pl.manifest.description || "";
                        entry.icon = pl.manifest.icon || "magnifying-glass";
                        break;
                    }
                }
            }
            var c = p.command;
            if (c) {
                var cmds = Array.isArray(c) ? c : [c];
                for (var k = 0; k < cmds.length; k++)
                    if (cmds[k] && cmds[k].prefix)
                        entry.prefixes.push("/" + cmds[k].prefix);
            }
            out.push(entry);
        }
        out.sort(function (a, b) {
            if (a.builtin !== b.builtin)
                return a.builtin ? -1 : 1;
            return a.label.localeCompare(b.label);
        });
        return out;
    }

    function unregisterProvider(providerId: string): void {
        svc._providers = svc._providers.filter(function (p) {
            return p.id !== providerId;
        });
    }

    function search(text: string): void {
        svc.query = text;
        if (!text || text.length === 0) {
            svc._debounce.stop();
            svc._queryId++;          // invalidate any in-flight async responses
            svc._buffer = ({});
            svc._rebuild();
            return;
        }
        // Debounce provider execution: old results stay visible until the new run
        // produces them, so fast typing neither flickers nor spams HTTP providers.
        svc._debounce.restart();
    }

    function _runProviders(): void {
        svc._queryId++;
        var qid = svc._queryId;
        var text = svc.query;
        svc._buffer = ({});
        // A leading "/" is command mode: only command providers (and the command
        // hint list) run, so ambient providers don't pollute "/find wallpaper".
        var commandMode = text.charAt(0) === "/";
        for (var i = 0; i < svc._providers.length; i++) {
            var p = svc._providers[i];
            if (!svc.isProviderEnabled(p.id))
                continue;
            if (commandMode && !p.command && p.id !== "commands")
                continue;
            var out = null;
            try {
                out = p.query ? p.query(text, qid) : null;
            } catch (e) {
                out = null;
            }
            if (out && out.length !== undefined)
                svc._buffer[p.id] = out;
        }
        svc._rebuild();
    }

    function submit(queryId: int, providerId: string, rows: var): void {
        if (queryId !== svc._queryId)
            return;
        svc._buffer[providerId] = rows || [];
        svc._rebuild();
    }

    function activate(index: int): bool {
        if (index < 0 || index >= svc.results.length)
            return false;
        var r = svc.results[index];
        // An action returning true keeps the launcher open (e.g. a command hint
        // that only prefilled the search box); anything else dismisses it.
        if (r && typeof r.action === "function")
            return r.action() === true;
        return false;
    }

    function requestFill(text: string): void {
        svc.fillRequested(text);
    }

    function _commands(): var {
        var out = [];
        for (var i = 0; i < svc._providers.length; i++) {
            var c = svc._providers[i].command;
            if (!c || !svc.isProviderEnabled(svc._providers[i].id))
                continue;
            if (Array.isArray(c))
                out = out.concat(c);
            else
                out.push(c);
        }
        out.sort(function (a, b) {
            return (a.prefix || "").localeCompare(b.prefix || "");
        });
        return out;
    }

    // ═══════════════════════════════════════════════════════════════
    //  INTERNAL STATE
    // ═══════════════════════════════════════════════════════════════
    property var _providers: ([])
    property int _queryId: 0
    property var _buffer: ({})

    property Timer _debounce: Timer {
        interval: 150
        repeat: false
        onTriggered: svc._runProviders()
    }

    // ═══════════════════════════════════════════════════════════════
    //  PRIVATE HELPERS
    // ═══════════════════════════════════════════════════════════════
    function _sortProviders(): void {
        svc._providers.sort(function (a, b) {
            return (b.priority || 0) - (a.priority || 0);
        });
    }

    function _rebuild(): void {
        var merged = [];
        for (var i = 0; i < svc._providers.length; i++) {
            var rows = svc._buffer[svc._providers[i].id];
            if (rows && rows.length)
                merged = merged.concat(rows);
        }
        svc.results = merged.slice(0, 40);
    }

    function _mapApps(entries: var): var {
        var out = [];
        for (var i = 0; i < entries.length; i++) {
            (function (e) {
                    out.push({
                        id: "app:" + (e.exec || e.name),
                        label: e.name || "",
                        sublabel: "",
                        icon: e.icon || "",
                        iconKind: "app",
                        priority: 100,
                        source: "apps",
                        groupLabel: "Applications",
                        action: function () {
                            LauncherService.launch(e);
                        }
                    });
                })(entries[i]);
        }

        return out;
    }

    // ═══════════════════════════════════════════════════════════════
    //  BUILT-IN PROVIDERS
    // ═══════════════════════════════════════════════════════════════
    readonly property var _appsProvider: ({
            id: "apps",
            priority: 100,
            query: function (text, qid) {
                LauncherService.search(text);
                return svc._mapApps(LauncherService.filteredEntries);
            }
        })

    // Type "/" (or a partial like "/fi") to list every provider command — the
    // general counterpart to DuckDuckGo's "!" bang suggestions. Selecting one
    // prefills the search box with "/prefix ".
    readonly property var _commandsProvider: ({
            id: "commands",
            priority: 1000,
            query: function (text, qid) {
                if (text.charAt(0) !== "/" || text.indexOf(" ") >= 0)
                    return [];
                var partial = text.slice(1).toLowerCase();
                var cmds = svc._commands();
                var rows = [];
                for (var i = 0; i < cmds.length; i++) {
                    if (partial.length && cmds[i].prefix.toLowerCase().indexOf(partial) !== 0)
                        continue;
                    rows.push((function (c) {
                            return {
                                id: "cmd:" + c.prefix,
                                label: "/" + c.prefix + (c.args ? " " + c.args : ""),
                                sublabel: c.description || "",
                                icon: c.icon || "chevron-right",
                                iconKind: "symbolic",
                                priority: 1000,
                                source: "commands",
                                groupLabel: "Commands",
                                action: function () {
                                    svc.requestFill("/" + c.prefix + " ");
                                    return true;
                                }
                            };
                        })(cmds[i]));
                }
                return rows;
            }
        })

    readonly property var _calcProvider: ({
            id: "calc",
            priority: 300,
            query: function (text, qid) {
                if (text.indexOf("=") !== 0 || text.length < 2)
                    return [];
                var expr = text.substring(1);
                ProcessPool.runTracked("Search calc", ["qalc", "-t", expr], {
                    id: "search-calc",
                    callback: function (r) {
                        var out = r.stdout.trim();
                        if (!out || out.indexOf("error") >= 0 || out.length > 40) {
                            svc.submit(qid, "calc", []);
                            return;
                        }
                        svc.submit(qid, "calc", [
                            {
                                id: "calc:result",
                                label: out,
                                sublabel: expr + " =",
                                icon: "calculator",
                                iconKind: "symbolic",
                                priority: 300,
                                source: "calc",
                                groupLabel: "Calculator",
                                action: function () {
                                    ProcessPool.runDetached(["sh", "-c", "printf %s " + JSON.stringify(out) + " | wl-copy"]);
                                }
                            }
                        ]);
                    }
                });
                return null;
            }
        })

    // ═══════════════════════════════════════════════════════════════
    //  SIGNAL CONNECTIONS
    // ═══════════════════════════════════════════════════════════════
    // Re-emit app results when the async desktop index resolves.
    Connections {
        target: LauncherService
        function onFilteredEntriesChanged() {
            if (svc.query.length === 0)
                return;
            svc.submit(svc._queryId, "apps", svc._mapApps(LauncherService.filteredEntries));
        }
    }

    Connections {
        target: PluginService
        function onPluginsUpdated() {
            svc._syncPluginProviders();
        }
    }

    function _syncPluginProviders(): void {
        var plugins = PluginService.plugins || [];
        for (var i = 0; i < plugins.length; i++) {
            var p = plugins[i];
            if (p && p.searchProvider && p.searchProvider.id)
                svc.registerProvider(p.searchProvider);
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  LIFECYCLE
    // ═══════════════════════════════════════════════════════════════
    Component.onCompleted: {
        svc.registerProvider(svc._appsProvider);
        svc.registerProvider(svc._calcProvider);
        svc.registerProvider(svc._commandsProvider);
        svc._syncPluginProviders();
    }
}
