pragma Singleton
pragma ComponentBehavior: Bound
import QtQml
import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../../core"
import "../system"

Singleton {
    id: svc

    // ═══════════════════════════════════════════════════════════════
    //  PUBLIC STATE
    // ═══════════════════════════════════════════════════════════════

    property bool hasPlayer: false
    property string playbackStatus: "Stopped"
    property string currentTitle: ""
    property string currentArtist: ""
    property string currentAlbum: ""
    property string currentArtUrl: ""
    property real position: activePlayer?.position ?? 0
    property real duration: activePlayerStableLength
    property var eqBands: [0, 0, 0, 0, 0, 0, 0, 0]

    // ═══════════════════════════════════════════════════════════════
    //  PUBLIC API
    // ═══════════════════════════════════════════════════════════════

    function playPause(): void {
        activePlayer?.togglePlaying();
    }
    function next(): void {
        activePlayer?.next();
    }
    function previous(): void {
        if (!activePlayer)
            return;
        if (activePlayer.position > 8 && activePlayer.canSeek)
            activePlayer.position = 0.1;
        else if (activePlayer.canGoPrevious)
            activePlayer.previous();
    }

    function setActivePlayer(player: MprisPlayer): void {
        activePlayer = player;
        if (player)
            _persistIdentity(player.identity);
    }

    function init(): void {}

    // ═══════════════════════════════════════════════════════════════
    //  INTERNAL STATE
    // ═══════════════════════════════════════════════════════════════

    readonly property bool hasActivePlasmaIntegration: Mpris.players.values.some(p => p.dbusName?.startsWith("org.mpris.MediaPlayer2.plasma-browser-integration"))

    property var _excludedPlayers: []

    readonly property list<MprisPlayer> availablePlayers: {
        var players = Mpris.players.values;
        var excluded = _excludedPlayers;
        if (excluded.length === 0)
            return players.filter(_isRealPlayer);
        return players.filter(function (p) {
            if (!_isRealPlayer(p))
                return false;
            var identity = (p.identity || "").toLowerCase();
            var desktopEntry = (p.desktopEntry || "").toString().toLowerCase();
            return !excluded.some(function (ex) {
                var exLower = String(ex).toLowerCase().trim();
                if (!exLower)
                    return false;
                if (identity.includes(exLower) || desktopEntry.includes(exLower))
                    return true;
                if (exLower.indexOf(".") !== -1) {
                    var lastPart = exLower.split(".").pop();
                    if (lastPart && (identity.includes(lastPart) || desktopEntry.includes(lastPart)))
                        return true;
                }
                if (identity.length >= 3 && exLower.includes(identity))
                    return true;
                return false;
            });
        });
    }

    property MprisPlayer activePlayer: null
    property real activePlayerStableLength: 0

    property bool _isStream: false
    property var _eqHandle: null

    readonly property int _basePositionInterval: 250
    readonly property int _baseStaleInterval: 120000
    readonly property int _positionInterval: PerformanceService.scaleInterval(_basePositionInterval)
    readonly property int _staleInterval: PerformanceService.scaleInterval(_baseStaleInterval)

    // ═══════════════════════════════════════════════════════════════
    //  PRIVATE HELPERS
    // ═══════════════════════════════════════════════════════════════

    // ── Player filtering ──

    readonly property list<string> _blockedPrefixes: {
        var list = ["org.mpris.MediaPlayer2.playerctld"];
        if (hasActivePlasmaIntegration) {
            list.push("org.mpris.MediaPlayer2.firefox");
            list.push("org.mpris.MediaPlayer2.chromium");
            list.push("org.mpris.MediaPlayer2.brave");
        }
        return list;
    }

    function _isRealPlayer(player): bool {
        if (!player?.dbusName)
            return false;
        if (player.dbusName.endsWith(".mpd") && !player.dbusName.endsWith("MediaPlayer2.mpd"))
            return false;
        if (isFirefoxYoutubeHoverPreview(player))
            return false;
        return !_blockedPrefixes.some(prefix => player.dbusName.startsWith(prefix));
    }

    function isFirefoxYoutubeHoverPreview(player: MprisPlayer): bool {
        if (!player)
            return false;
        var id = (player.identity || "").toLowerCase();
        if (!id.includes("firefox"))
            return false;
        var url = "";
        try {
            url = (player.metadata?.["xesam:url"] || "").toString();
        } catch (e) {}
        return /^https?:\/\/(www\.)?youtube\.com\/?($|\?|#)/i.test(url);
    }

    function isIdle(player: MprisPlayer): bool {
        return player && player.playbackState === MprisPlaybackState.Stopped && !player.trackTitle && !player.trackArtist;
    }

    // ── Player selection ──

    function _resolveActivePlayer(): void {
        var playing = availablePlayers.find(function (p) {
            return p.isPlaying;
        });
        if (playing) {
            activePlayer = playing;
            _persistIdentity(playing.identity);
            return;
        }
        if (activePlayer && availablePlayers.indexOf(activePlayer) >= 0 && !isIdle(activePlayer))
            return;
        var savedId = Store.media.lastPlayerIdentity;
        if (savedId) {
            var match = availablePlayers.find(function (p) {
                return p.identity === savedId;
            });
            if (match && !isIdle(match)) {
                activePlayer = match;
                return;
            }
        }
        activePlayer = availablePlayers.find(function (p) {
            return p.canControl && !isIdle(p);
        }) ?? null;
        if (activePlayer)
            _persistIdentity(activePlayer.identity);
    }

    function _persistIdentity(identity: string): void {
        if (identity)
            Store.media.lastPlayerIdentity = identity;
    }

    // ── State management ──

    function _resetState(): void {
        svc.playbackStatus = "Stopped";
        svc.currentTitle = "";
        svc.currentArtist = "";
        svc.currentAlbum = "";
        svc.currentArtUrl = "";
        svc.hasPlayer = false;
        svc._isStream = false;
    }

    function _normalizeArtUrl(url): string {
        if (!url)
            return "";
        if (url.indexOf("file://") === 0)
            return url;
        if (url.indexOf("/") === 0)
            return "file://" + url;
        return url;
    }

    function _syncFromActive(): void {
        var p = svc.activePlayer;

        if (!p) {
            if (svc.hasPlayer) {
                _resetState();
                _updateSpectrumWatcher();
            }
            return;
        }

        if (p.lengthSupported && p.length > 1) {
            svc.activePlayerStableLength = p.length;
        }

        var newStatus = p.isPlaying ? "Playing" : "Paused";
        var newTitle = p.trackTitle || "";
        var newArtist = p.trackArtist || "";
        var newAlbum = p.trackAlbum || "";
        var newArtUrl = _normalizeArtUrl(p.trackArtUrl);
        var newIsStream = p.length <= 0;
        var newHasPlayer = (newTitle !== "" || newIsStream) && newStatus !== "Stopped";

        var statusChanged = newStatus !== svc.playbackStatus;
        var trackChanged = newTitle !== svc.currentTitle || newArtist !== svc.currentArtist || newAlbum !== svc.currentAlbum;
        var hasPlayerChanged = newHasPlayer !== svc.hasPlayer;

        svc.playbackStatus = newStatus;
        svc.currentTitle = newTitle;
        svc.currentArtist = newArtist;
        svc.currentAlbum = newAlbum;
        svc.currentArtUrl = newArtUrl;
        svc._isStream = newIsStream;
        svc.hasPlayer = newHasPlayer;

        if (trackChanged || statusChanged) {}
        if (statusChanged || hasPlayerChanged) {
            _updateSpectrumWatcher();
        }
    }

    // ── Audio analyzer ──

    function _parseCavaLine(line): var {
        var parts = line.trim().split(";");
        if (parts.length < 7)
            return null;

        var raw = [];
        for (var i = 0; i < 7; i++) {
            raw.push((parseInt(parts[i]) || 0) / 7.0);
        }
        raw.push(0);
        return raw.some(v => v > 0) ? raw : null;
    }

    function _startAudioAnalyzer(): void {
        if (svc._eqHandle)
            return;
        var confPath = AppInfo.configHome + "/cava/config.conf";
        svc._eqHandle = WatchService.register("media-eq", ["cava", "-p", confPath], function (line) {
            svc.eqBands = _parseCavaLine(line) ?? [0, 0, 0, 0, 0, 0, 0, 0];
        }, function () {
            svc._eqHandle = null;
        });
    }

    function _stopAudioAnalyzer(): void {
        svc._eqHandle?.stop();
        svc._eqHandle = null;
        if (svc.eqBands[0] !== 0)
            svc.eqBands = [0, 0, 0, 0, 0, 0, 0, 0];
    }

    function _updateSpectrumWatcher(): void {
        if (svc.hasPlayer && svc.playbackStatus === "Playing") {
            _startAudioAnalyzer();
        } else {
            _stopAudioAnalyzer();
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  SYSTEM INTEGRATION
    // ═══════════════════════════════════════════════════════════════

    // ═══════════════════════════════════════════════════════════════
    //  SIGNAL CONNECTIONS
    // ═══════════════════════════════════════════════════════════════

    Instantiator {
        model: svc.availablePlayers

        Connections {
            required property MprisPlayer modelData
            target: modelData

            function onIsPlayingChanged() {
                if (modelData.isPlaying)
                    svc._resolveActivePlayer();
            }
        }
    }

    Connections {
        target: svc.activePlayer
        function onTrackChanged() {
            _syncFromActive();
        }
        function onPostTrackChanged() {
            _syncFromActive();
        }
        function onPlaybackStateChanged() {
            if (isIdle(svc.activePlayer))
                svc._resolveActivePlayer();
            _syncFromActive();
        }
        function onTrackTitleChanged() {
            if (isIdle(svc.activePlayer))
                svc._resolveActivePlayer();
            _syncFromActive();
        }
        function onTrackArtistChanged() {
            if (isIdle(svc.activePlayer))
                svc._resolveActivePlayer();
            _syncFromActive();
        }
        function onTrackAlbumChanged() {
            _syncFromActive();
        }
        function onTrackArtUrlChanged() {
            _syncFromActive();
        }
        function onLengthChanged() {
            if (svc.activePlayer && svc.activePlayer.lengthSupported && svc.activePlayer.length > 1) {
                svc.activePlayerStableLength = svc.activePlayer.length;
            }
        }
    }

    onAvailablePlayersChanged: _resolveActivePlayer()
    onActivePlayerChanged: {
        activePlayerStableLength = (activePlayer && activePlayer.lengthSupported && activePlayer.length > 1) ? activePlayer.length : 0;
        _syncFromActive();
    }

    // ═══════════════════════════════════════════════════════════════
    //  TIMERS
    // ═══════════════════════════════════════════════════════════════

    Timer {
        running: svc.activePlayer?.isPlaying ?? false
        interval: PerformanceService.scaleInterval(1000)
        repeat: true
        onTriggered: {
            var player = svc.activePlayer;
            if (!player)
                return;
            player.positionChanged();
        }
    }

    Timer {
        id: staleTimer
        interval: svc._staleInterval
        repeat: false
        onTriggered: {
            if (!svc.hasPlayer)
                return;
            Logger.warn("media", "Stale timer — clearing player (no update for 2m)");
            _resetState();
            _updateSpectrumWatcher();
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  LIFECYCLE
    // ═══════════════════════════════════════════════════════════════

    function _loadExcludedPlayers(): void {
        _excludedPlayers = Store.toArray(Store.media.excludePlayers);
    }

    Connections {
        target: Store
        function onChanged(key, value, previous) {
            if (key === "media.excludePlayers") {
                svc._loadExcludedPlayers();
            }
        }
    }

    Component.onCompleted: {
        _loadExcludedPlayers();
        _resolveActivePlayer();
        if (svc.activePlayer)
            _syncFromActive();
    }

    Component.onDestruction: {
        _stopAudioAnalyzer();
    }
}
