pragma Singleton
import QtQuick
import Quickshell
import "../../core"
import "../"

Singleton {
  id: svc

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC STATE
  // ═══════════════════════════════════════════════════════════════
  readonly property var catalog: {
    var state = svc._state
    var out = []
    for (var i = 0; i < svc._providers.length; i++) {
      var p = svc._providers[i]
      var s = state[p.id] || {}
      out.push({
        id: p.id,
        label: p.label || p.id,
        icon: p.icon || "shield",
        builtin: p.id === "networkmanager",
        available: !!s.available,
        connected: !!s.connected,
        connecting: !!s.connecting,
        detail: s.detail || ""
      })
    }
    return out
  }

  readonly property var providers: catalog.filter(function(p) { return p.available })

  readonly property var activeProvider: {
    var list = svc.providers
    if (list.length === 0) return null
    for (var i = 0; i < list.length; i++) if (list[i].connected && !list[i].builtin) return list[i]
    for (var j = 0; j < list.length; j++) if (list[j].connected) return list[j]
    for (var k = 0; k < list.length; k++) if (list[k].id === Store.vpn.provider) return list[k]
    return list[0]
  }

  readonly property bool available: providers.length > 0
  readonly property bool connected: activeProvider !== null && activeProvider.connected
  readonly property bool connecting: activeProvider !== null && activeProvider.connecting
  readonly property string label: activeProvider ? activeProvider.label : "VPN"
  readonly property string detail: activeProvider ? activeProvider.detail : ""
  property string nmBusyName: ""

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════
  function registerProvider(provider): void {
    if (!provider || !provider.id) return
    var next = svc._providers.slice()
    var replaced = false
    for (var i = 0; i < next.length; i++) {
      if (next[i].id === provider.id) {
        next[i] = provider
        replaced = true
        break
      }
    }
    if (!replaced) next.push(provider)
    svc._providers = next
  }

  function unregisterProvider(providerId: string): void {
    svc._providers = svc._providers.filter(function(p) { return p.id !== providerId })
  }

  function submit(providerId: string, state: var): void {
    var prev = svc._state[providerId] || {}
    svc._state = Store.mapSet(svc._state, providerId, state || {})
    if (!state || !!state.connected === !!prev.connected) return
    if (providerId === "networkmanager") {
      if (!state.connected) return
      var list = svc.providers
      for (var i = 0; i < list.length; i++)
        if (list[i].connected && !list[i].builtin) return
      Store.vpn.provider = providerId
      return
    }
    NetworkService.poll()
    if (state.connected) Store.vpn.provider = providerId
  }

  function select(providerId: string): void {
    Store.vpn.provider = providerId
  }

  function connectProvider(providerId: string): void {
    var p = svc._find(providerId)
    if (!p || !p.connect) return
    var list = svc.providers
    var ownedElsewhere = false
    for (var i = 0; i < list.length; i++)
      if (list[i].connected && !list[i].builtin && list[i].id !== providerId) ownedElsewhere = true
    for (var j = 0; j < list.length; j++) {
      if (list[j].id === providerId || !list[j].connected) continue
      if (list[j].builtin && ownedElsewhere) continue
      var other = svc._find(list[j].id)
      if (other && other.disconnect) other.disconnect()
    }
    Store.vpn.provider = providerId
    p.connect()
  }

  function disconnectProvider(providerId: string): void {
    var p = svc._find(providerId)
    if (p && p.disconnect) p.disconnect()
  }

  function toggle(): void {
    var a = svc.activeProvider
    if (!a || a.connecting) return
    if (!a.connected) {
      svc.connectProvider(a.id)
      return
    }
    var list = svc.providers
    var owned = false
    for (var i = 0; i < list.length; i++) {
      if (!list[i].connected || list[i].builtin) continue
      svc.disconnectProvider(list[i].id)
      owned = true
    }
    if (!owned) svc.disconnectProvider(a.id)
  }

  // ═══════════════════════════════════════════════════════════════
  //  INTERNAL STATE
  // ═══════════════════════════════════════════════════════════════
  property var _providers: []
  property var _state: ({})

  readonly property var _nmProvider: ({
    id: "networkmanager",
    label: "VPN",
    icon: "shield",
    connect: function() { svc._nmUp() },
    disconnect: function() { svc._nmDown() }
  })

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════
  function _find(providerId: string): var {
    for (var i = 0; i < svc._providers.length; i++)
      if (svc._providers[i].id === providerId) return svc._providers[i]
    return null
  }

  function _nmActive(): var {
    var list = NetworkService.vpnConnections
    for (var i = 0; i < list.length; i++) if (list[i].active) return list[i]
    return null
  }

  function _syncNm(): void {
    var list = NetworkService.vpnConnections
    var act = svc._nmActive()
    svc.submit("networkmanager", {
      available: list.length > 0,
      connected: act !== null,
      connecting: svc.nmBusyName !== "",
      detail: act ? act.name : ""
    })
  }

  function nmConnect(name: string): void {
    if (svc.nmBusyName !== "" || name === "") return
    svc.nmBusyName = name
    svc._syncNm()
    ProcessPool.runQueued("VPN connect", ["nmcli", "connection", "up", name], {
      id: "vpn-toggle",
      silent: true,
      callback: function(r) {
        svc.nmBusyName = ""
        if (r.exitCode !== 0) {
          NotificationService.systemNotify("VPN", name + ": connect failed", 2)
        } else {
          Store.vpn.nmConnection = name
          NotificationService.systemNotify("VPN", name + " connected", 1)
        }
        NetworkService.poll()
        svc._syncNm()
      }
    })
  }

  function nmDisconnect(name: string): void {
    if (svc.nmBusyName !== "" || name === "") return
    svc.nmBusyName = name
    svc._syncNm()
    ProcessPool.runQueued("VPN disconnect", ["nmcli", "connection", "down", name], {
      id: "vpn-toggle",
      silent: true,
      callback: function(r) {
        svc.nmBusyName = ""
        if (r.exitCode !== 0) NotificationService.systemNotify("VPN", name + ": disconnect failed", 2)
        else NotificationService.systemNotify("VPN", name + " disconnected", 1)
        NetworkService.poll()
        svc._syncNm()
      }
    })
  }

  function _nmUp(): void {
    var list = NetworkService.vpnConnections
    if (list.length === 0) return
    var name = list[0].name
    for (var i = 0; i < list.length; i++)
      if (list[i].name === Store.vpn.nmConnection) name = list[i].name
    svc.nmConnect(name)
  }

  function _nmDown(): void {
    var act = svc._nmActive()
    if (act) svc.nmDisconnect(act.name)
  }

  function _syncPluginProviders(): void {
    var plugins = PluginService.plugins || []
    for (var i = 0; i < plugins.length; i++) {
      var p = plugins[i]
      if (p && p.vpnProvider && p.vpnProvider.id)
        svc.registerProvider(p.vpnProvider)
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  SIGNAL CONNECTIONS
  // ═══════════════════════════════════════════════════════════════
  Connections {
    target: NetworkService
    function onVpnConnectionsChanged() { svc._syncNm() }
  }

  Connections {
    target: PluginService
    function onPluginsUpdated() { svc._syncPluginProviders() }
  }

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════
  Component.onCompleted: {
    svc.registerProvider(svc._nmProvider)
    svc._syncNm()
    svc._syncPluginProviders()
  }
}
