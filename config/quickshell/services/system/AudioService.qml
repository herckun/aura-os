pragma Singleton
import QtQml
import Quickshell
import Quickshell.Services.Pipewire
import "../../core"

Singleton {
  id: svc

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC STATE
  // ═══════════════════════════════════════════════════════════════
  readonly property PwNode _defaultSink: Pipewire.defaultAudioSink
  readonly property PwNode sink: _resolveSink(_defaultSink, _eeTargetName, Pipewire.nodes.values)
  readonly property PwNode source: Pipewire.defaultAudioSource

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

  property string _eeTargetName: ""

  on_DefaultSinkChanged: _refreshEeTarget()

  function _resolveSink(def: PwNode, targetName: string, nodes: var): PwNode {
    if (def && def.name === "easyeffects_sink") {
      if (targetName) {
        for (var i = 0; i < nodes.length; i++) {
          var n = nodes[i]
          if (n.isSink && !n.isStream && n.name === targetName) {
            return n
          }
        }
      }
      var hwSinks = []
      for (var i = 0; i < nodes.length; i++) {
        var n = nodes[i]
        if (n.isSink && !n.isStream && n.name !== "easyeffects_sink" &&
            n.properties && n.properties["device.api"]) {
          hwSinks.push(n)
        }
      }
      if (hwSinks.length === 1) {
        return hwSinks[0]
      }

      return null
    }
    return def
  }

  function _refreshEeTarget(): void {
    if (!_defaultSink || _defaultSink.name !== "easyeffects_sink") {
      svc._eeTargetName = ""
      return
    }

    var script = "pw-dump | python3 -c \"" +
      "import json,sys\n" +
      "d=json.load(sys.stdin)\n" +
      "nodes={}\n" +
      "for o in d:\n" +
      "    if str(o.get('type','')).endswith('Node'):\n" +
      "        props=(o.get('info') or {}).get('props') or {}\n" +
      "        nodes[o['id']]=props.get('node.name','')\n" +
      "ee_id=None\n" +
      "for nid,name in nodes.items():\n" +
      "    if name=='easyeffects_sink':\n" +
      "        ee_id=nid\n" +
      "        break\n" +
      "if ee_id is None:\n" +
      "    sys.exit(0)\n" +
      "for o in d:\n" +
      "    if not str(o.get('type','')).endswith('Link'):\n" +
      "        continue\n" +
      "    info=o.get('info') or {}\n" +
      "    if info.get('output-node-id')==ee_id:\n" +
      "        target_id=info.get('input-node-id')\n" +
      "        if target_id in nodes:\n" +
      "            print(nodes[target_id])\n" +
      "            break\n" +
      "\""

    ProcessPool.runTracked("Resolve EE target", script, {
      id: "ee-target-resolve",
      shell: true,
      callback: function(r) {
        svc._eeTargetName = (r.stdout || "").trim()
      }
    })
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
    if (sink?.ready && sink?.audio && sink.name !== "easyeffects_sink") {
      sink.audio.volume = Math.min(1.5, sink.audio.volume + 0.1)
    }
  }

  function volumeDown(): void {
    if (sink?.ready && sink?.audio && sink.name !== "easyeffects_sink") {
      sink.audio.volume = Math.max(0, sink.audio.volume - 0.1)
    }
  }

  function setVolume(v: real): void {
    if (sink?.ready && sink?.audio && sink.name !== "easyeffects_sink") {
      sink.audio.muted = false
      sink.audio.volume = Math.max(0, Math.min(1.5, v))
    }
  }

  function toggleMute(): void {
    if (sink?.ready && sink?.audio && sink.name !== "easyeffects_sink") {
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
    // NEVER apply volume to easyeffects_sink - it doesn't affect actual output
    if (node?.ready && node?.audio && node.name !== "easyeffects_sink") {
      node.audio.muted = false
      node.audio.volume = Math.max(0, Math.min(1.5, v))
    }
  }

  function toggleNodeMute(node: PwNode): void {
    // NEVER apply mute to easyeffects_sink - it doesn't affect actual output
    if (node?.ready && node?.audio && node.name !== "easyeffects_sink") {
      node.audio.muted = !node.audio.muted
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
