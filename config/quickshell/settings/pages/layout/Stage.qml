import QtQuick
import "../../../styles"
import "../../../services"

Item {
  id: root

  default property alias content: inner.data
  property real minHeight: 0

  implicitHeight: Math.max(inner.implicitHeight + Theme.spaceMd * 2, minHeight)

  Rectangle {
    anchors.fill: parent
    radius: Theme.radiusMedium
    antialiasing: true
    color: Theme.background
    border.width: Theme.borderWidth
    border.color: Theme.borderVisible
    clip: true

    Image {
      anchors.fill: parent
      source: WallpaperService.sourceWallpaperPath.length > 0 ? "file://" + WallpaperService.sourceWallpaperPath : ""
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      opacity: 0.3
    }

    Rectangle {
      anchors.fill: parent
      gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.25) }
        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.6) }
      }
    }
  }

  Item {
    id: inner
    anchors.fill: parent
    anchors.margins: Theme.spaceMd
    implicitHeight: childrenRect.height
  }
}
