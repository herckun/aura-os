pragma ComponentBehavior: Bound

import QtQuick
import QtQml
import QtQuick.Layouts
import "../../../../styles"
import "../../../../components"
import "../../../../core"
import "../../../"

BasePlugin {
  id: root

  // ── Manifest ────────────────────────────────────────────────────
  pluginId: "timer"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Timer",
    description: "Pomodoro and countdown timer",
    icon: "timer",
    locations: ["controlcenter_row", "overview"],
    overviewTab: { icon: "timer", label: "TIMER", key: "3" },
    settings: [
      { key: "defaultMinutes", label: "DEFAULT MINUTES", type: "stepper", default: 25, min: 1, max: 120, step: 1 }
    ]
  })

  // ── Public state ─────────────────────────────────────────────────

  // ── Internal state ───────────────────────────────────────────────

  // ── Signal handlers ──────────────────────────────────────────────

  // ── Public API ───────────────────────────────────────────────────

  // ── Helpers ──────────────────────────────────────────────────────

  // ── Timers ───────────────────────────────────────────────────────

  // ── Lifecycle ────────────────────────────────────────────────────

  // ── UI components ────────────────────────────────────────────────
  property Component controlCenterComponent: Column {
    id: ccCol
    width: parent.width
    spacing: Theme.spaceSm

    property int _localDefault: PluginService.getPluginSetting("timer", "defaultMinutes", "controlcenter_row") ?? 25

    SectionLabel {
      label: "TIMER"
    }

    Text {
      text: TimerService.running ? TimerService.formatTime(TimerService.remaining) :
            TimerService.paused ? TimerService.formatTime(TimerService.remaining) :
            "00:00:00"
      color: TimerService.running ? Theme.accent : Theme.textDisplay
      font.pixelSize: Theme.fontSizeHeading
      font.family: Theme.fontFamilyDisplay
      font.letterSpacing: 0.04
      anchors.horizontalCenter: parent.horizontalCenter
    }

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Theme.controlSpacing

      Button { shape: "circle"; 
        label: ccCol._localDefault + ":00"
        iconSize: 8
        buttonWidth: 52
        buttonHeight: 26
        onClicked: TimerService.startTimer(ccCol._localDefault * 60)
      }

      Button { shape: "circle"; 
        label: "5:00"
        iconSize: 8
        buttonWidth: 52
        buttonHeight: 26
        onClicked: TimerService.startTimer(300)
      }

      Button { shape: "circle"; 
        icon: TimerService.running && !TimerService.paused ? "pause" : "play"
        iconSize: 10
        size: 26
        bgColor: TimerService.running && !TimerService.paused ? Theme.textDisplay : Theme.controlBackground
        iconColor: TimerService.running && !TimerService.paused ? Theme.background : Theme.textSecondary
        onClicked: TimerService.running ? TimerService.pause() : TimerService.startTimer(TimerService.remaining > 0 ? TimerService.remaining : ccCol._localDefault * 60)
      }

      Button { shape: "circle"; 
        icon: "square"
        iconSize: 10
        size: 26
        onClicked: TimerService.stop()
      }
    }
  }

  property Component overviewComponent: FocusScope {
    id: ovScope
    width: parent ? parent.width : undefined
    implicitHeight: timerCol.implicitHeight + Theme.spaceLg * 2

    property int _localDefault: PluginService.getPluginSetting("timer", "defaultMinutes", "overview") ?? 25

    Column {
      id: timerCol
      anchors { left: parent.left; right: parent.right; top: parent.top }
      anchors.margins: Theme.spaceLg
      spacing: Theme.spaceMd

      RowLayout {
        width: parent.width

        SectionLabel { label: "Timer"; Layout.alignment: Qt.AlignVCenter }

        Item { Layout.fillWidth: true }

        Text {
          text: TimerService.running ? "RUNNING" :
                TimerService.paused ? "PAUSED" : "STOPPED"
          color: TimerService.running ? Theme.accent : Theme.textDisabled
          font.pixelSize: Theme.fontSizeCaption
          font.family: Theme.fontFamilyMono
          font.letterSpacing: 0.06
        }
      }

      Item {
        width: timeDisplay.implicitWidth + Theme.spaceLg * 2
        height: 56
        anchors.horizontalCenter: parent.horizontalCenter

        Rectangle {
          anchors.fill: parent
          visible: timerEditInput.visible
          radius: Theme.radiusMedium
          color: timerEditInput.activeFocus ? Theme.controlBackground : "transparent"
          border.width: timerEditInput.activeFocus ? 1 : 0
          border.color: Theme.accent
        }

        TextInput {
          id: timerEditInput
          anchors.fill: parent
          color: TimerService.running ? Theme.accent : Theme.textPrimary
          font.pixelSize: Theme.fontSizeDisplayLarge
          font.family: Theme.fontFamilyMono
          font.letterSpacing: 0.08
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          clip: true
          selectByMouse: true
          visible: false

          onAccepted: {
            var parts = text.split(":")
            var m = parseInt(parts[0]) || 0
            var s = parseInt(parts.length > 1 ? parts[1] : "0") || 0
            var total = m * 60 + s
            if (total > 0) {
              TimerService.startTimer(total)
              text = ""
              timerEditInput.visible = false
            }
          }

          onActiveFocusChanged: {
            if (!activeFocus && !TimerService.running) {
              visible = false
              text = ""
            }
          }
        }

        Text {
          anchors.centerIn: parent
          text: "MM:SS"
          color: Theme.textDisabled
          font.pixelSize: Theme.fontSizeDisplayLarge
          font.family: Theme.fontFamilyMono
          font.letterSpacing: 0.08
          visible: timerEditInput.visible && timerEditInput.text.length === 0 && !timerEditInput.activeFocus
        }

        Text {
          id: timeDisplay
          anchors.centerIn: parent
          text: TimerService.running ? TimerService.formatTime(TimerService.remaining) :
                TimerService.paused ? TimerService.formatTime(TimerService.remaining) : "00:00:00"
          color: TimerService.running ? Theme.accent : Theme.textPrimary
          font.pixelSize: Theme.fontSizeDisplayLarge
          font.family: Theme.fontFamilyMono
          font.letterSpacing: 0.08
          visible: !timerEditInput.visible
        }

        MouseArea {
          anchors.fill: parent
          visible: !TimerService.running && !TimerService.paused
          cursorShape: Qt.IBeamCursor
          onClicked: {
            timerEditInput.visible = true
            timerEditInput.forceActiveFocus()
          }
        }

        MouseArea {
          anchors.fill: parent
          visible: TimerService.running || TimerService.paused
        }
      }

      Divider { width: parent.width }

      Flow {
        spacing: Theme.spaceSm
        anchors.horizontalCenter: parent.horizontalCenter

        Repeater {
          model: [
            { label: "1", secs: 60 },
            { label: "5", secs: 300 },
            { label: "10", secs: 600 },
            { label: "15", secs: 900 },
            { label: "25", secs: 1500 },
            { label: "60", secs: 3600 }
          ]

          delegate: Button {
            required property var modelData
            size: "sm"
            text: modelData.label + " MIN"
            bgColor: "transparent"
            bgHoverColor: Theme.controlBackgroundHover
            onClicked: TimerService.startTimer(modelData.secs)
          }
        }
      }

      Divider { width: parent.width }

      RowLayout {
        width: parent.width
        spacing: Theme.spaceSm

        Button {
          Layout.fillWidth: true
          size: "sm"
          text: TimerService.running ? "PAUSE" : TimerService.paused ? "RESUME" : "START"
          variant: TimerService.running || TimerService.paused ? "accent" : "default"
          bgColor: "transparent"
          bgHoverColor: Theme.controlBackgroundHover
          onClicked: {
            if (TimerService.running) TimerService.pause()
            else if (TimerService.paused) TimerService.pause()
            else TimerService.startTimer(ovScope._localDefault * 60)
          }
        }

        Button {
          Layout.fillWidth: true
          size: "sm"
          text: "STOP"
          color: Theme.textSecondary
          bgColor: "transparent"
          bgHoverColor: Theme.controlBackgroundHover
          onClicked: {
            TimerService.stop()
            timerEditInput.text = ""
            timerEditInput.visible = false
          }
        }
      }
    }
  }
}
