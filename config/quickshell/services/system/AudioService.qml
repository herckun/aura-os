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
  readonly property PwNode sink: Pipewire.defaultAudioSink
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

  // ═══════════════════════════════════════════════════════════════
  //  SYSTEM INTEGRATION
  // ═══════════════════════════════════════════════════════════════
  PwObjectTracker {
    objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource, Pipewire.nodes]
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
    for (var i = 0; i < Pipewire.nodes.count; i++) {
      var node = Pipewire.nodes.get(i)
      if (!node.ready || !node.audio) continue
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
        isDefault: isDefault
      })
    }
    return devices
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

  function snapshot() {
    return {
      sinkName: sinkName,
      sourceName: sourceName,
      sinkReady: sinkReady,
      sourceReady: sourceReady
    }
  }
}
