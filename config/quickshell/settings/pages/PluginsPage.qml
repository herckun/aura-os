import QtQuick
import QtQuick.Layouts
import "../../styles"
import "../../core"
import "../../services"
import "../../components"

Column {
  id: root
  spacing: Theme.spaceLg
  width: parent.width

  property string searchQuery: ""
  onVisibleChanged: if (visible) searchInput.forceActiveFocus()

  PageHeader { title: "PLUGINS" }

  // ── Search ──────────────────────────────────────
  Rectangle {
    width: parent.width
    height: 36
    radius: Theme.radiusMedium
    color: Theme.backgroundSecondary
    border.width: Theme.borderWidth
    border.color: searchInput.activeFocus ? Theme.accent : Theme.border

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: Theme.spaceSm
      anchors.rightMargin: Theme.spaceSm
      spacing: Theme.spaceXs

      Icon {
        source: Icons.get("magnifying-glass")
        size: 14
        color: searchInput.activeFocus ? Theme.accent : Theme.textDisabled
      }

      TextInput {
        id: searchInput
        Layout.fillWidth: true
        color: Theme.textDisplay
        font.pixelSize: Theme.fontSizeCaption
        font.family: Theme.fontFamilyMono
        clip: true
        selectByMouse: true
        selectionColor: Theme.accent

        Text {
          text: "Search plugins..."
          color: Theme.textDisabled
          font: searchInput.font
          visible: !searchInput.text && !searchInput.activeFocus
        }

        onTextChanged: root.searchQuery = text

        Keys.onEscapePressed: {
          text = ""
          focus = false
        }
      }

      Rectangle {
        width: 18; height: 18
        radius: Theme.radiusSmall
        color: Theme.controlBackground
        visible: searchInput.text.length > 0

        Icon {
          anchors.centerIn: parent
          source: Icons.get("x")
          size: 10
          color: Theme.textSecondary
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: searchInput.text = ""
        }
      }
    }
  }

  // ── Areas ───────────────────────────────────────
  property var _areas: [
    { location: "controlcenter_row",    label: "Control Center", desc: "Control center cards and settings", icon: "gear" },
    { location: "controlcenter_toggle", label: "Quick Toggles",  desc: "Control center toggle buttons",      icon: "bolt" },
    { location: "bar_left",             label: "Bar — Left",     desc: "Left bar section",                    icon: "workspaces" },
    { location: "bar_center",           label: "Bar — Center",   desc: "Center bar section",                  icon: "workspaces" },
    { location: "bar_right",            label: "Bar — Right",    desc: "Right bar section",                   icon: "workspaces" },
    { location: "overview",             label: "Overview",       desc: "Desktop overview widgets",            icon: "grid" },
    { location: "desktop",              label: "Desktop",        desc: "Desktop widgets and overlays",        icon: "monitor" },
    { location: "connectivity",         label: "Connectivity",   desc: "VPN and network utilities",           icon: "globe" },
    { location: "audio",                label: "Audio",          desc: "Audio effects and processing",        icon: "speaker" },
    { location: "dashboard",            label: "Dashboard",      desc: "Dashboard hardware stats",            icon: "cpu" }
  ]

  property string activeLocation: "controlcenter_row"

  function _areaForLocation(loc) {
    for (var i = 0; i < _areas.length; i++) if (_areas[i].location === loc) return _areas[i]
    return _areas[0]
  }

  function _activeCount(loc) {
    if (!PluginService.loaded) return 0
    var list = PluginService.getPluginsAssignedToSection(loc)
    var n = 0
    for (var i = 0; i < list.length; i++)
      if (PluginService.isPluginEnabledForLocation(list[i].id, loc)) n++
    return n
  }

  // ── Area selector (hidden while searching) ──────
  Flow {
    width: parent.width
    spacing: Theme.spaceXs
    visible: root.searchQuery === ""

    Repeater {
      model: root._areas

      delegate: Chip {
        id: chip
        required property var modelData
        icon: modelData.icon
        label: modelData.label
        count: root._activeCount(modelData.location)
        selected: modelData.location === root.activeLocation
        onClicked: root.activeLocation = chip.modelData.location
      }
    }
  }

  // ── Active area detail ──────────────────────────
  PluginLocationCard {
    visible: root.searchQuery === ""
    width: parent.width
    location: root.activeLocation
    label: root._areaForLocation(root.activeLocation).label
    description: root._areaForLocation(root.activeLocation).desc
    icon: root._areaForLocation(root.activeLocation).icon
    plugins: PluginService.loaded
      && PluginService.plugins.length >= 0
      ? PluginService.getPluginsAssignedToSection(root.activeLocation) : []
  }

  // ── Search results (all areas, flat) ────────────
  Repeater {
    model: root.searchQuery !== "" ? root._areas : []

    delegate: PluginLocationCard {
      required property var modelData
      width: root.width
      location: modelData.location
      label: modelData.label
      description: modelData.desc
      icon: modelData.icon
      searchQuery: root.searchQuery
      plugins: PluginService.loaded
        && PluginService.plugins.length >= 0
        ? PluginService.getPluginsAssignedToSection(modelData.location) : []
    }
  }
}
