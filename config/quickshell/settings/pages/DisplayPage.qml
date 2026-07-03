import QtQuick
import QtQuick.Layouts
import "../../styles"
import "../../core"
import "../../services"
import "../../components"

Column {
  id: root
  spacing: Theme.spaceLg
  width: parent.width

  property int selectedMonitor: 0

  PageHeader { title: "DISPLAY" }

  // ── Top bar ─────────────────────────────────────────────────
  Surface {
    width: parent.width
    height: topRow.implicitHeight + Theme.spaceMd * 2
    radius: Theme.radiusMedium
    border.color: Theme.border

    RowLayout {
      id: topRow
      anchors.fill: parent
      anchors.margins: Theme.spaceMd
      spacing: Theme.spaceMd

      Column {
        Layout.fillWidth: true
        spacing: Theme.spaceXxs

        Text {
          text: (DisplayService.monitors ? DisplayService.monitors.length : 0) + " DISPLAY" + (DisplayService.monitors.length !== 1 ? "S" : "")
          color: Theme.textPrimary
          font.pixelSize: Theme.fontSizeLabel
          font.family: Theme.fontFamilyMono
          font.weight: Font.Bold
          font.letterSpacing: 0.08
        }

        Text {
          text: {
            if (DisplayService.pendingApply)
              return "Confirm in " + DisplayService.countdownRemaining + "s or auto-revert"
            if (DisplayService.detecting)
              return "Scanning..."
            if (DisplayService.hasPending)
              return "Unsaved changes"
            return "All displays configured"
          }
          color: DisplayService.pendingApply ? Theme.warning
            : DisplayService.hasPending ? Theme.accent
            : Theme.textSecondary
          font.pixelSize: Theme.fontSizeMicro
          font.family: Theme.fontFamilyMono
        }
      }

      Button {
        text: "DETECT"
        size: "sm"
        shape: "link"
        icon: "refresh"
        busy: DisplayService.detecting
        enabled: !DisplayService.pendingApply
        onClicked: DisplayService.detectMonitors()
      }

      Button {
        text: "RESET"
        size: "sm"
        shape: "link"
        icon: "arrow-clockwise"
        enabled: !DisplayService.pendingApply
        onClicked: DisplayService.resetToDefaults()
      }

      Button {
        text: "APPLY"
        size: "sm"
        icon: "check"
        variant: "accent"
        enabled: DisplayService.hasPending && !DisplayService.pendingApply
        onClicked: DisplayService.applyPending()
      }
    }
  }

  // ── Pending banner ──────────────────────────────────────────
  Surface {
    width: parent.width
    height: pendingCol.implicitHeight + Theme.spaceMd * 2
    radius: Theme.radiusMedium
    color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.06)
    border.color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.25)
    visible: DisplayService.pendingApply

    Column {
      id: pendingCol
      anchors.fill: parent
      anchors.margins: Theme.spaceMd
      spacing: Theme.spaceSm

      RowLayout {
        width: parent.width
        spacing: Theme.spaceSm

        Icon { source: Icons.get("alert"); size: 14; color: Theme.warning }

        Text {
          text: "CONFIRM DISPLAY SETTINGS"
          color: Theme.warning
          font.pixelSize: Theme.fontSizeMicro
          font.family: Theme.fontFamilyMono
          font.weight: Font.Bold
          font.letterSpacing: 0.06
        }

        Item { Layout.fillWidth: true }

        Text {
          text: DisplayService.countdownRemaining + "s"
          color: Theme.textSecondary
          font.pixelSize: Theme.fontSizeCaption
          font.family: Theme.fontFamilyMono
          font.weight: Font.Bold
        }
      }

      ProgressBar {
        width: parent.width
        barHeight: 3
        barColor: Theme.warning
        value: DisplayService.countdownRemaining / 10
      }

      Row {
        spacing: Theme.spaceSm
        anchors.right: parent.right
        Button { text: "REVERT"; size: "sm"; icon: "arrow-clockwise"; onClicked: DisplayService.revert() }
        Button { text: "KEEP"; size: "sm"; icon: "check"; variant: "accent"; onClicked: DisplayService.confirmApply() }
      }
    }
  }

  // ── Empty state ─────────────────────────────────────────────
  Surface {
    width: parent.width
    height: emptyCol.implicitHeight + Theme.spaceXl * 2
    radius: Theme.radiusMedium
    border.color: Theme.border
    visible: !DisplayService.detecting && (!DisplayService.monitors || DisplayService.monitors.length === 0)

    Column {
      id: emptyCol
      anchors.centerIn: parent
      spacing: Theme.spaceMd
      Icon { source: Icons.get("monitor"); size: 36; color: Theme.textDisabled; anchors.horizontalCenter: parent.horizontalCenter }
      Text { text: "NO DISPLAYS FOUND"; color: Theme.textSecondary; font.pixelSize: Theme.fontSizeLabel; font.family: Theme.fontFamilyMono; font.weight: Font.Bold; font.letterSpacing: 0.08; anchors.horizontalCenter: parent.horizontalCenter }
      Text { text: "Click DETECT to scan"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeCaption; font.family: Theme.fontFamilyMono; anchors.horizontalCenter: parent.horizontalCenter }
    }
  }

  // ── Hero monitor cards ──────────────────────────────────────
  GridLayout {
    width: parent.width
    columns: DisplayService.monitors && DisplayService.monitors.length > 1 ? 2 : 1
    columnSpacing: Theme.spaceMd
    rowSpacing: Theme.spaceMd
    visible: DisplayService.monitors && DisplayService.monitors.length > 0

    Repeater {
      model: DisplayService.monitors || []

      delegate: Surface {
        id: heroCard
        Layout.fillWidth: true
        Layout.preferredHeight: heroCol.implicitHeight + Theme.spaceLg * 2
        radius: Theme.radiusLarge
        color: root.selectedMonitor === index
          ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08)
          : Theme.backgroundSecondary
        border.width: root.selectedMonitor === index ? 2 : Theme.borderWidth
        border.color: root.selectedMonitor === index ? Theme.accent : Theme.border

        property var monitor: modelData

        Behavior on color { enabled: Theme.animationsEnabled; ColorAnimation { duration: Theme.animationFast } }
        Behavior on border.color { enabled: Theme.animationsEnabled; ColorAnimation { duration: Theme.animationFast } }

        Column {
          id: heroCol
          anchors.fill: parent
          anchors.margins: Theme.spaceLg
          spacing: Theme.spaceMd

          RowLayout {
            width: parent.width
            spacing: Theme.spaceSm

            Surface {
              width: 40; height: 40; radius: Theme.radiusMedium
              bordered: false
              color: root.selectedMonitor === index
                ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)
                : Theme.backgroundTertiary

              Icon {
                anchors.centerIn: parent
                source: Icons.get("monitor")
                size: 18
                color: root.selectedMonitor === index ? Theme.accent : Theme.textSecondary
              }
            }

            Column {
              Layout.fillWidth: true
              spacing: 2

              Text {
                text: (monitor.name || "?").toUpperCase()
                color: Theme.textPrimary
                font.pixelSize: Theme.fontSizeHeading
                font.family: Theme.fontFamilyMono
                font.weight: Font.Bold
                font.letterSpacing: 0.06
              }

              Text {
                text: monitor.description || monitor.model || "Unknown"
                color: Theme.textDisabled
                font.pixelSize: Theme.fontSizeCaption
                font.family: Theme.fontFamilyMono
                elide: Text.ElideRight
                width: parent.width
              }
            }

            Badge {
              text: monitor.focused ? "PRIMARY" : "EXT"
              variant: monitor.focused ? "accent" : "default"
              size: "sm"
            }
          }

          Surface {
            width: parent.width
            height: resRow.implicitHeight + Theme.spaceMd * 2
            radius: Theme.radiusMedium
            bordered: false
            color: Theme.backgroundTertiary

            RowLayout {
              id: resRow
              anchors.fill: parent
              anchors.margins: Theme.spaceMd
              spacing: Theme.spaceMd

              Column {
                spacing: 2
                Text {
                  text: "RESOLUTION"
                  color: Theme.textDisabled
                  font.pixelSize: Theme.fontSizeMicro
                  font.family: Theme.fontFamilyMono
                  font.letterSpacing: 0.1
                }
                Text {
                  text: DisplayService.getCurrentMode(monitor) || "---"
                  color: Theme.textPrimary
                  font.pixelSize: Theme.fontSizeTitle
                  font.family: Theme.fontFamilyMono
                  font.weight: Font.Bold
                  font.letterSpacing: 0.02
                }
              }

              Item { Layout.fillWidth: true }

              Column {
                spacing: Theme.spaceXxs
                Layout.alignment: Qt.AlignVCenter
                Text {
                  text: "SCALE"
                  color: Theme.textDisabled
                  font.pixelSize: Theme.fontSizeMicro
                  font.family: Theme.fontFamilyMono
                  font.letterSpacing: 0.1
                  horizontalAlignment: Text.AlignRight
                  anchors.right: parent.right
                }
                Text {
                  text: {
                    var cfg = DisplayService.getConfigForOutput(monitor.name)
                    return (cfg ? cfg.scale : String(monitor.scale || 1)) + "x"
                  }
                  color: Theme.textPrimary
                  font.pixelSize: Theme.fontSizeLabel
                  font.family: Theme.fontFamilyMono
                  font.weight: Font.Bold
                  horizontalAlignment: Text.AlignRight
                  anchors.right: parent.right
                }
              }

              Column {
                spacing: Theme.spaceXxs
                Layout.alignment: Qt.AlignVCenter
                Text {
                  text: "POSITION"
                  color: Theme.textDisabled
                  font.pixelSize: Theme.fontSizeMicro
                  font.family: Theme.fontFamilyMono
                  font.letterSpacing: 0.1
                  horizontalAlignment: Text.AlignRight
                  anchors.right: parent.right
                }
                Text {
                  text: {
                    var cfg = DisplayService.getConfigForOutput(monitor.name)
                    return cfg ? cfg.position : ((monitor.x || 0) + "x" + (monitor.y || 0))
                  }
                  color: Theme.textPrimary
                  font.pixelSize: Theme.fontSizeLabel
                  font.family: Theme.fontFamilyMono
                  font.weight: Font.Bold
                  horizontalAlignment: Text.AlignRight
                  anchors.right: parent.right
                }
              }
            }
          }

          Row {
            spacing: Theme.spaceXs
            Repeater {
              model: [
                { label: "MAKE", value: monitor.make || "---" },
                { label: "MODEL", value: monitor.model || "---" },
                { label: "SIZE", value: (monitor.physicalWidth || "?") + "x" + (monitor.physicalHeight || "?") + "mm" }
              ]
              delegate: Surface {
                height: 22
                width: chipRow.implicitWidth + Theme.spaceSm * 2
                radius: Theme.radiusSmall
                bordered: false
                color: Theme.backgroundTertiary

                Row {
                  id: chipRow
                  anchors.centerIn: parent
                  spacing: Theme.spaceXxs

                  Text {
                    text: modelData.label
                    color: Theme.textDisabled
                    font.pixelSize: Theme.fontSizeMicro
                    font.family: Theme.fontFamilyMono
                    font.letterSpacing: 0.08
                    anchors.verticalCenter: parent.verticalCenter
                  }

                  Text {
                    text: modelData.value
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontSizeMicro
                    font.family: Theme.fontFamilyMono
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }
              }
            }
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.selectedMonitor = index
        }
      }
    }
  }

  // ── Settings panel for selected monitor ─────────────────────
  Repeater {
    model: DisplayService.monitors || []

    delegate: Card {
      width: parent.width
      visible: root.selectedMonitor === index

      property var monitor: modelData
      property string outputName: monitor.name || "Unknown"
      property var config: DisplayService.getConfigForOutput(outputName)
      property string posText: ""

      Component.onCompleted: _syncPos()
      onConfigChanged: _syncPos()

      function _syncPos() {
        var val = (config && config.position) ? config.position : ((monitor.x || 0) + "x" + (monitor.y || 0))
        posText = val
        if (posInput) posInput.input.text = val
      }

      Connections {
        target: DisplayService
        function onConfigEntriesChanged() {
          config = DisplayService.getConfigForOutput(outputName)
        }
      }

      Column {
        width: parent.width
        spacing: 0
        enabled: !DisplayService.pendingApply

        SettingRow {
          width: parent.width
          label: "RESOLUTION"
          SelectDropdown {
            width: 260
            placeholder: "Select resolution..."
            items: {
              var modes = DisplayService.getAvailableModes(monitor)
              var result = []
              for (var i = 0; i < modes.length; i++) {
                result.push({ label: modes[i].label, value: modes[i].value })
              }
              return result
            }
            textRole: "label"
            valueRole: "value"
            value: config ? config.mode : ""
            onItemSelected: function(item) {
              var scale = config ? config.scale : String(monitor.scale || 1)
              var pos = config ? config.position : ((monitor.x || 0) + "x" + (monitor.y || 0))
              DisplayService.updateMonitor(outputName, item.value, scale, pos)
            }
          }
        }

        Divider { width: parent.width }

        SettingRow {
          width: parent.width
          label: "SCALE"
          SelectDropdown {
            width: 140
            placeholder: "Scale..."
            items: DisplayService.getScaleOptions()
            textRole: "label"
            valueRole: "value"
            value: config ? config.scale : "1.0"
            onItemSelected: function(item) {
              var mode = config ? config.mode : DisplayService.getCurrentMode(monitor)
              var pos = config ? config.position : ((monitor.x || 0) + "x" + (monitor.y || 0))
              DisplayService.updateMonitor(outputName, mode, item.value, pos)
            }
          }
        }

        Divider { width: parent.width }

        SettingRow {
          width: parent.width
          label: "POSITION"
          Input {
            id: posInput
            width: 180
            placeholder: "auto"
            iconName: "map-pin"

            onAccepted: {
              var mode = config ? config.mode : DisplayService.getCurrentMode(monitor)
              var scale = config ? config.scale : "1.0"
              DisplayService.updateMonitor(outputName, mode, scale, input.text || "auto")
            }
          }
        }
      }
    }
  }

  // ── Fallback ────────────────────────────────────────────────
  Card {
    id: fallbackCard
    width: parent.width
    title: "FALLBACK"
    description: "Default for unconfigured displays"

    property var fallbackConfig: DisplayService.getConfigForOutput("")

    Connections {
      target: DisplayService
      function onConfigEntriesChanged() {
        fallbackCard.fallbackConfig = DisplayService.getConfigForOutput("")
      }
    }

    Column {
      width: parent.width
      spacing: 0
      enabled: !DisplayService.pendingApply

      SettingRow {
        width: parent.width
        label: "DEFAULT SCALE"
        SelectDropdown {
          width: 140
          placeholder: "Scale..."
          items: DisplayService.getScaleOptions()
          textRole: "label"
          valueRole: "value"
          value: fallbackCard.fallbackConfig ? fallbackCard.fallbackConfig.scale : "1.0"
          onItemSelected: function(item) {
            var mode = fallbackCard.fallbackConfig ? fallbackCard.fallbackConfig.mode : "preferred"
            var pos = fallbackCard.fallbackConfig ? fallbackCard.fallbackConfig.position : "auto"
            DisplayService.updateMonitor("", mode, item.value, pos)
          }
        }
      }
    }
  }
}
