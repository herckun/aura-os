import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../styles"
import "../../core"
import "../../services"
import "../../components"

PanelWindow {
  id: calendarPopup

  implicitWidth: 300
  implicitHeight: 340

  anchors {
    top: true
    left: true
    right: true
  }
  margins.top: PopupPositioner.belowBar()
  margins.left: AppearanceService.barFloating ? BarService.sideOffset : Theme.spaceXs
  margins.right: AppearanceService.barFloating ? BarService.sideOffset : Theme.spaceXs

  exclusiveZone: 0
  color: "transparent"
  visible: false

  mask: Region { item: calBg }

  function toggle(): void { calendarPopup.visible = !calendarPopup.visible }

  Connections {
    target: DateTimeService
    function onCurrentDateChanged() {
      calendarPopup.todayDate = DateTimeService.currentDate
    }
  }

  HyprlandFocusGrab {
    windows: [calendarPopup]
    active: calendarPopup.visible
    onCleared: calendarPopup.visible = false
  }

  Timer {
    id: leaveTimer
    interval: 2000
    onTriggered: calendarPopup.visible = false
  }

  HoverHandler {
    onHoveredChanged: {
      if (hovered) leaveTimer.stop()
      else if (calendarPopup.visible) leaveTimer.restart()
    }
  }

  property date selectedDate: new Date()
  property date todayDate: new Date()

  function daysInMonth(date): int {
    return new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate()
  }

  function firstDayOffset(date): int {
    return new Date(date.getFullYear(), date.getMonth(), 1).getDay()
  }

  Surface {
    id: calBg
    anchors.fill: parent
    radius: Theme.radiusMedium
    antialiasing: true
  }

  Column {
    anchors { fill: parent; margins: Theme.spaceMd }
    spacing: Theme.spaceMd

    Row {
      width: parent.width

      Text {
        text: Qt.formatDateTime(calendarPopup.selectedDate, "MMMM yyyy").toUpperCase()
        color: Theme.textDisplay
        font.pixelSize: Theme.fontSizeCaption
        font.family: Theme.fontFamilyMono
        font.letterSpacing: 0.06
        anchors.verticalCenter: parent.verticalCenter
      }

      Item { width: parent.width - 160; height: 1 }

      Button {
        shape: "icon"
        icon: "chevron.left"
        size: "xs"
        showBackground: false
        onClicked: {
          var d = calendarPopup.selectedDate
          calendarPopup.selectedDate = new Date(d.getFullYear(), d.getMonth() - 1, 1)
        }
      }

      Button {
        shape: "icon"
        icon: "chevron.right"
        size: "xs"
        showBackground: false
        onClicked: {
          var d = calendarPopup.selectedDate
          calendarPopup.selectedDate = new Date(d.getFullYear(), d.getMonth() + 1, 1)
        }
      }
    }

    Grid {
      width: parent.width
      columns: 7
      columnSpacing: 2
      rowSpacing: 2

      Repeater {
        model: ["S", "M", "T", "W", "T", "F", "S"]
        delegate: Text {
          width: 34; horizontalAlignment: Text.AlignHCenter
          text: modelData
          color: Theme.textSecondary
          font.pixelSize: Theme.fontSizeCaption
          font.family: Theme.fontFamilyMono
          font.letterSpacing: 0.06
        }
      }

      Repeater {
        model: calendarPopup.firstDayOffset(calendarPopup.selectedDate) + calendarPopup.daysInMonth(calendarPopup.selectedDate)

        delegate: Item {
          width: 34; height: 30
          property int dayIndex: index - calendarPopup.firstDayOffset(calendarPopup.selectedDate)
          property bool isDay: dayIndex >= 0
          property int day: dayIndex + 1
          property bool isToday: isDay && day === calendarPopup.todayDate.getDate() &&
                                 calendarPopup.selectedDate.getMonth() === calendarPopup.todayDate.getMonth() &&
                                 calendarPopup.selectedDate.getFullYear() === calendarPopup.todayDate.getFullYear()

          Rectangle {
            anchors.centerIn: parent
            width: 24; height: 24
            color: isToday ? Theme.textDisplay : "transparent"
            visible: isDay
          }

          Text {
            anchors.centerIn: parent
            text: isDay ? String(day) : ""
            color: isToday ? Theme.contrastTextColor(Theme.textDisplay) : Theme.textPrimary
            font.pixelSize: Theme.fontSizeCaption
            font.family: Theme.fontFamilyMono
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: isDay ? Qt.PointingHandCursor : Qt.ArrowCursor
            visible: isDay
          }
        }
      }
    }

    Rectangle { width: parent.width; height: 1; color: Theme.border }

    Column {
      width: parent.width
      spacing: Theme.spaceXs

      Text { text: "EVENTS"; color: Theme.textSecondary; font.pixelSize: Theme.fontSizeCaption; font.family: Theme.fontFamilyMono; font.letterSpacing: 0.06 }
      Text { text: "NO EVENTS"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeCaption; font.family: Theme.fontFamilyMono; visible: true }
    }
  }
}
