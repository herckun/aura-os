pragma Singleton
import QtQml
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
  id: svc

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC STATE
  // ═══════════════════════════════════════════════════════════════
  readonly property PwNode _defaultSink: Pipewire.defaultAudioSink
  readonly property PwNode sink: _resolveSink(_defaultSink, Pipewire.linkGroups.values, Pipewire.nodes.values)
  readonly property PwNode source: Pipewire.defaultAudioSource
  readonly property bool effectsActive: _isEeSink(_defaultSink)

  readonly property real volume: sink?.audio?.volume ?? 0
  readonly property bool muted: sink?.audio?.muted ?? false
  readonly property real micVolume: source?.audio?.volume ?? 0
  readonly property bool micMuted: source?.audio?.muted ?? false

  readonly property string sinkName: sink?.description || sink?.nickname || sink?.name || "Unknown"
  readonly property string sourceName: source?.description || source?.nickname || source?.name || "Unknown"

  readonly property bool sinkReady: sink?.ready ?? false
  readonly property bool sourceReady: source?.ready ?? false

  readonly property var outputDevices: _getDevices(true)
  readonly property var inputDevices: _getDevices(false)

  readonly property var playbackStreams: _getStreams(true)
  readonly property var recordingStreams: _getStreams(false)

  // ═══════════════════════════════════════════════════════════════
  //  SYSTEM INTEGRATION
  // ═══════════════════════════════════════════════════════════════
  PwObjectTracker {
    objects: Pipewire.nodes.values
  }

  Timer {
    id: streamGraceTimer
    interval: 400
    repeat: false
    onTriggered: {
      svc._pruneStreamSeen()
      svc._streamRev++
    }
  }

  function _isEeNode(n: PwNode): bool {
    if (!n) return false
    var name = (n.name || "").toLowerCase()
    if (name.indexOf("easyeffects") === 0 || name.indexOf("pulseeffects") === 0 ||
        name.indexOf("ee_soe_") === 0 || name.indexOf("ee_sie_") === 0) return true
    var p = n.properties || ({})
    var blob = ((p["application.id"] || "") + " " + (p["application.name"] || "") + " " +
                (p["node.name"] || "")).toLowerCase()
    return blob.indexOf("easyeffects") !== -1 || blob.indexOf("easy effects") !== -1
  }

  function _isEeSink(n: PwNode): bool {
    return (n?.isSink ?? false) && !n.isStream && _isEeNode(n)
  }

  function _resolveSink(def: PwNode, groups: var, nodes: var): PwNode {
    if (!def || !_isEeSink(def)) return def
    var real = _downstreamSink(def, groups)
    if (real) return real
    var hwSinks = []
    for (var i = 0; i < nodes.length; i++) {
      var n = nodes[i]
      if (n.isSink && !n.isStream && !_isEeNode(n) &&
          n.properties && n.properties["device.api"]) {
        hwSinks.push(n)
      }
    }
    if (hwSinks.length === 1) return hwSinks[0]
    return def
  }

  function _downstreamSink(start: PwNode, groups: var): PwNode {
    var visited = {}
    visited[start.id] = true
    var frontier = [start.id]
    for (var depth = 0; depth < 6 && frontier.length > 0; depth++) {
      var next = []
      for (var i = 0; i < groups.length; i++) {
        var g = groups[i]
        var s = g.source
        var t = g.target
        if (!s || !t || frontier.indexOf(s.id) === -1 || visited[t.id]) continue
        visited[t.id] = true
        if (t.isSink && !t.isStream && t.audio && !_isEeNode(t)) return t
        next.push(t.id)
      }
      frontier = next
    }
    return null
  }

  // ═══════════════════════════════════════════════════════════════
  //  SIGNAL CONNECTIONS
  // ═══════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════
  function _getDevices(isOutput: bool): var {
    if (!Pipewire.ready) return []
    var devices = []
    var nodes = Pipewire.nodes.values
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i]
      if (!node.ready || !node.audio || node.isStream) continue
      if (isOutput && !node.isSink) continue
      if (!isOutput && node.isSink) continue
      var name = node.description || node.nickname || node.name || ""
      if (name === "") continue
      var isDefault = isOutput
        ? node === Pipewire.defaultAudioSink
        : node === Pipewire.defaultAudioSource
      devices.push({
        name: name,
        node: node,
        isDefault: isDefault,
        isVirtual: !(node.properties && node.properties["device.api"])
      })
    }
    return devices
  }

  property var _streamSeen: ({})
  readonly property int _streamGraceMs: 2000
  property int _streamRev: 0

  function _pruneStreamSeen(): void {
    var alive = {}
    var nodes = Pipewire.nodes.values
    for (var i = 0; i < nodes.length; i++) alive[nodes[i].id] = true
    var seen = svc._streamSeen
    for (var k in seen) {
      if (!alive[k]) delete seen[k]
    }
  }

  function _getStreams(sinkSide: bool): var {
    if (!Pipewire.ready) return []
    var rev = svc._streamRev
    var now = Date.now()
    var streams = []
    var nodes = Pipewire.nodes.values
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i]
      if (!node.ready || !node.audio || !node.isStream) continue
      if (node.isSink !== sinkSide) continue
      if (!sinkSide && node.properties && node.properties["stream.monitor"] === "true") continue
      var seen = svc._streamSeen[node.id]
      if (!seen) {
        svc._streamSeen[node.id] = now
        streamGraceTimer.restart()
        continue
      }
      if (now - seen < svc._streamGraceMs) {
        streamGraceTimer.restart()
        continue
      }
      var app = node.properties ? (node.properties["application.name"] || "") : ""
      var media = node.properties ? (node.properties["media.name"] || "") : ""
      streams.push({
        name: app || node.nickname || node.description || node.name || "Unknown",
        media: media,
        node: node
      })
    }
    return streams
  }

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════
  function setOutputDevice(node: PwNode): void {
    Pipewire.preferredDefaultAudioSink = node
  }

  function setInputDevice(node: PwNode): void {
    Pipewire.preferredDefaultAudioSource = node
  }

  function volumeUp(): void {
    if (sink?.ready && sink?.audio) {
      sink.audio.volume = Math.min(1.5, sink.audio.volume + 0.1)
    }
  }

  function volumeDown(): void {
    if (sink?.ready && sink?.audio) {
      sink.audio.volume = Math.max(0, sink.audio.volume - 0.1)
    }
  }

  function setVolume(v: real): void {
    if (sink?.ready && sink?.audio) {
      sink.audio.muted = false
      sink.audio.volume = Math.max(0, Math.min(1.5, v))
    }
  }

  function toggleMute(): void {
    if (sink?.ready && sink?.audio) {
      sink.audio.muted = !sink.audio.muted
    }
  }

  function toggleMicMute(): void {
    if (source?.ready && source?.audio) {
      source.audio.muted = !source.audio.muted
    }
  }

  function setMicVolume(v: real): void {
    if (source?.ready && source?.audio) {
      source.audio.muted = false
      source.audio.volume = Math.max(0, Math.min(1.5, v))
    }
  }

  function setNodeVolume(node: PwNode, v: real): void {
    var n = _isEeSink(node) ? svc.sink : node
    if (n?.ready && n?.audio) {
      n.audio.muted = false
      n.audio.volume = Math.max(0, Math.min(1.5, v))
    }
  }

  function toggleNodeMute(node: PwNode): void {
    var n = _isEeSink(node) ? svc.sink : node
    if (n?.ready && n?.audio) {
      n.audio.muted = !n.audio.muted
    }
  }

  function snapshot() {
    return {
      sinkName: sinkName,
      sourceName: sourceName,
      sinkReady: sinkReady,
      sourceReady: sourceReady
    }
  }
}
