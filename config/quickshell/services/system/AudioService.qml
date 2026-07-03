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

  property string _eeTargetName: ""

  on_DefaultSinkChanged: _refreshEeTarget()

  function _resolveSink(def: PwNode, targetName: string, nodes: var): PwNode {
    if (def && def.name === "easyeffects_sink" && targetName) {
      for (var i = 0; i < nodes.length; i++) {
        var n = nodes[i]
        if (n.isSink && !n.isStream && n.name === targetName) return n
      }
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
      "props={}\n" +
      "for o in d:\n" +
      "    if str(o.get('type','')).endswith('Node'): props[o['id']]=(o.get('info') or {}).get('props') or {}\n" +
      "ee={i for i,p in props.items() if p.get('application.id')=='com.github.wwmm.easyeffects' or str(p.get('node.name','')).startswith('ee_')}\n" +
      "sinks={i for i,p in props.items() if p.get('media.class')=='Audio/Sink' and p.get('node.name')!='easyeffects_sink'}\n" +
      "for o in d:\n" +
      "    if not str(o.get('type','')).endswith('Link'): continue\n" +
      "    info=o.get('info') or {}\n" +
      "    if info.get('output-node-id') in ee and info.get('input-node-id') in sinks:\n" +
      "        print(props[info.get('input-node-id')].get('node.name','')); break\n" +
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

  function _getStreams(sinkSide: bool): var {
    if (!Pipewire.ready) return []
    var streams = []
    var nodes = Pipewire.nodes.values
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i]
      if (!node.ready || !node.audio || !node.isStream) continue
      if (node.isSink !== sinkSide) continue
      if (!sinkSide && node.properties && node.properties["stream.monitor"] === "true") continue
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
    if (node?.ready && node?.audio) {
      node.audio.muted = false
      node.audio.volume = Math.max(0, Math.min(1.5, v))
    }
  }

  function toggleNodeMute(node: PwNode): void {
    if (node?.ready && node?.audio) {
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
