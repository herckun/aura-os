import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../../styles"
import "../../../../services"
import "../../../../components"
import "../../../../core"

Item {
  id: root

  implicitWidth: mainRow.implicitWidth + (isTimerRunning() ? Theme.spaceSm : 0)
  implicitHeight: 44

  property int _lastActivated: 0

  Connections {
    target: MediaService
    function onHasPlayerChanged() { root._lastActivated = 1 }
  }

  Connections {
    target: TimerService
    function onRunningChanged() {
      if (TimerService.running || TimerService.paused) root._lastActivated = 2
    }
    function onPausedChanged() {
      if (TimerService.running || TimerService.paused) root._lastActivated = 2
    }
  }

  function isTimerRunning() { return TimerService.running }
  function isTimerPaused() { return TimerService.paused }
  function isTimerActive() { return TimerService.running || TimerService.paused }

  property bool _eqWasActive: false
  property bool eqVisible: false

  Timer {
    id: eqHideTimer
    interval: 500
    onTriggered: {
      eqDot.opacity = 0
      eqDot.scale = 0.8
      eqHideTimer2.start()
    }
  }

  Timer {
    id: eqHideTimer2
    interval: Theme.animationSlow
    onTriggered: eqVisible = false
  }

  Connections {
    target: MediaService
    function onEqBandsChanged() {
      var active = MediaService.eqBands.some(function(b) { return b > 0 })
      if (active) {
        eqHideTimer.stop()
        eqHideTimer2.stop()
        
        if (!eqVisible || eqDot.opacity < 1) {
          eqVisible = true
          eqDot.opacity = 1
          eqDot.scale = 1.0
        }
        _eqWasActive = true
      } else if (_eqWasActive) {
        eqHideTimer.restart()
      }
    }
  }

  RowLayout {
    id: mainRow
    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.spaceXs

    EqDotMatrix {
      id: eqDot
      Layout.alignment: Qt.AlignVCenter
      bands: MediaService.eqBands
      visible: eqVisible
      
      Behavior on opacity {
        enabled: Theme.animationsEnabled
        NumberAnimation { duration: Theme.animationNormal }
      }
      
      Behavior on scale {
        enabled: Theme.animationsEnabled
        NumberAnimation { duration: Theme.animationNormal }
      }
    }

    Column {
      id: clockCol
      Layout.alignment: Qt.AlignVCenter

      Text {
        id: timeText
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(DateTimeService.currentDate, "HH:mm")
        color: Theme.textDisplay
        font.pixelSize: Theme.fontSizeBody
        font.family: Theme.fontFamilyMono
        font.weight: Font.Bold
        font.letterSpacing: 0.08
      }
    }

    Badge {
      id: timerContainer
      Layout.alignment: Qt.AlignVCenter
      size: "xs"
      variant: isTimerPaused() ? "warning" : "accent"
      visible: isTimerActive()

      contentItem: Component {
        Icon {
          source: Icons.get("hourglass")
          size: 12

          RotationAnimation on rotation {
            running: !isTimerPaused()
            from: 0
            to: 360
            duration: Theme.animationVerySlow
            loops: Animation.Infinite
            onRunningChanged: {
              if (!running) rotation = 0
            }
          }

          SequentialAnimation on opacity {
            running: !isTimerPaused()
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 0.3; duration: Theme.animationVerySlow }
            NumberAnimation { from: 0.3; to: 1.0; duration: Theme.animationVerySlow }
            onRunningChanged: {
              if (!running) opacity = 1.0
            }
          }
        }
      }
    }
  }

  signal clicked()

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}