import QtQuick
import Qt5Compat.GraphicalEffects
import "../../../styles"
import "../../../services"

Item {
    id: root

    default property alias content: inner.data
    property real minHeight: 0

    implicitHeight: Math.max(inner.implicitHeight + Theme.spaceMd * 2, minHeight)

    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: Theme.radiusMedium
        antialiasing: true
        color: Theme.background
        border.width: Theme.borderWidth
        border.color: Theme.borderVisible

        Image {
            id: bgImage
            anchors.fill: parent
            source: WallpaperService.sourceWallpaperPath.length > 0 ? "file://" + WallpaperService.sourceWallpaperPath : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
            smooth: true
        }

        Rectangle {
            id: imageMask
            anchors.fill: parent
            radius: Theme.radiusMedium
            antialiasing: true
            color: "white"
            visible: false
        }

        OpacityMask {
            anchors.fill: parent
            source: bgImage
            maskSource: imageMask
            opacity: 0.3
            visible: WallpaperService.sourceWallpaperPath.length > 0 && bgImage.status === Image.Ready
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusMedium
            antialiasing: true
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(0, 0, 0, 0.25)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(0, 0, 0, 0.6)
                }
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
