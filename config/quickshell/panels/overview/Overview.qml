import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import "../../styles"
import "../../core"
import "../../services"
import "../../components"

// ═══════════════════════════════════════════════════════════════════
//  Overview — the reference implementation of the OverlayPanel golden
//  tabs. All visuals come from Theme tokens.
// ═══════════════════════════════════════════════════════════════════

OverlayPanel {
    id: overview

    closeOnEscape: false
    panelWidth: Math.min((screen ? screen.width : 1920) * 0.44, 640)
    topRatio: 0.10

    // ── State ────────────────────────────────────────────────────
    property string searchQuery: ""
    property int selectedIndex: 0
    property bool isSearching: false
    property int activeTab: 0

    property var _overviewPlugins: []

    readonly property var _tabs: {
        var tabs = [];
        for (var i = 0; i < _overviewPlugins.length; i++) {
            var p = _overviewPlugins[i];
            var t = p.manifest.overviewTab;
            if (!t)
                continue;
            tabs.push({
                icon: t.icon,
                label: t.label,
                key: String(tabs.length + 1),
                tab: tabs.length,
                plugin: p
            });
        }
        return tabs;
    }
    property var _activePlugin: (activeTab >= 0 && activeTab < _tabs.length) ? _tabs[activeTab].plugin : null

    readonly property bool _hasTabs: !isSearching && _tabs.length > 0
    readonly property bool _showBody: isSearching || _activePlugin !== null

    readonly property var _hints: {
        if (overview.isSearching)
            return [
                {
                    k: "↑ ↓",
                    l: "navigate"
                },
                {
                    k: "↵",
                    l: "open"
                },
                {
                    k: "esc",
                    l: "clear"
                }
            ];
        if (overview._tabs.length > 0)
            return [
                {
                    k: "tab",
                    l: "switch"
                },
                {
                    k: "1–" + overview._tabs.length,
                    l: "jump"
                },
                {
                    k: "esc",
                    l: "close"
                }
            ];
        return [
            {
                k: "esc",
                l: "close"
            }
        ];
    }
    readonly property string _footerRight: {
        if (overview.isSearching) {
            var n = SearchService.results.length;
            return n === 0 ? "" : n + (n === 1 ? " result" : " results");
        }
        if (overview._activePlugin)
            return (overview._activePlugin.manifest.name || "").toUpperCase();
        return "";
    }

    // ── Helpers ──────────────────────────────────────────────────
    function _refreshOverviewPlugins(): void {
        if (!PluginService.loaded) {
            _overviewPlugins = [];
            return;
        }
        _overviewPlugins = PluginService.getPluginsForLocation("overview").filter(function (p) {
            return PluginService.isPluginEnabledForLocation(p.id, "overview");
        });
    }

    function _cycleTab(direction: int): void {
        if (_tabs.length === 0)
            return;
        activeTab = (activeTab + direction + _tabs.length) % _tabs.length;
    }

    function _clearSearch(): void {
        overviewSearch.text = "";
        overview.searchQuery = "";
        overview.isSearching = false;
        overview.selectedIndex = 0;
        SearchService.search("");
    }

    // ── Lifecycle / open-close ───────────────────────────────────
    onPanelOpened: {
        overview.activeTab = 0;
        _clearSearch();
        overviewSearch.forceFocus();
    }

    Component.onCompleted: _refreshOverviewPlugins()

    Connections {
        target: PluginService
        function onPluginsUpdated() {
            overview._refreshOverviewPlugins();
        }
    }

    Connections {
        target: HyprlandService
        function onActiveWsIdChanged() {
            if (overview.visible)
                overview.visible = false;
        }
    }

    // ── Floating hint bar (screen bottom, outside the card) ──────
    overlayFooter: Surface {
        color: Theme.backgroundTertiary
        bordered: true
        radius: Theme.radiusPill
        implicitWidth: barRow.implicitWidth + Theme.spaceLg * 2
        implicitHeight: barRow.implicitHeight + Theme.spaceSm * 2

        Row {
            id: barRow
            anchors.centerIn: parent
            spacing: Theme.spaceMd

            Repeater {
                model: overview._hints
                delegate: KeyHint {
                    required property var modelData
                    anchors.verticalCenter: parent.verticalCenter
                    key: modelData.k
                    label: modelData.l
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 12
                color: Theme.border
                visible: overview._footerRight.length > 0
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: overview._footerRight
                visible: overview._footerRight.length > 0
                color: Theme.textDisabled
                font.pixelSize: Theme.fontSizeCaption
                font.family: Theme.fontFamilyMono
                font.letterSpacing: 0.04
            }
        }
    }

    // ── Content: one command-palette card ────────────────────────
    content: FocusScope {
        id: focusScope
        width: parent.width
        implicitHeight: card.implicitHeight
        height: implicitHeight
        focus: true

        Keys.onPressed: function (event) {
            var searchFocused = overviewSearch.input.activeFocus;
            switch (event.key) {
            case Qt.Key_Escape:
                if (overview.isSearching && overviewSearch.text.length > 0) {
                    overview._clearSearch();
                    event.accepted = true;
                } else if (searchFocused) {
                    overviewSearch.input.focus = false;
                    overviewSearch.input.cursorVisible = false;
                    event.accepted = true;
                } else {
                    overview.visible = false;
                    event.accepted = true;
                }
                break;
            case Qt.Key_Tab:
                if (!overview.isSearching && overview._tabs.length > 0) {
                    overview._cycleTab(1);
                    event.accepted = true;
                }
                break;
            case Qt.Key_Backtab:
                if (!overview.isSearching && overview._tabs.length > 0) {
                    overview._cycleTab(-1);
                    event.accepted = true;
                }
                break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
                if (searchFocused && overview.isSearching && SearchService.results.length > 0) {
                    SearchService.activate(overview.selectedIndex);
                    overview.visible = false;
                    event.accepted = true;
                }
                break;
            case Qt.Key_Up:
                if (searchFocused && overview.isSearching) {
                    if (overview.selectedIndex > 0)
                        overview.selectedIndex--;
                    event.accepted = true;
                }
                break;
            case Qt.Key_Down:
                if (searchFocused && overview.isSearching) {
                    var len = SearchService.results.length;
                    if (len > 0)
                        overview.selectedIndex = Math.min(overview.selectedIndex + 1, len - 1);
                    event.accepted = true;
                }
                break;
            default:
                if (!overview.isSearching && overview._tabs.length > 0) {
                    var num = event.key - Qt.Key_0;
                    if (num >= 1 && num <= overview._tabs.length && num <= 6) {
                        overview.activeTab = num - 1;
                        event.accepted = true;
                    }
                }
                break;
            }
        }

        MultiEffect {
            source: card
            anchors.fill: card
            z: -1
            autoPaddingEnabled: true
            blurMax: 64
            shadowEnabled: true
            shadowColor: "#000000"
            shadowBlur: 1.0
            shadowVerticalOffset: 10
            shadowOpacity: 0.7
        }

        Surface {
            id: card
            width: parent.width
            implicitHeight: cardCol.implicitHeight
            height: implicitHeight
            radius: Theme.radiusLarge
            color: Theme.backgroundSecondary
            clip: true

            Column {
                id: cardCol
                width: parent.width
                spacing: 0

                Item {
                    width: parent.width
                    height: 54

                    Input {
                        id: overviewSearch
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: Theme.spaceLg
                        anchors.rightMargin: Theme.spaceLg
                        maxHeight: 42
                        color: "transparent"
                        border.width: 0
                        iconName: "search"
                        iconSize: Theme.fontSizeTitle
                        fontFamily: Theme.fontFamily
                        persistentPlaceholder: true
                        placeholder: "Search apps, calc, or plugins…"
                        fontSize: Theme.fontSizeTitle
                        showClearButton: false
                        escapeClears: false
                        iconColor: Theme.textSecondary
                        iconFocusedColor: Theme.accent
                        defaultFocus: true

                        onTextEdited: function (text) {
                            overview.searchQuery = text;
                            overview.isSearching = text.length > 0;
                            overview.selectedIndex = 0;
                            SearchService.search(text);
                        }
                    }
                }

                Divider {
                    width: parent.width
                    visible: overview._hasTabs || overview._showBody
                }

                Item {
                    width: parent.width
                    height: overview._hasTabs ? 52 : 0
                    visible: overview._hasTabs
                    clip: true

                    TabBar {
                        anchors.centerIn: parent
                        tabs: overview._tabs
                        currentIndex: overview.activeTab
                        onSelected: idx => overview.activeTab = idx
                    }
                }

                Item {
                    id: bodyWrap
                    width: parent.width
                    visible: overview._showBody
                    height: overview._showBody ? body.height + Theme.spaceSm * 2 : 0

                    Surface {
                        id: body
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: Theme.spaceMd
                        anchors.rightMargin: Theme.spaceMd
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.backgroundSecondary
                        radius: Theme.radiusLarge
                        clip: true
                        height: {
                            if (overview.isSearching)
                                return SearchService.results.length > 0 ? Math.min(380, resultsCol.implicitHeight + Theme.spaceSm * 2) : 120;
                            var ih = pluginHost.implicitHeight || 0;
                            return ih > 0 ? Math.min(460, ih + Theme.spaceSm * 2) : 0;
                        }

                        Behavior on height {
                            enabled: Theme.animationsEnabled
                            NumberAnimation {
                                duration: Theme.animationFast
                                easing.type: Easing.OutCubic
                            }
                        }

                        Flickable {
                            id: resultsFlick
                            anchors.fill: parent
                            anchors.margins: Theme.spaceSm
                            contentHeight: resultsCol.implicitHeight
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            visible: overview.isSearching

                            // Keep the arrow-selected row within the viewport.
                            function ensureVisible(top, bottom) {
                                if (top < contentY)
                                    contentY = Math.max(0, top - Theme.spaceXs)
                                else if (bottom > contentY + height)
                                    contentY = Math.min(Math.max(0, contentHeight - height), bottom - height + Theme.spaceXs)
                            }

                            Column {
                                id: resultsCol
                                width: parent.width
                                spacing: Theme.spaceXxs

                                Repeater {
                                    model: overview.isSearching ? SearchService.results.slice(0, 20) : []

                                    delegate: Column {
                                        id: resultGroup
                                        required property int index
                                        required property var modelData
                                        readonly property bool groupStart: index === 0 || SearchService.results[index - 1].source !== modelData.source
                                        width: resultsCol.width
                                        spacing: Theme.spaceXxs

                                        SectionLabel {
                                            visible: resultGroup.groupStart
                                            leftPadding: Theme.spaceMd
                                            topPadding: resultGroup.index === 0 ? Theme.space2 : Theme.spaceMd
                                            bottomPadding: Theme.spaceXxs
                                            label: resultGroup.modelData.groupLabel || (resultGroup.modelData.source || "")
                                        }

                                        ResultRow {
                                            width: parent.width
                                            result: resultGroup.modelData
                                            selected: resultGroup.index === overview.selectedIndex
                                            showSource: false
                                            onHovered: overview.selectedIndex = resultGroup.index
                                            onClicked: {
                                                SearchService.activate(resultGroup.index);
                                                overview.visible = false;
                                            }
                                        }

                                        Connections {
                                            target: overview
                                            function onSelectedIndexChanged() {
                                                if (resultGroup.index !== overview.selectedIndex)
                                                    return;
                                                resultsFlick.ensureVisible(resultGroup.y, resultGroup.y + resultGroup.height);
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.spaceSm
                            visible: overview.isSearching && SearchService.results.length === 0

                            readonly property bool _indexing: !LauncherService.loaded

                            Spinner {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spinnerSize: 24
                                visible: parent._indexing
                            }
                            Icon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                source: Icons.get("search")
                                size: 26
                                color: Theme.textDisabled
                                visible: !parent._indexing
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: parent._indexing ? "SEARCHING…" : "NO RESULTS"
                                color: Theme.textDisabled
                                font.pixelSize: Theme.fontSizeCaption
                                font.family: Theme.fontFamilyMono
                                font.letterSpacing: 0.08
                            }
                        }

                        Flickable {
                            id: pluginFlick
                            anchors.fill: parent
                            anchors.margins: Theme.spaceSm
                            clip: true
                            contentHeight: pluginHost.implicitHeight
                            boundsBehavior: Flickable.StopAtBounds
                            visible: !overview.isSearching && overview._activePlugin !== null

                            PluginHost {
                                id: pluginHost
                                width: pluginFlick.width
                                location: "overview"
                                onlyPluginId: overview._activePlugin ? overview._activePlugin.id : ""
                            }

                            MouseArea {
                                anchors.fill: parent
                                propagateComposedEvents: true
                                onClicked: function (mouse) {
                                    if (pluginHost.activeItem && pluginHost.activeItem.forceActiveFocus)
                                        pluginHost.activeItem.forceActiveFocus();
                                    mouse.accepted = false;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
