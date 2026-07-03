import QtQuick
import Quickshell
import Quickshell.Wayland
import "./"

Item {
  // ── Top-right: Control Center ─────────────────────────────
  PanelWindow {
    visible: ModeService.showHotAreas && HotAreasService.enabledMap["controlcenter"] === true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:hotarea"
    anchors { top: true; right: true }
    implicitWidth: 8; implicitHeight: 8
    exclusiveZone: -1; focusable: false; color: "transparent"
    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onEntered: HotAreasService.triggerAction("controlcenter")
    }
  }

  // ── Top-left: Launcher ───────────────────────────────────
  PanelWindow {
    visible: ModeService.showHotAreas && HotAreasService.enabledMap["launcher"] === true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:hotarea"
    anchors { top: true; left: true }
    implicitWidth: 8; implicitHeight: 8
    exclusiveZone: -1; focusable: false; color: "transparent"
    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onEntered: HotAreasService.triggerAction("launcher")
    }
  }

  // ── Top-center: Overview ─────────────────────────────────
  PanelWindow {
    visible: ModeService.showHotAreas && HotAreasService.enabledMap["overview"] === true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:hotarea"
    anchors { top: true }
    implicitWidth: 8; implicitHeight: 8
    exclusiveZone: -1; focusable: false; color: "transparent"
    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onEntered: HotAreasService.triggerAction("overview")
    }
  }
}
