import QtQuick
import "../../../styles"
import "../../../core"
import "../../../services"
import "../../../components"

Column {
  id: root
  spacing: Theme.spaceLg
  width: parent.width

  Item {
    width: parent.width
    height: pageHeader.implicitHeight

    PageHeader {
      id: pageHeader
      title: "PLUGINS"
      width: parent.width
    }

    Button {
      id: restoreBtn
      property bool armed: false
      anchors.right: parent.right
      anchors.top: parent.top
      size: "sm"
      icon: "arrow-counter-clockwise"
      text: armed ? "CLICK TO CONFIRM" : "RESTORE DEFAULT LAYOUT"
      color: armed ? Theme.accent : Theme.textSecondary
      onClicked: {
        if (armed) {
          DefaultLayoutService.apply()
          armed = false
          disarmTimer.stop()
          root.selectedId = ""
          root.selectedLocation = ""
        } else {
          armed = true
          disarmTimer.restart()
        }
      }

      Timer {
        id: disarmTimer
        interval: 3000
        repeat: false
        onTriggered: restoreBtn.armed = false
      }
    }
  }

  // ── Areas ───────────────────────────────────────
  readonly property var areas: [
    { key: "bar", label: "Bar", icon: "workspaces", kind: "bar",
      locations: ["bar_left", "bar_center", "bar_right"] },
    { key: "controlcenter", label: "Control Center", icon: "controlcenter", kind: "zones", align: "right",
      locations: ["controlcenter_row"],
      zones: [
        { location: "controlcenter_row", label: "CARDS — TOP TO BOTTOM", vertical: true }
      ] },
    { key: "overview", label: "Overview", icon: "grid", kind: "zones",
      locations: ["overview"],
      zones: [{ location: "overview", label: "TABS — LEFT TO RIGHT", vertical: false }] },
    { key: "desktop", label: "Desktop", icon: "monitor", kind: "desktop",
      locations: ["desktop"] },
    { key: "dashboard", label: "Dashboard", icon: "cpu", kind: "zones",
      locations: ["dashboard"],
      zones: [{ location: "dashboard", label: "STATS — LEFT TO RIGHT", vertical: false }] },
    { key: "connectivity", label: "Connectivity", icon: "globe", kind: "zones",
      locations: ["connectivity"],
      zones: [{ location: "connectivity", label: "UTILITIES — TOP TO BOTTOM", vertical: true }] },
    { key: "audio", label: "Audio", icon: "speaker", kind: "zones",
      locations: ["audio"],
      zones: [{ location: "audio", label: "PROCESSING — TOP TO BOTTOM", vertical: true }] },
    { key: "search", label: "Search", icon: "magnifying-glass", kind: "search", locations: [] }
  ]

  property int areaIndex: 0
  readonly property var area: areas[areaIndex]
  property string selectedId: ""
  property string selectedLocation: ""

  readonly property var selectedPlugin: {
    if (selectedId === "") return null
    var _p = PluginService.plugins
    for (var i = 0; i < _p.length; i++)
      if (_p[i].id === selectedId) return _p[i]
    return null
  }

  // ── Model helpers ───────────────────────────────
  function enabledFor(location: string): var {
    var _p = PluginService.plugins
    var _e = Store.plugins.enabled
    var _o = Store.plugins.order
    if (!PluginService.loaded) return []
    var list = PluginService.getPluginsAssignedToSection(location)
    return list.filter(function(p) { return PluginService.isPluginEnabledForLocation(p.id, location) })
  }

  function availableFor(a: var): var {
    var _p = PluginService.plugins
    var _e = Store.plugins.enabled
    if (!PluginService.loaded) return []
    var out = []
    for (var i = 0; i < _p.length; i++) {
      var p = _p[i]
      var can = false
      var on = false
      for (var j = 0; j < a.locations.length; j++) {
        if (PluginService.canRenderAt(p, a.locations[j])) can = true
        if (PluginService.isPluginEnabledForLocation(p.id, a.locations[j])) on = true
      }
      if (can && !on) out.push(p)
    }
    return out
  }

  function activeCount(a: var): int {
    var n = 0
    for (var i = 0; i < a.locations.length; i++)
      n += enabledFor(a.locations[i]).length
    return n
  }

  function primaryLocation(a: var, plugin: var): string {
    for (var i = 0; i < a.locations.length; i++)
      if (PluginService.canRenderAt(plugin, a.locations[i])) return a.locations[i]
    return a.locations.length ? a.locations[0] : ""
  }

  function select(pluginId: string, location: string): void {
    if (selectedId === pluginId && selectedLocation === location) {
      selectedId = ""
      selectedLocation = ""
    } else {
      selectedId = pluginId
      selectedLocation = location
    }
  }

  // ── Drop handling ───────────────────────────────
  function groupOf(location: string): string {
    var i = location.indexOf("_")
    return i > 0 ? location.substring(0, i) : ""
  }

  function applyDrop(pluginId: string, fromLocation: string, toLocation: string, index: int): void {
    var ids = enabledFor(toLocation).map(function(p) { return p.id })
    var old = ids.indexOf(pluginId)
    if (old >= 0) {
      ids.splice(old, 1)
      if (old < index) index--
    }
    if (fromLocation !== toLocation) {
      var sameGroup = fromLocation !== "" && groupOf(fromLocation) !== "" && groupOf(fromLocation) === groupOf(toLocation)
      if (sameGroup) {
        PluginService.movePluginToLocation(pluginId, toLocation)
      } else {
        if (fromLocation !== "")
          PluginService.setPluginEnabledForLocation(pluginId, fromLocation, false)
        PluginService.setPluginEnabledForLocation(pluginId, toLocation, true)
      }
    }
    ids.splice(Math.max(0, Math.min(index, ids.length)), 0, pluginId)
    PluginService.setPluginOrder(toLocation, ids)
    select(pluginId, toLocation)
  }

  function enableFromTray(plugin: var): void {
    var loc = primaryLocation(area, plugin)
    if (loc === "") return
    PluginService.setPluginEnabledForLocation(plugin.id, loc, true)
    select(plugin.id, loc)
  }

  function disableFromDrag(pluginId: string, fromLocation: string): void {
    if (fromLocation === "") return
    PluginService.setPluginEnabledForLocation(pluginId, fromLocation, false)
    if (selectedId === pluginId) {
      selectedId = ""
      selectedLocation = ""
    }
  }

  // ── Area selector ───────────────────────────────
  TabStrip {
    width: parent.width
    model: root.areas.map(function(a) {
      return { icon: a.icon, label: a.label, count: a.kind === "search" ? -1 : root.activeCount(a) }
    })
    currentIndex: root.areaIndex
    onSelected: (index) => {
      root.areaIndex = index
      root.selectedId = ""
      root.selectedLocation = ""
    }
  }

  // ── Preview ─────────────────────────────────────
  readonly property var _kindHints: ({
    bar: "Your bar, live — drag widgets to reorder or move them between sections, click one to configure it",
    zones: "Drag to rearrange — changes apply instantly, click a widget to configure it",
    desktop: "Widgets sit at their on-screen positions — drag them around, click one to configure it",
    search: "Everything the launcher can search — toggle providers on or off"
  })

  Card {
    width: parent.width
    title: root.area.label.toUpperCase()
    description: root._kindHints[root.area.kind] || ""

    Loader {
      width: parent.width
      sourceComponent: {
        switch (root.area.kind) {
          case "bar": return barComp
          case "zones": return zonesComp
          case "desktop": return desktopComp
          case "search": return searchComp
          default: return null
        }
      }
    }

    PluginDetail {
      width: parent.width
      visible: root.selectedPlugin !== null && root.area.kind !== "search"
      plugin: root.selectedPlugin
      location: root.selectedLocation
      onClosed: {
        root.selectedId = ""
        root.selectedLocation = ""
      }
    }
  }

  Component {
    id: barComp
    BarPreview {
      dragLayer: chipDragLayer
      selectedId: root.selectedId
      modelFor: root.enabledFor
      onChipClicked: (pluginId, location) => root.select(pluginId, location)
      onDropRequested: (pluginId, fromLocation, toLocation, index) => root.applyDrop(pluginId, fromLocation, toLocation, index)
    }
  }

  Component {
    id: zonesComp
    ZonesPreview {
      dragLayer: chipDragLayer
      selectedId: root.selectedId
      modelFor: root.enabledFor
      zones: root.area.zones
      align: root.area.align || "center"
      onChipClicked: (pluginId, location) => root.select(pluginId, location)
      onDropRequested: (pluginId, fromLocation, toLocation, index) => root.applyDrop(pluginId, fromLocation, toLocation, index)
    }
  }

  Component {
    id: desktopComp
    DesktopPreview {
      dragLayer: chipDragLayer
      selectedId: root.selectedId
      model: root.enabledFor("desktop")
      onChipClicked: (pluginId, location) => root.select(pluginId, location)
      onPositionCommitted: (pluginId, fx, fy) => {
        Store.desktop.widgets = Store.mapPatch(Store.desktop.widgets, pluginId, { x: fx, y: fy })
        PluginService.setPluginSetting(pluginId, "autoPosition", false, "desktop")
      }
      onDropRequested: (pluginId, fromLocation, fx, fy) => {
        PluginService.setPluginEnabledForLocation(pluginId, "desktop", true)
        Store.desktop.widgets = Store.mapPatch(Store.desktop.widgets, pluginId, { x: fx, y: fy })
        PluginService.setPluginSetting(pluginId, "autoPosition", false, "desktop")
        root.select(pluginId, "desktop")
      }
    }
  }

  Component {
    id: searchComp
    SearchPreview {}
  }

  // ── Available tray ──────────────────────────────
  Card {
    width: parent.width
    title: "AVAILABLE"
    description: "Drag a widget into the preview or click it to enable — drop one here to disable it"
    visible: root.area.kind !== "search"

    Rectangle {
      width: parent.width
      height: Math.max(trayFlow.implicitHeight + Theme.spaceSm * 2, 46)
      radius: Theme.radiusSmall
      color: trayDrop.containsDrag ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.08) : Theme.controlBackground
      border.width: Theme.borderWidth
      border.color: trayDrop.containsDrag ? Theme.error : Theme.border

      Behavior on color { enabled: Theme.animationsEnabled; ColorAnimation { duration: Theme.animationFast } }
      Behavior on border.color { enabled: Theme.animationsEnabled; ColorAnimation { duration: Theme.animationFast } }

      Text {
        anchors.centerIn: parent
        text: trayDrop.containsDrag ? "DROP TO DISABLE" : "EVERYTHING IS PLACED"
        color: trayDrop.containsDrag ? Theme.error : Theme.textDisabled
        font.pixelSize: Theme.fontSizeMicro
        font.family: Theme.fontFamilyMono
        font.letterSpacing: 0.12
        visible: trayDrop.containsDrag || root.availableFor(root.area).length === 0
      }

      Flow {
        id: trayFlow
        anchors.fill: parent
        anchors.margins: Theme.spaceSm
        spacing: Theme.spaceXs

        Repeater {
          model: root.availableFor(root.area)

          delegate: PluginChip {
            required property var modelData
            pluginId: modelData.id
            fromLocation: ""
            label: modelData.manifest.name || modelData.id
            icon: modelData.manifest.icon || "cpu"
            dimmed: true
            dragLayer: chipDragLayer
            onClicked: root.enableFromTray(modelData)
          }
        }
      }

      DropArea {
        id: trayDrop
        anchors.fill: parent
        keys: ["plugin"]
        onDropped: (drop) => {
          var src = drop.source
          if (src && src.pluginId && src.fromLocation !== "")
            root.disableFromDrag(src.pluginId, src.fromLocation)
          drop.accept()
        }
      }
    }
  }

  Item {
    id: chipDragLayer
    width: parent.width
    height: 0
    z: 1000
  }
}
