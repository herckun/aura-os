import QtQuick
import Quickshell
import "../../../styles"
import "../../../core"
import "../../../services"
import "../../../components"

Column {
  id: root

  property Item dragLayer: null
  property string selectedId: ""
  property var model: []

  signal chipClicked(string pluginId, string location)
  signal positionCommitted(string pluginId, real fx, real fy)
  signal dropRequested(string pluginId, string fromLocation, real fx, real fy)

  readonly property real screenRatio: Quickshell.screens.length > 0
    ? Quickshell.screens[0].height / Quickshell.screens[0].width : 0.5625

  spacing: Theme.spaceXs

  Rectangle {
    id: canvas
    width: parent.width
    height: width * root.screenRatio
    radius: Theme.radiusMedium
    color: Theme.background
    border.width: Theme.borderWidth
    border.color: canvasDrop.containsDrag ? Theme.accent : Theme.borderVisible
    clip: true

    Image {
      anchors.fill: parent
      source: WallpaperService.sourceWallpaperPath.length > 0 ? "file://" + WallpaperService.sourceWallpaperPath : ""
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      opacity: 0.4
    }

    Rectangle {
      width: parent.width
      height: Math.max(4, parent.height * 0.045)
      color: Qt.rgba(0, 0, 0, 0.55)
      border.width: 0
    }

    Repeater {
      id: widgetRepeater
      model: root.model

      delegate: Rectangle {
        id: w
        required property var modelData
        readonly property string pluginId: modelData.id
        readonly property bool dragging: wma.drag.active

        width: wRow.implicitWidth + Theme.spaceSm * 2
        height: 26
        radius: Theme.radiusSmall
        color: root.selectedId === pluginId ? Theme.accent
             : wma.containsMouse ? Theme.controlBackgroundHover : Qt.rgba(0, 0, 0, 0.75)
        border.width: Theme.borderWidth
        border.color: dragging || root.selectedId === pluginId ? Theme.accent : Theme.borderVisible

        function reposition(): void {
          if (dragging) return
          var geom = Store.desktop.widgets[pluginId] || {}
          x = Math.max(0, Math.min(canvas.width - width, (geom.x ?? 0.05) * canvas.width))
          y = Math.max(0, Math.min(canvas.height - height, (geom.y ?? 0.1) * canvas.height))
        }

        Component.onCompleted: reposition()
        onWidthChanged: reposition()

        Connections {
          target: Store.desktop
          function onWidgetsChanged() { w.reposition() }
        }

        Connections {
          target: canvas
          function onWidthChanged() { w.reposition() }
          function onHeightChanged() { w.reposition() }
        }

        Row {
          id: wRow
          anchors.centerIn: parent
          spacing: Theme.spaceXs

          Icon {
            anchors.verticalCenter: parent.verticalCenter
            source: Icons.get(w.modelData.manifest.icon || "cpu")
            size: 12
            color: root.selectedId === w.pluginId ? Theme.contrastTextColor(Theme.accent) : Theme.textPrimary
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: (w.modelData.manifest.name || w.pluginId).toUpperCase()
            color: root.selectedId === w.pluginId ? Theme.contrastTextColor(Theme.accent) : Theme.textPrimary
            font.pixelSize: Theme.fontSizeMicro
            font.family: Theme.fontFamilyMono
            font.weight: Font.Bold
            font.letterSpacing: 0.06
          }
        }

        MouseArea {
          id: wma
          anchors.fill: parent
          hoverEnabled: true
          preventStealing: true
          cursorShape: dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
          drag.target: w
          drag.threshold: 4
          drag.minimumX: 0
          drag.maximumX: canvas.width - w.width
          drag.minimumY: 0
          drag.maximumY: canvas.height - w.height
          onClicked: root.chipClicked(w.pluginId, "desktop")
          onReleased: {
            if (!drag.active) return
            root.positionCommitted(w.pluginId, w.x / canvas.width, w.y / canvas.height)
          }
        }
      }
    }

    DropArea {
      id: canvasDrop
      anchors.fill: parent
      keys: ["plugin"]
      onDropped: (drop) => {
        var src = drop.source
        if (src && src.pluginId)
          root.dropRequested(src.pluginId, src.fromLocation, drop.x / canvas.width, drop.y / canvas.height)
        drop.accept()
      }
    }
  }
}
