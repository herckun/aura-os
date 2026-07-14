pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQml
import Quickshell
import "../../../../styles"
import "../../../../components"
import "../../../../core"
import "../../../"

BasePlugin {
  id: root

  // ── Manifest ────────────────────────────────────────────────────
  pluginId: "notifications"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Notifications",
    description: "Recent notifications and badge",
    icon: "message",
    locations: ["controlcenter_row", "bar_right"],
    defaultLayout: { "bar_right": { order: 20 }, "controlcenter_row": { enabled: false } },
    settings: [
      { key: "maxVisible", label: "MAX VISIBLE", type: "stepper", default: 5, min: 1, max: 20, step: 1, shared: true }
    ]
  })

  // ── Public state ─────────────────────────────────────────────────

  // ── Internal state ───────────────────────────────────────────────
  property int _maxVisible: PluginService.getPluginSetting("notifications", "maxVisible", "controlcenter_row") ?? 5

  // ── Signal handlers ──────────────────────────────────────────────

  // ── Public API ───────────────────────────────────────────────────

  // ── Helpers ──────────────────────────────────────────────────────

  // ── Timers ───────────────────────────────────────────────────────

  // ── Lifecycle ────────────────────────────────────────────────────

  // ── UI components ────────────────────────────────────────────────
  property Component controlCenterComponent: Column {
    width: parent.width
    spacing: Theme.spaceSm

    RowLayout {
      width: parent.width

      SectionLabel {
        label: "NOTIFICATIONS"
        Layout.alignment: Qt.AlignVCenter
      }

      Item { Layout.fillWidth: true; height: 1 }

      Badge {
        text: NotificationService.unreadCount > 9 ? "9+" : NotificationService.unreadCount.toString()
        variant: "default"
        size: "xs"
        Layout.alignment: Qt.AlignVCenter
        visible: NotificationService.unreadCount > 0
      }
    }

    Repeater {
      model: NotificationService.notifications.slice(0, root._maxVisible)

      delegate: Rectangle {
        required property var modelData
        width: parent.width
        height: 36
        radius: Theme.radiusSmall
        antialiasing: true
        color: notifMouse.containsMouse ? Theme.controlBackgroundHover : Theme.controlBackground

        RowLayout {
          anchors.fill: parent
          anchors.margins: Theme.spaceSm
          spacing: Theme.spaceSm

          Rectangle {
            Layout.preferredWidth: 3
            Layout.fillHeight: true
            radius: Theme.radiusXs
            antialiasing: true
            color: Theme.accent
          }

          Column {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            Text {
              text: modelData.summary || "Notification"
              color: Theme.textPrimary
              font.pixelSize: Theme.fontSizeCaption
              font.family: Theme.fontFamilyMono
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              text: modelData.body || ""
              color: Theme.textSecondary
              font.pixelSize: Theme.fontSizeMicro
              font.family: Theme.fontFamilyMono
              elide: Text.ElideRight
              width: parent.width
              visible: text !== ""
            }
          }
        }

        MouseArea {
          id: notifMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: NotificationService.dismiss(modelData.id)
        }
      }
    }

    Text {
      text: NotificationService.notifications.length === 0 ? "NO NOTIFICATIONS" : ""
      color: Theme.textDisabled
      font.pixelSize: Theme.fontSizeCaption
      font.family: Theme.fontFamilyMono
      font.letterSpacing: 0.06
      visible: NotificationService.notifications.length === 0
      anchors.horizontalCenter: parent.horizontalCenter
    }
  }

  property Component barComponent: Row {
    spacing: Theme.spaceSm

    Component.onCompleted: IpcService.registerPanel("notifications", function () { notifPopup.toggle() })
    Component.onDestruction: IpcService.unregisterPanel("notifications")

    Divider { vertical: true; height: 18; anchors.verticalCenter: parent.verticalCenter }

    Item {
      anchors.verticalCenter: parent.verticalCenter
      width: 24; height: 24

      Button {
        shape: "icon"
        anchors.fill: parent
        icon: "bell"
        showBackground: false
        onClicked: notifPopup.toggle()
      }

      NotificationBadge {
        anchors { top: parent.top; right: parent.right; topMargin: -2; rightMargin: -2 }
      }

      NotificationListPopup { id: notifPopup }
    }

    Button {
      shape: "icon"
      anchors.verticalCenter: parent.verticalCenter
      width: 24; height: 24
      text: "⋮"
      showBackground: false
      onClicked: IpcService.togglePanel("controlcenter")
    }
  }
}
