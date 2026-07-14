import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../styles"
import "../services"

PanelWindow {
    id: pc

    default property alias content: contentCol.data
    property alias contentWrap: contentCol
    property bool scrollLock: false

    property real paddingX: 20
    property real paddingY: 10
    property real outerMargin: 6
    property real maxHeightRatio: 0.85
    property alias bg: bg

    anchors {
        top: true
        right: true
    }
    margins.top: PopupPositioner.belowBar() - outerMargin
    margins.right: AppearanceService.barFloating ? BarService.sideOffset : Theme.spaceXs

    exclusiveZone: 0
    color: "transparent"
    visible: false

    mask: Region {
        item: bg
    }

    implicitHeight: Math.min(contentCol.implicitHeight + paddingY * 2 + outerMargin * 2, (screen?.height ?? 700) * maxHeightRatio)

    function toggle(): void {
        pc.visible = !pc.visible;
    }

    HyprlandFocusGrab {
        windows: [pc]
        active: pc.visible
        onCleared: pc.visible = false
    }

    Timer {
        id: leaveTimer
        interval: 1500
        onTriggered: pc.visible = false
    }

    HoverHandler {
        onHoveredChanged: {
            if (hovered)
                leaveTimer.stop();
            else if (pc.visible)
                leaveTimer.restart();
        }
    }

    Surface {
        id: bg
        anchors.fill: parent
        anchors.margins: pc.outerMargin
        radius: Theme.radiusLarge
        antialiasing: true
        color: Theme.panelBackgroundSecondary
        border.color: Theme.border
    }

    Flickable {
        anchors.fill: parent
        anchors.leftMargin: pc.paddingX
        anchors.rightMargin: pc.paddingX
        anchors.topMargin: pc.paddingY
        anchors.bottomMargin: pc.paddingY
        contentHeight: contentCol.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        flickableDirection: Flickable.VerticalFlick
        interactive: !pc.scrollLock && contentHeight > height

        Column {
            id: contentCol
            width: parent.width
            spacing: Theme.spaceMd
        }
    }
}
