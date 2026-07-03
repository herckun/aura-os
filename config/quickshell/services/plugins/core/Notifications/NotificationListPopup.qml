import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../../../styles"
import "../../../../core"
import "../../../../services"
import "../../../../components"

PanelContainer {
  id: notifList

  implicitWidth: 340
  paddingX: 20
  paddingY: 20

  property int maxVisible: 20

  RowLayout {
    width: parent.width
    spacing: Theme.spaceXs
    visible: NotificationService.notifications.length > 0

    Column {
      Layout.fillWidth: true
      spacing: Theme.spaceXs

      Text {
        text: "NOTIFICATIONS"
        color: Theme.textDisplay
        font.pixelSize: Theme.fontSizeLabel
        font.family: Theme.fontFamilyMono
        font.weight: Font.Bold
        font.letterSpacing: 0.12
      }

      Text {
        text: NotificationService.notifications.length + " TOTAL"
             + (NotificationService.unreadCount > 0 ? "·" + NotificationService.unreadCount + " UNREAD" : "")
        color: Theme.textSecondary
        font.pixelSize: Theme.fontSizeCaption
        font.family: Theme.fontFamilyMono
        font.letterSpacing: 0.06
      }
    }

    Button {
      shape: "link"
      text: "MARK READ"
      visible: NotificationService.unreadCount > 0
      onClicked: NotificationService.markAllRead()
    }

    Button {
      shape: "link"
      text: "CLEAR ALL"
      visible: NotificationService.notifications.length > 0
      onClicked: NotificationService.clearAll()
    }
  }

  Item {
    width: parent.width
    height: 200
    visible: NotificationService.notifications.length === 0

    Column {
      anchors.centerIn: parent
      spacing: Theme.spaceSm

      Icon {
        anchors.horizontalCenter: parent.horizontalCenter
        source: Icons.get("bell")
        size: 48
        color: Theme.textDisabled
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "NO NOTIFICATIONS"
        color: Theme.textDisabled
        font.pixelSize: Theme.fontSizeLabel
        font.family: Theme.fontFamilyMono
        font.letterSpacing: 0.1
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "You're all caught up"
        color: Theme.textSecondary
        font.pixelSize: Theme.fontSizeCaption
        font.family: Theme.fontFamily
      }
    }
  }

  Repeater {
    model: NotificationService.notifications.slice(0, notifList.maxVisible)

    delegate: Notification {
      required property var modelData
      required property int index

      property bool removing: false

      width: parent.width
      height: removing ? 0 : implicitHeight
      icon: modelData.icon || ""
      summary: modelData.summary || "Notification"
      body: modelData.body || ""
      appName: modelData.appName || ""
      urgency: modelData.urgency || 1
      notifTime: modelData.time || new Date()
      showDismiss: true

      Behavior on height { enabled: Theme.animationsEnabled; NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.InOutCubic } }

      Timer {
        id: removeTimer
        interval: Theme.animationNormal
        onTriggered: NotificationService.dismiss(modelData.id)
      }

      onDismissed: {
        if (removing) return
        removing = true
        if (Theme.animationsEnabled) removeTimer.start()
        else NotificationService.dismiss(modelData.id)
      }
    }
  }

  Text {
    width: parent.width
    horizontalAlignment: Text.AlignHCenter
    text: "+" + (NotificationService.notifications.length - notifList.maxVisible) + " MORE"
    color: Theme.textDisabled
    font.pixelSize: Theme.fontSizeCaption
    font.family: Theme.fontFamilyMono
    font.letterSpacing: 0.08
    visible: NotificationService.notifications.length > notifList.maxVisible
    topPadding: Theme.spaceXs
  }
}
