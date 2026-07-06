import QtQuick
import QtQuick.Layouts
import "../styles"
import "../services"
import "../components"

Item {
  id: root

  property string location: ""
  property string layout: "column"
  property int columns: 3
  property bool sectioned: false
  property string onlyPluginId: ""
  property Component delegate: null

  property var activeItem: null

  readonly property var plugins: PluginService.loaded
    ? PluginService.getPluginsForLocation(root.location).filter(function(p) {
        if (root.onlyPluginId !== "" && p.id !== root.onlyPluginId) return false
        if (!PluginService.isPluginEnabledForLocation(p.id, root.location)) return false
        return root.delegate !== null || root._resolveComponent(p) !== null
      }) : []

  function _resolveComponent(pluginInstance) {
    if (!pluginInstance) return null
    var prop = PluginService.componentMap[root.location]
    if (!prop) return null
    return pluginInstance[prop] || null
  }

  implicitWidth: _holder.item ? _holder.item.implicitWidth : 0
  implicitHeight: _holder.item ? _holder.item.implicitHeight : 0
  width: (root.layout === "column" || root.layout === "grid")
    ? (parent ? parent.width : implicitWidth) : implicitWidth
  height: implicitHeight

  Component {
    id: _defaultDelegate
    Loader {
      required property var modelData
      property var pluginInstance: modelData
      width: root.layout === "column" ? root.width : implicitWidth
      sourceComponent: root.sectioned ? _sectionWrap : root._resolveComponent(modelData)
      onLoaded: if (root.onlyPluginId !== "") root.activeItem = item
      Component.onDestruction: if (root.activeItem === item) root.activeItem = null
      Component {
        id: _sectionWrap
        Section {
          Loader {
            width: parent.width
            sourceComponent: root._resolveComponent(modelData)
          }
        }
      }
    }
  }

  Component {
    id: _rowDelegate
    Loader {
      required property var modelData
      property var pluginInstance: modelData
      Layout.alignment: Qt.AlignVCenter
      Layout.fillHeight: false
      width: implicitWidth
      sourceComponent: root.sectioned ? _rowSectionWrap : root._resolveComponent(modelData)
      onLoaded: if (root.onlyPluginId !== "") root.activeItem = item
      Component.onDestruction: if (root.activeItem === item) root.activeItem = null
      Component {
        id: _rowSectionWrap
        Section {
          Loader {
            width: parent.width
            sourceComponent: root._resolveComponent(modelData)
          }
        }
      }
    }
  }

  Loader {
    id: _holder
    anchors.fill: root.layout === "free" ? parent : undefined
    sourceComponent: root.layout === "row" ? _rowLayout
                   : root.layout === "grid" ? _gridLayout
                   : root.layout === "free" ? _freeLayout
                   : _colLayout
  }

  Component {
    id: _colLayout
    Column {
      spacing: Theme.spaceSm
      Repeater { model: root.plugins; delegate: root.delegate || _defaultDelegate }
    }
  }

  Component {
    id: _rowLayout
    RowLayout {
      spacing: Theme.spaceSm
      Repeater { model: root.plugins; delegate: root.delegate || _rowDelegate }
    }
  }

  Component {
    id: _gridLayout
    GridLayout {
      width: root.width
      columns: root.columns
      columnSpacing: Theme.spaceSm
      rowSpacing: Theme.spaceSm
      Repeater { model: root.plugins; delegate: root.delegate || _defaultDelegate }
    }
  }

  Component {
    id: _freeLayout
    Item {
      anchors.fill: parent
      Repeater { model: root.plugins; delegate: root.delegate || _defaultDelegate }
    }
  }
}
