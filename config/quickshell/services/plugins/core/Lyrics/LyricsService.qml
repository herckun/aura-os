pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../../../core"
import "../../../media"
import "../../../system"

Singleton {
  id: svc

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC STATE
  // ═══════════════════════════════════════════════════════════════

  property bool hasLyrics: false
  property bool loading: false
  property string currentTrack: ""
  property string currentArtist: ""
  property var lines: []
  property int currentLineIndex: -1
  property string currentLineText: ""

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════

  function seekTo(timeMs: real): void {
    if (!svc.hasLyrics || svc.lines.length === 0) return
    var timeSec = timeMs / 1000
    var idx = _findLineIndex(timeSec)
    if (idx !== svc.currentLineIndex) {
      svc.currentLineIndex = idx
      svc.currentLineText = idx >= 0 ? svc.lines[idx].text : ""
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  INTERNAL STATE
  // ═══════════════════════════════════════════════════════════════

  property string _lastFetchKey: ""

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════

  property string _pendingTrack: ""
  property string _pendingArtist: ""
  property int _fetchGeneration: 0

  function _fetchLyrics(track: string, artist: string): void {
    if (!track) return
    var key = (artist || "") + "|" + track
    if (key === _lastFetchKey && svc.hasLyrics) return

    _pendingTrack = track
    _pendingArtist = artist || ""
    _lastFetchKey = key
    _debounceTimer.restart()
  }

  function _doFetch(): void {
    var track = _pendingTrack
    var artist = _pendingArtist
    if (!track) return

    loading = true
    currentTrack = track
    currentArtist = artist
    _fetchTimeout.restart()

    var gen = ++_fetchGeneration

    var queue = _buildSearchQueue(track, artist)
    var totalRequests = queue.length * 3
    var completed = 0
    var displayedScore = -1

    function onResult(lrc, score) {
      if (gen !== _fetchGeneration) return
      if (!lrc) return

      if (displayedScore < 0 || score > displayedScore) {
        displayedScore = score
        svc._parseLRC(lrc)
      }
    }

    function onComplete() {
      if (gen !== _fetchGeneration) return
      completed++
      if (completed >= totalRequests) {
        svc.loading = false
        if (displayedScore < 0) {
          svc._clearLyrics()
        }
      }
    }

    for (var i = 0; i < queue.length; i++) {
      var entry = queue[i]
      _fetchLyrica(entry.track, entry.artist, gen, onResult, onComplete)
      _fetchNetease(entry.track, entry.artist, gen, onResult, onComplete)
      _fetchLRCLIB(entry.track, entry.artist, gen, onResult, onComplete)
    }
  }

  function _buildSearchQueue(track: string, artist: string): var {
    var queue = []
    var seen = {}

    var cleanTrack = _cleanTrackName(track)
    var cleanArtist = _cleanArtistName(artist)

    var parsed = _parseArtistTrack(track, artist)
    var parsedArtist = parsed.artist
    var parsedTrack = parsed.track

    function add(a, t) {
      if (!a || !t) return
      var k = a.toLowerCase() + "|" + t.toLowerCase()
      if (seen[k]) return
      seen[k] = true
      queue.push({ artist: a, track: t })
    }

    add(artist, track)

    if (cleanTrack !== track || cleanArtist !== artist) {
      add(cleanArtist, cleanTrack)
    }

    if (parsedArtist && parsedTrack) {
      add(parsedArtist, parsedTrack)
      add(parsedArtist, cleanTrack)
    }

    if (cleanArtist !== artist) {
      add(cleanArtist, track)
    }

    var noFeatArtist = _removeFeaturing(artist)
    var noFeatTrack = _removeFeaturing(cleanTrack)
    if (noFeatArtist !== artist || noFeatTrack !== cleanTrack) {
      add(noFeatArtist, noFeatTrack)
      add(noFeatArtist, cleanTrack)
    }

    return queue
  }

  function _cleanTrackName(name: string): string {
    if (!name) return ""
    var s = name
    s = s.replace(/\s*\(Official\s+(Video|Audio|Music\s+Video|Lyric\s+Video)\)/i, "")
    s = s.replace(/\s*\(Official\)/i, "")
    s = s.replace(/\s*\(Music\s+Video\)/i, "")
    s = s.replace(/\s*\(Lyric\s+Video\)/i, "")
    s = s.replace(/\s*\(Visualizer\)/i, "")
    s = s.replace(/\s*\(Live\)/i, "")
    s = s.replace(/\s*\(Remaster(ed)?\s*\d*\)/i, "")
    s = s.replace(/\s*\(Remix\)/i, "")
    s = s.replace(/\s*\(Cover\)/i, "")
    s = s.replace(/\s*\(Acoustic\)/i, "")
    s = s.replace(/\s*\[Official\s+(Video|Audio|Music\s+Video|Lyric\s+Video)\]/i, "")
    s = s.replace(/\s*\[Remix\]/i, "")
    s = s.replace(/\s*\[Live\]/i, "")
    s = s.replace(/\s*-\s*Remaster(ed)?\s*\d*$/i, "")
    s = s.replace(/\s*-\s*Live$/i, "")
    s = s.replace(/\s*-\s*Remix$/i, "")
    s = s.trim()
    return s || name
  }

  function _cleanArtistName(name: string): string {
    if (!name) return ""
    var s = name
    s = s.replace(/\s*-\s*Topic$/i, "")
    s = s.trim()
    return s || name
  }

  function _parseArtistTrack(track: string, artist: string): var {
    var dashIdx = track.indexOf(" - ")
    if (dashIdx > 0 && dashIdx < track.length - 3) {
      var parsedArtist = track.substring(0, dashIdx).trim()
      var parsedTrack = track.substring(dashIdx + 3).trim()
      if (parsedArtist && parsedTrack) {
        return { artist: parsedArtist, track: parsedTrack }
      }
    }
    var colonIdx = track.indexOf(": ")
    if (colonIdx > 0 && colonIdx < track.length - 2) {
      var parsedArtist2 = track.substring(0, colonIdx).trim()
      var parsedTrack2 = track.substring(colonIdx + 2).trim()
      if (parsedArtist2 && parsedTrack2) {
        return { artist: parsedArtist2, track: parsedTrack2 }
      }
    }
    return { artist: artist, track: track }
  }

  function _removeFeaturing(name: string): string {
    if (!name) return ""
    var s = name
    s = s.replace(/\s*\(feat\.?\s+[^)]+\)/i, "")
    s = s.replace(/\s*\(ft\.?\s+[^)]+\)/i, "")
    s = s.replace(/\s*feat\.?\s+[^,]+$/i, "")
    s = s.replace(/\s*ft\.?\s+[^,]+$/i, "")
    s = s.trim()
    return s || name
  }

  function _fetchLyrica(track: string, artist: string, gen: int, onResult: var, onComplete: var): void {
    var url = "https://wilooper-lyrica.hf.space/lyrics/?artist=" + encodeURIComponent(artist) + "&song=" + encodeURIComponent(track) + "&timestamps=true&fast=true"

    RequestService.get(url, function(resp) {
      if (gen !== _fetchGeneration) { onComplete(); return }

      if (!resp.ok || !resp.data || resp.data.status !== "success" || !resp.data.data) {
        onComplete()
        return
      }

      var data = resp.data.data
      if (data.instrumental) {
        onResult(null, 0)
        onComplete()
        return
      }

      if (data.hasTimestamps && data.lyrics) {
        var score = _scoreMatch(track, artist, track, artist)
        onResult(data.lyrics, score)
      }
      onComplete()
    })
  }

  function _fetchNetease(track: string, artist: string, gen: int, onResult: var, onComplete: var): void {
    var query = encodeURIComponent(track + " " + artist)
    var url = "https://music.163.com/api/search/get?s=" + query + "&type=1&limit=5"

    RequestService.get(url, function(resp) {
      if (gen !== _fetchGeneration) { onComplete(); return }

      if (!resp.ok || !resp.data || !resp.data.result || !resp.data.result.songs || resp.data.result.songs.length === 0) {
        onComplete()
        return
      }

      var songId = resp.data.result.songs[0].id
      var lyricUrl = "https://music.163.com/api/song/lyric?id=" + songId + "&lv=1"

      RequestService.get(lyricUrl, function(resp2) {
        if (gen !== _fetchGeneration) { onComplete(); return }

        if (!resp2.ok || !resp2.data || !resp2.data.lrc || !resp2.data.lrc.lyric) {
          onComplete()
          return
        }

        var score = _scoreMatch(track, artist, track, artist)
        onResult(resp2.data.lrc.lyric, score)
        onComplete()
      })
    })
  }

  function _fetchLRCLIB(track: string, artist: string, gen: int, onResult: var, onComplete: var): void {
    var url = "https://lrclib.net/api/search?track_name=" + encodeURIComponent(track) + "&artist_name=" + encodeURIComponent(artist)

    RequestService.get(url, function(resp) {
      if (gen !== _fetchGeneration) { onComplete(); return }

      if (!resp.ok || !resp.data || !Array.isArray(resp.data) || resp.data.length === 0) {
        onComplete()
        return
      }

      var trackDuration = MediaService.duration / 1000
      var best = null
      var bestScore = -Infinity

      for (var i = 0; i < resp.data.length; i++) {
        var item = resp.data[i]
        if (!item.syncedLyrics || item.syncedLyrics.length === 0) continue
        if (item.instrumental) continue

        var durationDiff = trackDuration > 0 ? Math.abs((item.duration || 0) - trackDuration) : 0
        var score = 1000 - durationDiff
        if (score > bestScore) { bestScore = score; best = item }
      }

      if (best) {
        onResult(best.syncedLyrics, _scoreMatch(track, artist, track, artist) + bestScore)
      }
      onComplete()
    })
  }

  function _scoreMatch(searchTrack: string, searchArtist: string, resultTrack: string, resultArtist: string): int {
    var score = 0
    if (searchTrack.toLowerCase() === resultTrack.toLowerCase()) score += 100
    if (searchArtist.toLowerCase() === resultArtist.toLowerCase()) score += 100
    return score
  }

  function _parseLRC(lrc: string): void {
    var result = []
    var lines = lrc.split("\n")

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim()
      if (!line) continue

      if (line.match(/^\[(ti|ar|al|by|offset):/i)) continue

      var match = line.match(/^\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)/)
      if (!match) continue

      var min = parseInt(match[1])
      var sec = parseInt(match[2])
      var ms = parseInt(match[3])
      if (match[3].length === 2) ms *= 10
      if (match[3].length === 1) ms *= 100
      var text = match[4].trim()

      if (!text) continue
      if (text.match(/^(作词|作曲|编曲|制作人|作詞|作曲|編曲|製作人)\s*:/)) continue

      var time = min * 60 + sec + ms / 1000
      result.push({ time: time, text: text })
    }

    if (result.length > 0) {
      svc.lines = result
      svc.hasLyrics = true
      svc.loading = false
      svc.currentLineIndex = -1
      svc.currentLineText = ""
      if (svc._fetchTimeout) svc._fetchTimeout.stop()
    } else {
      svc.loading = false
      svc._clearLyrics()
    }
  }

  function _clearLyrics(): void {
    svc.hasLyrics = false
    svc.lines = []
    svc.currentLineIndex = -1
    svc.currentLineText = ""
    if (svc._fetchTimeout) svc._fetchTimeout.stop()
  }

  function _findLineIndex(timeSec: real): int {
    if (svc.lines.length === 0) return -1

    var idx = -1
    for (var i = svc.lines.length - 1; i >= 0; i--) {
      if (svc.lines[i].time <= timeSec) {
        idx = i
        break
      }
    }
    return idx
  }

  // ═══════════════════════════════════════════════════════════════
  //  SIGNAL CONNECTIONS
  // ═══════════════════════════════════════════════════════════════

  Connections {
    target: MediaService
    function onCurrentTitleChanged() {
      if (MediaService.hasPlayer && MediaService.currentTitle) {
        svc.currentTrack = MediaService.currentTitle
        svc.currentArtist = MediaService.currentArtist
        svc.loading = true
        _fetchLyrics(MediaService.currentTitle, MediaService.currentArtist)
      } else {
        svc._clearLyrics()
      }
    }
    function onCurrentArtistChanged() {
      if (MediaService.hasPlayer && MediaService.currentTitle) {
        svc.currentArtist = MediaService.currentArtist
        _fetchLyrics(MediaService.currentTitle, MediaService.currentArtist)
      }
    }
    function onHasPlayerChanged() {
      if (!MediaService.hasPlayer) {
        _clearLyrics()
      } else if (MediaService.currentTitle) {
        svc.currentTrack = MediaService.currentTitle
        svc.currentArtist = MediaService.currentArtist
        svc.loading = true
        _fetchLyrics(MediaService.currentTitle, MediaService.currentArtist)
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  TIMERS
  // ═══════════════════════════════════════════════════════════════

  Timer {
    id: _debounceTimer
    interval: 500
    repeat: false
    onTriggered: svc._doFetch()
  }

  Timer {
    id: _fetchTimeout
    interval: 15000
    repeat: false
    onTriggered: {
      if (svc.loading) {
        svc.loading = false
        if (!svc.hasLyrics) {
          svc._clearLyrics()
        }
      }
    }
  }

  Timer {
    interval: 200
    running: MediaService.hasPlayer && MediaService.playbackStatus === "Playing" && svc.hasLyrics
    repeat: true
    onTriggered: {
      svc.seekTo(MediaService.position * 1000)
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════

  Component.onCompleted: {
    if (MediaService.hasPlayer && MediaService.currentTitle) {
      svc.currentTrack = MediaService.currentTitle
      svc.currentArtist = MediaService.currentArtist
      svc.loading = true
      _fetchLyrics(MediaService.currentTitle, MediaService.currentArtist)
    }
  }
}
