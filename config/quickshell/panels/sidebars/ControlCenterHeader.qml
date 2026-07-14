import QtQuick
import QtQuick.Layouts
import "../../styles"
import "../../core"
import "../../services"
import "../../components"

Section {
  id: header
  borderEnabled: false
  transparentBg: true
  paddingX: 0
  paddingY: 0

  property bool menuOpen: false
  readonly property Item menuAnchor: idHit

  readonly property var _menuActions: [
    { icon: "user",      label: "PROFILE",   act: "profile", group: 0 },
    { icon: "settings",  label: "SETTINGS",  act: "settings", group: 0 },
    { icon: "refresh",   label: "RELOAD SHELL", act: "reload", group: 0 },
    { icon: "lock",      label: "LOCK",      act: "lock", group: 1 },
    { icon: "moon",      label: "SUSPEND",   act: "cmd", cmd: ["systemctl", "suspend"], group: 1 },
    { icon: "snowflake", label: "HIBERNATE", act: "cmd", cmd: ["systemctl", "hibernate"], group: 1 },
    { icon: "logout",    label: "LOG OUT",   act: "cmd", cmd: ["hyprctl", "dispatch", "exit"], group: 2 },
    { icon: "restart",   label: "REBOOT",    act: "cmd", cmd: ["systemctl", "reboot"], danger: true, group: 2 },
    { icon: "power",     label: "SHUT DOWN", act: "cmd", cmd: ["systemctl", "poweroff"], danger: true, group: 2 }
  ]

  function _runAction(a: var): void {
    header.menuOpen = false
    switch (a.act) {
    case "profile":
      ControlCenterService.visible = false
      IpcService.navigatePanel("settings", "user")
      return
    case "settings":
      ControlCenterService.visible = false
      IpcService.togglePanel("settings")
      return
    case "reload":
      ProcessPool.runDetached("hyprctl reload && pkill -TERM -x qs && sleep 1 && nohup qs >/dev/null 2>&1 &", { shell: true })
      return
    case "lock":
      ControlCenterService.visible = false
      LockService.lock()
      return
    default:
      ProcessPool.runDetached(a.cmd)
    }
  }

  Connections {
    target: ControlCenterService
    function onVisibleChanged() {
      if (!ControlCenterService.visible)
        header.menuOpen = false
    }
  }

  ColumnLayout {
    width: parent.width
    spacing: Theme.spaceSm

    Rectangle {
      id: idHit
      Layout.fillWidth: true
      implicitHeight: idRow.implicitHeight + Theme.spaceXs * 2
      radius: Theme.radiusMedium
      antialiasing: true
      color: idMa.containsMouse || header.menuOpen
        ? Theme.controlBackgroundHover
        : "transparent"

      Behavior on color { enabled: Theme.animationsEnabled; ColorAnimation { duration: Theme.animationFast } }

      RowLayout {
        id: idRow
        anchors.fill: parent
        anchors.leftMargin: Theme.spaceXs
        anchors.rightMargin: Theme.spaceSm
        spacing: Theme.spaceSm

        Avatar {
          Layout.alignment: Qt.AlignVCenter
          size: 34
          source: UserService.avatarSource
          fallbackText: UserService.initial
          ringColor: idMa.containsMouse || header.menuOpen ? Theme.accent : Theme.borderVisible
        }

        ColumnLayout {
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignVCenter
          spacing: 0

          Text {
            text: "HELLO,"
            color: Theme.textDisabled
            font.pixelSize: Theme.fontSizeMicro
            font.family: Theme.fontFamilyMono
            font.letterSpacing: 0.16
          }

          Text {
            Layout.fillWidth: true
            text: UserService.displayName.toUpperCase()
            color: idMa.containsMouse || header.menuOpen ? Theme.accent : Theme.textPrimary
            font.pixelSize: Theme.fontSizeCaption
            font.family: Theme.fontFamilyMono
            font.weight: Font.Bold
            font.letterSpacing: 0.14
            elide: Text.ElideRight

            Behavior on color { enabled: Theme.animationsEnabled; ColorAnimation { duration: Theme.animationFast } }
          }
        }

        Icon {
          Layout.alignment: Qt.AlignVCenter
          source: Icons.get("caret-down")
          size: 10
          color: idMa.containsMouse || header.menuOpen ? Theme.accent : Theme.textDisabled
          rotation: header.menuOpen ? 180 : 0

          Behavior on rotation { enabled: Theme.animationsEnabled; NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic } }
        }
      }

      MouseArea {
        id: idMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: header.menuOpen = !header.menuOpen
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Theme.spaceXxs

      RowLayout {
        spacing: Theme.space2

        Text {
          text: Qt.formatDateTime(DateTimeService.currentDate, "HH")
          color: Theme.textDisplay
          font.pixelSize: Theme.fontSizeDisplay
          font.family: Theme.fontFamilyDeco
          font.letterSpacing: 0.02
        }

        Text {
          text: ":"
          color: Theme.textDisabled
          font.pixelSize: Theme.fontSizeDisplay
          font.family: Theme.fontFamilyDeco
          font.letterSpacing: 0.02

          SequentialAnimation on opacity {
            running: true
            loops: Animation.Infinite
            NumberAnimation { from: 1; to: 0.3; duration: Theme.animationVerySlow; easing.type: Easing.InOutQuad }
            NumberAnimation { from: 0.3; to: 1; duration: Theme.animationVerySlow; easing.type: Easing.InOutQuad }
          }
        }

        Text {
          text: Qt.formatDateTime(DateTimeService.currentDate, "mm")
          color: Theme.textDisplay
          font.pixelSize: Theme.fontSizeDisplay
          font.family: Theme.fontFamilyDeco
          font.letterSpacing: 0.02
        }
      }

      Text {
        text: Qt.formatDateTime(DateTimeService.currentDate, "dddd, MMMM d").toUpperCase()
        color: Theme.textSecondary
        font.pixelSize: Theme.fontSizeCaption
        font.family: Theme.fontFamilyMono
        font.letterSpacing: 0.1
      }

      Text {
        text: ResourceService.uptime ? "UPTIME " + ResourceService.uptime : ""
        color: Theme.textDisabled
        font.pixelSize: Theme.fontSizeMicro
        font.family: Theme.fontFamilyMono
        font.letterSpacing: 0.06
        visible: ResourceService.uptime !== ""
      }
    }
  }
}
