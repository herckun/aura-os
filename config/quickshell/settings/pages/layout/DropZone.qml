import QtQuick
import "../../../styles"

Item {
  id: zone

  property string location: ""
  property string zoneLabel: ""
  property bool vertical: false
  property bool bare: false
  property bool centered: false
  property var model: []
  property Item dragLayer: null
  property string selectedId: ""
  property int insertIndex: -1

  readonly property bool dragOver: dropArea.containsDrag
  readonly property bool empty: model.length === 0

  signal chipClicked(string pluginId)
  signal dropRequested(string pluginId, string fromLocation, int index)

  implicitHeight: Math.max(flow.implicitHeight + Theme.spaceSm * 2, 48)
  implicitWidth: flow.implicitWidth + Theme.spaceSm * 2

  property real _contentWidth: 0

  function _recomputeContentWidth(): void {
    var w = 0
    for (var i = 0; i < repeater.count; i++) {
      var it = repeater.itemAt(i)
      if (it) w += it.width + (w > 0 ? Theme.spaceXs : 0)
    }
    _contentWidth = w
  }

  Rectangle {
    anchors.fill: parent
    radius: Theme.radiusSmall
    color: zone.dragOver ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08) : zone.bare ? "transparent" : Theme.controlBackground
    border.width: Theme.borderWidth
    border.color: zone.dragOver ? Theme.accent : zone.bare ? "transparent" : Theme.border

    Behavior on color { enabled: Theme.animationsEnabled; ColorAnimation { duration: Theme.animationFast } }
    Behavior on border.color { enabled: Theme.animationsEnabled; ColorAnimation { duration: Theme.animationFast } }
  }

  Text {
    anchors.centerIn: parent
    text: zone.zoneLabel
    color: Theme.textDisabled
    font.pixelSize: Theme.fontSizeMicro
    font.family: Theme.fontFamilyMono
    font.letterSpacing: 0.12
    visible: zone.empty
    opacity: 0.7
  }

  Flow {
    id: flow
    anchors.verticalCenter: zone.vertical ? undefined : parent.verticalCenter
    anchors.top: zone.vertical ? parent.top : undefined
    anchors.topMargin: Theme.spaceSm
    anchors.horizontalCenter: zone.centered && !zone.vertical ? parent.horizontalCenter : undefined
    anchors.left: zone.centered && !zone.vertical ? undefined : parent.left
    anchors.leftMargin: Theme.spaceSm
    width: zone.vertical
      ? zone.width - Theme.spaceSm * 2
      : Math.min(zone.width - Theme.spaceSm * 2, Math.max(zone._contentWidth, 60))
    spacing: Theme.spaceXs

    move: Transition {
      enabled: Theme.animationsEnabled
      NumberAnimation { properties: "x,y"; duration: Theme.animationFast; easing.type: Easing.OutCubic }
    }

    Repeater {
      id: repeater
      model: zone.model

      delegate: PluginChip {
        required property var modelData
        pluginId: modelData.id
        fromLocation: zone.location
        label: modelData.manifest.name || modelData.id
        icon: modelData.manifest.icon || "cpu"
        fill: zone.vertical
        selected: modelData.id === zone.selectedId
        dragLayer: zone.dragLayer
        onClicked: zone.chipClicked(modelData.id)
        onWidthChanged: zone._recomputeContentWidth()
      }

      onItemAdded: zone._recomputeContentWidth()
      onItemRemoved: zone._recomputeContentWidth()
    }
  }

  readonly property var _indicatorPt: {
    var i = zone.insertIndex
    var pt = { x: flow.x, y: flow.y }
    if (i < 0) return pt
    var target = null
    var after = false
    if (i < repeater.count) target = repeater.itemAt(i)
    if (!target || target.width === 0) {
      target = null
      for (var j = Math.min(i, repeater.count) - 1; j >= 0; j--) {
        var prev = repeater.itemAt(j)
        if (prev && prev.width > 0) {
          target = prev
          after = true
          break
        }
      }
    }
    if (!target) return pt
    if (zone.vertical)
      return { x: flow.x, y: flow.y + (after ? target.y + target.height + 1 : target.y - 3) }
    return { x: flow.x + (after ? target.x + target.width + 1 : target.x - 3), y: flow.y + target.y }
  }

  Rectangle {
    visible: zone.dragOver && zone.insertIndex >= 0
    color: Theme.accent
    radius: 1
    width: zone.vertical ? flow.width : 2
    height: zone.vertical ? 2 : 30
    x: zone._indicatorPt.x
    y: zone._indicatorPt.y
  }

  function _indexAt(px: real, py: real): int {
    var idx = 0
    for (var i = 0; i < repeater.count; i++) {
      var it = repeater.itemAt(i)
      if (!it || it.width === 0 || it.height === 0) continue
      if (zone.vertical) {
        if (py > flow.y + it.y + it.height / 2) idx = i + 1
        continue
      }
      var top = flow.y + it.y
      var bottom = top + it.height
      if (py >= bottom) {
        idx = i + 1
        continue
      }
      if (py < top) break
      if (px > flow.x + it.x + it.width / 2) idx = i + 1
    }
    return idx
  }

  DropArea {
    id: dropArea
    anchors.fill: parent
    keys: ["plugin"]
    onEntered: (drag) => zone.insertIndex = zone._indexAt(drag.x, drag.y)
    onPositionChanged: (drag) => zone.insertIndex = zone._indexAt(drag.x, drag.y)
    onExited: zone.insertIndex = -1
    onDropped: (drop) => {
      var src = drop.source
      if (src && src.pluginId !== undefined && src.pluginId !== "")
        zone.dropRequested(src.pluginId, src.fromLocation, zone._indexAt(drop.x, drop.y))
      zone.insertIndex = -1
      drop.accept()
    }
  }
}
