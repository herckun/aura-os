import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../styles"
import "../../services"
import "../../components"

PanelWindow {
  id: toast

  anchors { top: true; left: true }
  exclusiveZone: 0
  color: "transparent"
  visible: false

  property real stackOffset: 0
  readonly property real stackHeight: visible ? _toastHeight + 4 : 0
  property string summary: ""
  property string body: ""
  property string appIcon: ""
  property string appName: ""
  property int urgency: 1
  property var notifActions: []
  property string timestamp: ""
  property bool shown: false

  property double duration: Theme.toastDuration

  readonly property int _mode: ModeService.mode
  readonly property int _toastHeight: notifCard.implicitHeight + (toast.notifActions.length > 0 ? actionFlow.implicitHeight + Theme.spaceSm * 2 : 0)

  implicitWidth: Theme.toastWidth
  implicitHeight: _toastHeight

  margins.top: PopupPositioner.belowBar() + 4 + stackOffset
  margins.left: toast.screen ? toast.screen.width - toast.implicitWidth - Theme.spaceMd : 0

  function show(summary: string, body: string, icon: string, appName: string, urgency: int, actions: var): void {
    toast.summary = summary
    toast.body = body
    toast.appIcon = icon
    toast.appName = appName
    toast.urgency = urgency
    toast.notifActions = actions || []
    toast.timestamp = Qt.formatDateTime(new Date(), "HH:mm")
    visible = true
    Qt.callLater(function() { shown = true })
    hideTimer.restart()
  }

  function hide(): void {
    if (_mode === ModeService.Focus || _mode === ModeService.Gaming) {
      shown = false
      visible = false
      return
    }
    shown = false
    hideTimer.stop()
  }

  Timer {
    id: hideTimer
    interval: toast.duration
    onTriggered: toast.hide()
  }

  // ── Background card ─────────────────────────────────────
  Rectangle {
    id: toastRect
    anchors.fill: parent
    radius: Theme.radiusMedium
    color: Theme.backgroundTertiary
    border.width: Theme.borderWidth
    border.color: toast.urgency === 2 ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.4) : Theme.border
    clip: true

    state: toast.shown ? "shown" : "hidden"

    states: [
      State { name: "hidden"; PropertyChanges { target: toastRect; opacity: 0; y: -8 } },
      State { name: "shown"; PropertyChanges { target: toastRect; opacity: 1; y: 0 } }
    ]

    transitions: [
      Transition {
        from: "hidden"; to: "shown"
        NumberAnimation { properties: "opacity,y"; duration: Theme.animationNormal; easing.type: Easing.OutCubic }
      },
      Transition {
        from: "shown"; to: "hidden"
        SequentialAnimation {
          NumberAnimation { properties: "opacity,y"; duration: Theme.animationFast; easing.type: Easing.InCubic }
          ScriptAction { script: { toast.visible = false } }
        }
      }
    ]

    MouseArea {
      anchors.fill: parent
      onClicked: toast.hide()
    }

    Notification {
      id: notifCard
      anchors { left: parent.left; right: parent.right; top: parent.top }
      anchors.margins: 0
      icon: toast.appIcon
      summary: toast.summary
      body: toast.body
      appName: toast.appName
      urgency: toast.urgency
      notifTime: new Date()
      showDismiss: true
      previewLines: 1
      onDismissed: toast.hide()
    }

    // ── Action buttons (below notification) ────────────
    Flow {
      id: actionFlow
      anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.spaceSm }
      spacing: Theme.spaceXs
      visible: toast.notifActions.length > 0

      Repeater {
        model: toast.notifActions

        delegate: Button {
          required property var modelData
          size: "sm"
          text: modelData.text || ""
          onClicked: {
            if (modelData.invoke) modelData.invoke()
            toast.hide()
          }
        }
      }
    }
  }

  HoverHandler {
    onHoveredChanged: {
      if (hovered) hideTimer.stop()
      else if (toast.shown) hideTimer.restart()
    }
  }
}
