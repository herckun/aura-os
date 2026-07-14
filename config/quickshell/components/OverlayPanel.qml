pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../styles"

PanelWindow {
    id: root

    // ── Public API ─────────────────────────────────────────────────
    property alias content: contentColumn.data
    property alias header: headerColumn.data
    property alias footer: footerColumn.data
    property alias overlayFooter: overlayFooterHost.data
    property alias contentScope: scope
    property alias fullContent: scope.data

    property real panelWidth: Math.min((screen ? screen.width : 1920) * 0.42, 560)
    property bool centered: true
    property real topRatio: 0.08
    property bool dim: true
    property bool framed: false
    property bool closeOnBackdrop: true
    property bool closeOnEscape: true

    signal panelOpened
    signal panelClosed

    function open(): void {
        root.visible = true;
    }
    function close(): void {
        root.visible = false;
    }
    function toggle(): void {
        root.visible = !root.visible;
    }

    // ── Window setup ───────────────────────────────────────────────
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    WlrLayershell.layer: WlrLayer.Overlay
    exclusiveZone: -1
    focusable: true
    color: "transparent"
    visible: false

    Connections {
        target: root
        function onVisibleChanged() {
            if (root.visible)
                root.panelOpened();
            else
                root.panelClosed();
        }
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.visible
        onCleared: root.visible = false
    }

    // ── Dim backdrop ───────────────────────────────────────────────
    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: root.dim ? Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.72) : "transparent"
        opacity: root.visible ? 1 : 0

        Behavior on opacity {
            enabled: Theme.animationsEnabled
            NumberAnimation {
                duration: Theme.animationFast
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.closeOnBackdrop
            onClicked: function (mouse) {
                var p = card.mapFromItem(backdrop, mouse.x, mouse.y);
                if (p.x < 0 || p.x > card.width || p.y < 0 || p.y > card.height)
                    root.visible = false;
            }
        }
    }

    // ── Centered, animated content ─────────────────────────────────
    FocusScope {
        id: scope
        anchors.fill: parent
        focus: root.visible

        Keys.onEscapePressed: function (event) {
            if (root.closeOnEscape) {
                root.visible = false;
                event.accepted = true;
            }
        }

        Item {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: root.centered ? parent.verticalCenter : undefined
            anchors.top: root.centered ? undefined : parent.top
            anchors.topMargin: root.centered ? 0 : Math.min(parent.height * root.topRatio, 80)
            width: root.panelWidth
            implicitHeight: outerColumn.y + outerColumn.height + (root.framed ? Theme.spaceLg : 0)
            height: implicitHeight

            opacity: root.visible ? 1 : 0
            scale: root.visible ? 1 : 0.96
            Behavior on opacity {
                enabled: Theme.animationsEnabled
                NumberAnimation {
                    duration: Theme.animationNormal
                    easing.type: Easing.OutQuad
                }
            }
            Behavior on scale {
                enabled: Theme.animationsEnabled
                NumberAnimation {
                    duration: Theme.animationNormal
                    easing.type: Easing.OutQuad
                }
            }

            Surface {
                anchors.fill: parent
                visible: root.framed
                radius: Theme.radiusLarge
                antialiasing: true
                color: Theme.panelBackgroundSecondary
                border.color: Theme.border
            }

            Column {
                id: outerColumn
                x: root.framed ? Theme.spaceLg : 0
                y: root.framed ? Theme.spaceLg : 0
                width: root.framed ? parent.width - Theme.spaceLg * 2 : parent.width
                spacing: Theme.spaceMd

                Column {
                    id: headerColumn
                    width: parent.width
                    spacing: Theme.spaceMd
                }
                Column {
                    id: contentColumn
                    width: parent.width
                    spacing: Theme.spaceMd
                }
                Column {
                    id: footerColumn
                    width: parent.width
                    spacing: Theme.spaceMd
                }
            }
        }

        Item {
            id: overlayFooterHost
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.spaceXl
            width: childrenRect.width
            height: childrenRect.height
            opacity: root.visible ? 1 : 0
            Behavior on opacity {
                enabled: Theme.animationsEnabled
                NumberAnimation {
                    duration: Theme.animationNormal
                }
            }
        }
    }
}
