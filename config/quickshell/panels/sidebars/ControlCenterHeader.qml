import QtQuick
import QtQuick.Layouts
import "../../styles"
import "../../core"
import "../../services"
import "../../components"

Section {
  borderEnabled: false
  transparentBg: true
  paddingX: 0
  paddingY: 0

  ColumnLayout {
    width: parent.width
    spacing: Theme.spaceSm

    RowLayout {
      Layout.fillWidth: true
      spacing: Theme.spaceSm

      Avatar {
        Layout.alignment: Qt.AlignVCenter
        size: 34
        source: UserService.avatarSource
        fallbackText: UserService.initial
      }

      Text {
        Layout.fillWidth: true
        text: UserService.displayName.toUpperCase()
        color: Theme.textPrimary
        font.pixelSize: Theme.fontSizeCaption
        font.family: Theme.fontFamilyMono
        font.weight: Font.Bold
        font.letterSpacing: 0.14
        elide: Text.ElideRight
      }

      ButtonGroup {
        Layout.alignment: Qt.AlignVCenter

        Button { shape: "circle";
          icon: "settings"
          size: "md"
          buttonWidth: 30
          buttonHeight: 30
          iconSize: 14
          onClicked: IpcService.togglePanel("settings")
        }

        Button { shape: "circle";
          icon: "refresh"
          size: "md"
          buttonWidth: 30
          buttonHeight: 30
          iconSize: 14
          onClicked: {
            ProcessPool.runDetached("hyprctl reload && pkill -TERM -x qs && sleep 1 && nohup qs >/dev/null 2>&1 &", { shell: true })
          }
        }

        Button { shape: "circle";
          icon: "power"
          size: "md"
          buttonWidth: 30
          buttonHeight: 30
          iconSize: 14
          actionId: "power"
          onClicked: {
            ProcessPool.runQueued("Power", ["wleave", "-m", Theme.wleaveSize, "-p", "layer-shell"], {
              silent: true,
              id: "power",
            })
          }
        }
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
          font.family: Theme.fontFamilyDisplay
          font.letterSpacing: 0.02
        }

        Text {
          text: ":"
          color: Theme.textDisabled
          font.pixelSize: Theme.fontSizeDisplay
          font.family: Theme.fontFamilyDisplay
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
          font.family: Theme.fontFamilyDisplay
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
