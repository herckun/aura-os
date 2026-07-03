import QtQuick
import QtQuick.Layouts
import "../../../../styles"
import "../../../../services"
import "../../../../components"

Column {
  id: cal
  width: parent ? parent.width : 200

  property date selectedDate: DateTimeService.currentDate
  property date todayDate: DateTimeService.currentDate
  property bool yearMode: false
  property int viewYear: selectedDate.getFullYear()
  property int viewMonth: selectedDate.getMonth()

  spacing: Theme.spaceSm

  function daysInMonth(y: int, m: int): int {
    return new Date(y, m + 1, 0).getDate()
  }

  function firstDayOffset(y: int, m: int): int {
    return new Date(y, m, 1).getDay()
  }

  function formatHeader(): string {
    if (yearMode) return String(viewYear)
    var d = new Date(viewYear, viewMonth, 1)
    var months = ["JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE",
                  "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"]
    return months[d.getMonth()] + " " + d.getFullYear()
  }

  RowLayout {
    width: parent.width
    spacing: Theme.spaceXs

    Button {
      shape: "icon"
      icon: "chevron.left"
      size: "xs"
      showBackground: false
      onClicked: {
        if (cal.yearMode) {
          cal.viewYear--
        } else {
          if (cal.viewMonth === 0) { cal.viewMonth = 11; cal.viewYear-- }
          else cal.viewMonth--
        }
      }
    }

    Button {
      Layout.fillWidth: true
      shape: "default"
      size: "xs"
      text: cal.formatHeader()
      onClicked: {
        if (!cal.yearMode) cal.yearMode = true
      }
    }

    Button {
      shape: "icon"
      icon: "chevron.right"
      size: "xs"
      showBackground: false
      onClicked: {
        if (cal.yearMode) {
          cal.viewYear++
        } else {
          if (cal.viewMonth === 11) { cal.viewMonth = 0; cal.viewYear++ }
          else cal.viewMonth++
        }
      }
    }
  }

  Grid {
    width: parent.width
    columns: 7
    columnSpacing: Theme.space2
    rowSpacing: Theme.space2
    visible: !cal.yearMode

    Repeater {
      model: ["S", "M", "T", "W", "T", "F", "S"]
      delegate: Text {
        width: (parent.width - Theme.space2 * 6) / 7
        horizontalAlignment: Text.AlignHCenter
        text: modelData
        color: Theme.textSecondary
        font.pixelSize: Theme.fontSizeCaption
        font.family: Theme.fontFamilyMono
        font.letterSpacing: 0.06
      }
    }

    Repeater {
      model: cal.firstDayOffset(cal.viewYear, cal.viewMonth) + cal.daysInMonth(cal.viewYear, cal.viewMonth)

      delegate: Item {
        width: (parent.width - Theme.space2 * 6) / 7
        height: 26
        property int dayIndex: index - cal.firstDayOffset(cal.viewYear, cal.viewMonth)
        property bool isDay: dayIndex >= 0
        property int day: dayIndex + 1
        property bool isToday: isDay && day === cal.todayDate.getDate() &&
                               cal.viewMonth === cal.todayDate.getMonth() &&
                               cal.viewYear === cal.todayDate.getFullYear()

        Rectangle {
          anchors.centerIn: parent
          width: 22
          height: 22
          radius: Theme.radiusSmall
          color: isToday ? Theme.accent : "transparent"
          visible: isDay
        }

        Text {
          anchors.centerIn: parent
          text: isDay ? String(day) : ""
          color: isToday ? Theme.contrastTextColor(Theme.accent) : Theme.textPrimary
          font.pixelSize: Theme.fontSizeCaption
          font.family: Theme.fontFamilyMono
        }

        MouseArea {
          anchors.fill: parent
          visible: isDay
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            cal.selectedDate = new Date(cal.viewYear, cal.viewMonth, day)
            cal.yearMode = false
          }
        }
      }
    }
  }

  Grid {
    width: parent.width
    columns: 3
    columnSpacing: Theme.spaceSm
    rowSpacing: Theme.spaceSm
    visible: cal.yearMode

    Repeater {
      model: 12

      delegate: Button {
        required property int index

        width: (parent.width - Theme.spaceSm * 2) / 3
        shape: "default"
        size: "xs"
        text: Qt.formatDateTime(new Date(2000, index, 1), "MMM")
        active: cal.viewMonth === index
        onClicked: {
          cal.viewMonth = index
          cal.yearMode = false
        }
      }
    }
  }

  Component.onCompleted: {
    todayDate = DateTimeService.currentDate
    selectedDate = DateTimeService.currentDate
    viewYear = selectedDate.getFullYear()
    viewMonth = selectedDate.getMonth()
  }

  Connections {
    target: DateTimeService
    function onCurrentDateChanged() {
      cal.todayDate = DateTimeService.currentDate
    }
  }
}
