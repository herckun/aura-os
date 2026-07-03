import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import "../../styles"
import "../../core"
import "../../services"
import "../../components"

PanelWindow {
    id: desktopLayer

    required property var modelData
    screen: modelData

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "quickshell:desktop"

    implicitWidth: screen?.width ?? 1920
    implicitHeight: screen?.height ?? 1080

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    exclusiveZone: -1
    focusable: false
    color: "transparent"
    visible: true

    PluginHost {
        anchors.fill: parent
        location: "desktop"
        layout: "free"

        delegate: DesktopWidget {
            required property var modelData
            plugin: modelData
            screenWidth: desktopLayer.width
            screenHeight: desktopLayer.height
        }
    }
}
