import QtQuick
import QtQuick.Layouts
import "../../styles"
import "../../core"
import "../../services"
import "../../components"

Column {
  id: root

  property string location: ""
  property string label: ""
  property string description: ""
  property string icon: "grid"
  property var plugins: []
  property string searchQuery: ""

  width: parent ? parent.width : 0
  spacing: Theme.spaceSm
  visible: _filteredPlugins.length > 0 || _locationMatches

  readonly property bool _locationMatches: root.searchQuery === ""
    || root.label.toLowerCase().indexOf(root.searchQuery.toLowerCase()) >= 0
    || root.description.toLowerCase().indexOf(root.searchQuery.toLowerCase()) >= 0

  readonly property var _filteredPlugins: {
    if (root.searchQuery === "") return root.plugins
    var q = root.searchQuery.toLowerCase()
    return root.plugins.filter(function(p) {
      return (p.name && p.name.toLowerCase().indexOf(q) >= 0)
        || (p.description && p.description.toLowerCase().indexOf(q) >= 0)
        || (p.id && p.id.toLowerCase().indexOf(q) >= 0)
    })
  }

  readonly property var _enabled: PluginService.loaded
    && PluginService.plugins.length >= 0

  // ── Header ────────────────────────────────────────────
  RowLayout {
    width: parent.width
    spacing: Theme.spaceSm

    Rectangle {
      Layout.preferredWidth: 28
      Layout.preferredHeight: 28
      radius: Theme.radiusSmall
      color: Theme.backgroundTertiary

      Icon {
        anchors.centerIn: parent
        source: Icons.get(root.icon)
        size: 14
        color: Theme.accent
      }
    }

    Column {
      Layout.fillWidth: true
      spacing: Theme.spaceXxs

      Text {
        text: root.label.toUpperCase()
        color: Theme.textDisplay
        font.pixelSize: Theme.fontSizeLabel
        font.family: Theme.fontFamilyMono
        font.weight: Font.Bold
        font.letterSpacing: 0.1
      }

      Text {
        text: root.description
        color: Theme.textDisabled
        font.pixelSize: Theme.fontSizeMicro
        font.family: Theme.fontFamilyMono
        visible: text !== ""
      }
    }

    Text {
      text: root._enabled ? root._filteredPlugins.length + " ACTIVE" : ""
      color: Theme.textSecondary
      font.pixelSize: Theme.fontSizeMicro
      font.family: Theme.fontFamilyMono
      font.letterSpacing: 0.08
      visible: root._enabled && root._filteredPlugins.length > 0
    }
  }

  // ── Plugin list ───────────────────────────────────────
  Repeater {
    model: root._enabled ? root._filteredPlugins : []

    delegate: PluginRow {
      id: pluginRow
      width: root.width
      plugin: modelData
      location: root.location
      enabled: PluginService.isPluginEnabledForLocation(modelData.id, root.location)
          pluginIndex: index
      count: root._filteredPlugins.length

      onToggleEnabled: PluginService.setPluginEnabledForLocation(modelData.id, root.location, !enabled)
      onToggleExpanded: pluginRow.expanded = !pluginRow.expanded
      onMoveUp: {
        var ids = root.plugins.map(function(p) { return p.id })
        var item = ids.splice(index, 1)[0]
        ids.splice(index - 1, 0, item)
        PluginService.setPluginOrder(root.location, ids)
      }
      onMoveDown: {
        var ids = root.plugins.map(function(p) { return p.id })
        var item = ids.splice(index, 1)[0]
        ids.splice(index + 1, 0, item)
        PluginService.setPluginOrder(root.location, ids)
      }
    }
  }

  // ── Empty state ───────────────────────────────────────
  Surface {
    width: parent.width
    height: emptyLabel.implicitHeight + Theme.spaceMd * 2
    radius: Theme.radiusMedium
    visible: root._enabled && root._filteredPlugins.length === 0

    Text {
      id: emptyLabel
      anchors.centerIn: parent
      text: "NO PLUGINS"
      color: Theme.textDisabled
      font.pixelSize: Theme.fontSizeCaption
      font.family: Theme.fontFamilyMono
      font.letterSpacing: 0.1
    }
  }
}
