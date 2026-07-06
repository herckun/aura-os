import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../../../styles"
import "../../../../services"
import "../../../../components"
import "../../../../core"

PanelWindow {
  id: smartPopup

  implicitWidth: 300
  implicitHeight: contentCol.implicitHeight + Theme.spaceMd * 2

  anchors { top: true; left: true }
  margins.top: PopupPositioner.belowBar()
  margins.left: popupX
  exclusiveZone: 0
  color: "transparent"
  visible: false

  mask: Region { item: bg }

  property Item anchorItem: null
  property real popupX: PopupPositioner.anchorCenterX(anchorItem, smartPopup.width, smartPopup.screen ? smartPopup.screen.width : 0)

  function _recalcPopupX() {
    popupX = PopupPositioner.anchorCenterX(anchorItem, smartPopup.width, smartPopup.screen ? smartPopup.screen.width : 0)
  }

  onWidthChanged: _recalcPopupX()
  onScreenChanged: _recalcPopupX()

  Timer {
    running: smartPopup.visible
    interval: 200
    repeat: true
    onTriggered: _recalcPopupX()
  }

  property bool hasMedia: MediaService.hasPlayer
  property bool hasTimer: TimerService.running
  property bool _spectrumWasActive: false
  property bool spectrumVisible: false

  Timer {
    id: spectrumHideTimer
    interval: 500
    onTriggered: {
      spec.opacity = 0
      spectrumHideTimer2.restart()
    }
  }

  Timer {
    id: spectrumHideTimer2
    interval: Theme.animationSlow
    onTriggered: spectrumVisible = false
  }

  Connections {
    target: MediaService
    function onEqBandsChanged() {
      var active = MediaService.eqBands.some(function(b) { return b > 0 })
      if (active) {
        spectrumHideTimer.stop()
        spectrumHideTimer2.stop()
        
        if (!spectrumVisible || spec.opacity < 1) {
          spectrumVisible = true
          spec.opacity = 1
        }
        _spectrumWasActive = true
      } else if (_spectrumWasActive) {
        spectrumHideTimer.restart()
      }
    }
  }

  HyprlandFocusGrab {
    windows: [smartPopup]
    active: smartPopup.visible
    onCleared: smartPopup.visible = false
  }

  function toggle(): void {
    visible = !visible
    if (visible) {
      calGrid.viewYear = calGrid.selectedDate.getFullYear()
      calGrid.viewMonth = calGrid.selectedDate.getMonth()
      calGrid.yearMode = false
    }
  }

  Timer {
    id: leaveTimer
    interval: 2000
    onTriggered: smartPopup.visible = false
  }

  HoverHandler {
    onHoveredChanged: {
      if (hovered) leaveTimer.stop()
      else if (smartPopup.visible) leaveTimer.restart()
    }
  }

  function formatPosition(ms: real): string {
    var s = Math.floor(ms)
    var m = Math.floor(s / 60)
    s = s % 60
    return m + ":" + (s < 10 ? "0" : "") + s
  }

  function formatTime(secs: int): string {
    var m = Math.floor(secs / 60)
    var s = secs % 60
    return (m < 10 ? "0" + m : "" + m) + ":" + (s < 10 ? "0" + s : "" + s)
  }

  Surface {
    id: bg
    anchors.fill: parent
    radius: Theme.radiusLarge

    Column {
      id: contentCol
      anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: Theme.spaceMd }
      spacing: Theme.spaceSm

      Item {
        width: parent.width
        height: smartPopup.hasMedia ? mediaCol.implicitHeight : 0
        clip: true
        opacity: smartPopup.hasMedia ? 1 : 0

        Behavior on opacity {
          enabled: Theme.animationsEnabled
          NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutQuad }
        }

        Column {
          id: mediaCol
          width: parent.width
          spacing: Theme.spaceSm

          RowLayout {
            width: parent.width
            spacing: Theme.spaceSm

            Rectangle {
              Layout.preferredWidth: 44
              Layout.preferredHeight: 44
              radius: Theme.radiusMedium
              color: Theme.backgroundTertiary
              border.width: Theme.borderWidth
              border.color: Theme.border
              clip: true

              Image {
                id: artImage
                anchors.fill: parent
                source: MediaService.currentArtUrl || ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
              }

              Icon {
                anchors.centerIn: parent
                source: MediaService.playbackStatus === "Playing" ? Icons.get("music") : Icons.get("pause")
                size: 18
                color: Theme.accent
                visible: artImage.status !== Image.Ready
              }
            }

            Column {
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignVCenter
              spacing: Theme.spaceXxs

              Text {
                text: MediaService.currentTitle || "UNKNOWN"
                color: Theme.textDisplay
                font.pixelSize: Theme.fontSizeBody
                font.family: Theme.fontFamilyMono
                font.weight: Font.Bold
                elide: Text.ElideRight
                maximumLineCount: 1
                width: parent.width
              }

              Text {
                text: MediaService.currentArtist || "UNKNOWN ARTIST"
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSizeCaption
                font.family: Theme.fontFamilyMono
                font.letterSpacing: 0.04
                elide: Text.ElideRight
                maximumLineCount: 1
                width: parent.width
              }

              Column {
                width: parent.width
                spacing: Theme.spaceXxs

                ProgressBar {
                  width: parent.width
                  visible: !MediaService._isStream
                  value: MediaService.duration > 0 ? MediaService.position / MediaService.duration : 0
                }

                Row {
                  width: parent.width

                  Text {
                    id: posText
                    text: MediaService._isStream ? "LIVE" : formatPosition(MediaService.position)
                    color: MediaService._isStream ? Theme.error : Theme.textDisabled
                    font.pixelSize: Theme.fontSizeMicro
                    font.family: Theme.fontFamilyMono
                    font.weight: MediaService._isStream ? Font.Bold : Font.Normal
                  }

                  Item { width: parent.width - posText.width - durText.width; height: 1 }

                  Text {
                    id: durText
                    text: MediaService._isStream ? "" : formatPosition(MediaService.duration)
                    color: Theme.textDisabled
                    font.pixelSize: Theme.fontSizeMicro
                    font.family: Theme.fontFamilyMono
                  }
                }
              }
            }
          }

          EqSpectrum {
            id: spec
            width: parent.width
            height: 48
            bands: MediaService.eqBands
            visible: spectrumVisible
            Behavior on opacity {
              enabled: Theme.animationsEnabled
              NumberAnimation { duration: Theme.animationSlow; easing.type: Easing.OutQuad }
            }
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spaceLg

            Button { shape: "circle";
              icon: "skip-back"
              size: 24
              iconSize: 10
              bgColor: "transparent"
              onClicked: MediaService.previous()
            }

            Button { shape: "circle";
              icon: MediaService.playbackStatus === "Playing" ? "pause" : "play"
              iconSize: 12
              bgColor: Theme.accent
              iconColor: Theme.background
              size: 32
              onClicked: MediaService.playPause()
            }

            Button { shape: "circle";
              icon: "skip-forward"
              size: 24
              iconSize: 10
              bgColor: "transparent"
              onClicked: MediaService.next()
            }
          }
        }
      }

      Divider { visible: smartPopup.hasMedia && smartPopup.hasTimer }

      Item {
        width: parent.width
        height: smartPopup.hasTimer ? timerCol.implicitHeight : 0
        clip: true
        opacity: smartPopup.hasTimer ? 1 : 0

        Behavior on opacity {
          enabled: Theme.animationsEnabled
          NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutQuad }
        }

        Column {
          id: timerCol
          width: parent.width
          spacing: Theme.spaceSm

          Row {
            width: parent.width

            Badge {
              id: timerBadge
              text: TimerService.paused ? "PAUSED" : "RUNNING"
              size: "xs"
            }

            Item { width: parent.width - timerBadge.width - timerModeLabel.width; height: 1 }

            Text {
              id: timerModeLabel
              text: TimerService.label || ""
              color: Theme.textDisabled
              font.pixelSize: Theme.fontSizeMicro
              font.family: Theme.fontFamilyMono
              font.letterSpacing: 0.1
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: smartPopup.formatTime(TimerService.remaining)
            color: Theme.textDisplay
            font.pixelSize: Theme.fontSizeDisplay
            font.family: Theme.fontFamilyDeco
          }

          ProgressBar {
            width: parent.width
            barHeight: 6
            value: TimerService.total > 0 ? TimerService.remaining / TimerService.total : 0
            barColor: TimerService.paused ? Theme.warning : Theme.accent
            visible: TimerService.total > 0
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spaceLg

            Button { shape: "circle";
              icon: TimerService.paused ? "play" : "pause"
              bgColor: TimerService.paused ? Theme.accent : Theme.controlBackground
              iconColor: TimerService.paused ? Theme.background : Theme.textDisplay
              onClicked: TimerService.pause()
            }

            Button { shape: "circle";
              icon: "square"
              onClicked: TimerService.stop()
            }
          }
        }
      }

      Divider {}

      CalendarGrid {
        id: calGrid
        width: parent.width
      }
    }
  }
}