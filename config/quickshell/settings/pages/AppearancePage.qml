import QtQuick
import QtQuick.Layouts
import "../../core"
import "../../styles"
import "../../services"
import "../../components"

Column {
  id: root
  spacing: Theme.spaceLg
  width: parent.width

  readonly property var _fontItems: {
    var out = [{ label: "THEME DEFAULT", value: "" }]
    var fams = Qt.fontFamilies()
    for (var i = 0; i < fams.length; i++) {
      if (fams[i].charAt(0) === ".") continue
      out.push({ label: fams[i], value: fams[i] })
    }
    return out
  }

  PageHeader { title: "APPEARANCE"; description: "Themes, fonts, effects and shell mode" }

  Card {
    width: parent.width
    title: "THEME"
    description: "Colors and fonts for the shell, terminal and apps"

    GridLayout {
      width: parent.width
      columns: 4
      columnSpacing: Theme.spaceSm
      rowSpacing: Theme.spaceSm

      Repeater {
        model: ThemeService.themes

        delegate: Rectangle {
          id: themeCard
          required property var modelData
          readonly property var _pc: modelData.colors || ({})
          readonly property bool selected: ThemeService.active === modelData.id
          Layout.fillWidth: true
          Layout.preferredHeight: 68
          radius: Theme.radiusMedium
          antialiasing: true
          color: themeCard._pc.background || "#000000"
          border.width: selected ? 2 : Theme.borderWidth
          border.color: selected ? Theme.accent : Theme.borderVisible

          Behavior on border.color { enabled: Theme.animationsEnabled; ColorAnimation { duration: Theme.animationFast } }

          Column {
            anchors.centerIn: parent
            spacing: Theme.spaceSm

            Row {
              spacing: Theme.spaceXs
              anchors.horizontalCenter: parent.horizontalCenter

              Repeater {
                model: [
                  themeCard._pc.backgroundTertiary || "#1A1A1A",
                  themeCard._pc.textSecondary || "#999999",
                  themeCard._pc.textPrimary || "#E8E8E8",
                  modelData.accent || "#D71921"
                ]

                Rectangle {
                  required property var modelData
                  width: 12; height: 12
                  radius: 6
                  antialiasing: true
                  color: modelData
                }
              }
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: (themeCard.modelData.name || themeCard.modelData.id).toUpperCase()
              color: themeCard._pc.textPrimary || "#E8E8E8"
              font.pixelSize: Theme.fontSizeMicro
              font.family: Theme.fontFamilyMono
              font.letterSpacing: 0.08
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: ThemeService.apply(themeCard.modelData.id)
          }
        }
      }
    }
  }

  Card {
    width: parent.width
    title: "ACCENT COLOR"
    description: "Primary signal color for the interface"

    Column {
      width: parent.width
      spacing: Theme.spaceMd

      GridLayout {
        width: parent.width
        columns: 6
        columnSpacing: Theme.spaceSm
        rowSpacing: Theme.spaceSm

        Repeater {
          model: Theme.accentColors

          delegate: ColorSwatch {
            Layout.fillWidth: true
            Layout.fillHeight: true
            swatchColor: modelData.color
            label: modelData.name
            selected: Theme.accentPure.toString().toUpperCase() === modelData.color.toUpperCase()
            onClicked: Theme.setAccent(modelData.color)
          }
        }
      }

      RowLayout {
        width: parent.width
        spacing: Theme.spaceSm

        Rectangle {
          width: 10; height: 10
          radius: Theme.radiusSmall
          antialiasing: true
          color: Theme.accentPure
        }

        Text {
          text: Theme.accentPure.toString().toUpperCase()
          color: Theme.textSecondary
          font.pixelSize: Theme.fontSizeCaption
          font.family: Theme.fontFamilyMono
          Layout.fillWidth: true
        }

        Badge {
          text: Theme.monochrome ? "MONO" : colorToName(Theme.accentPure)
          bgColor: Theme.monochrome ? Theme.textDisabled : Theme.accent
          textColor: Theme.monochrome ? Theme.background : Theme.background
          size: "sm"
        }
      }
    }
  }

  Card {
    width: parent.width
    title: "VISUAL EFFECTS"
    description: PerformanceService.batterySaver
                 ? "Locked while battery saver is active"
                 : "Switching shell mode applies its preset — manual changes are saved"

    Column {
      width: parent.width
      spacing: 0

      SettingRow {
        width: parent.width
        label: "MONOCHROME MODE"
        description: "Pure black and white interface"
        Toggle {
          toggleWidth: 38
          toggleHeight: 20
          checked: Theme.monochrome
          onToggled: (v) => Theme.setMonochrome(v)
        }
      }

      Divider { width: parent.width }

      SettingRow {
        width: parent.width
        label: "ANIMATIONS"
        description: "Smooth transitions and motion"
        Toggle {
          toggleWidth: 38
          toggleHeight: 20
          checked: Store.appearance.animations
          enabled: !AppearanceService.locked
          opacity: AppearanceService.locked ? 0.4 : 1
          onToggled: (v) => AppearanceService.setAnimations(v)
        }
      }

      Divider { width: parent.width }

      SettingRow {
        width: parent.width
        label: "TRANSPARENCY"
        description: "Glass effects for panels and terminal"
        Toggle {
          toggleWidth: 38
          toggleHeight: 20
          checked: Store.appearance.transparency
          enabled: !AppearanceService.locked
          opacity: AppearanceService.locked ? 0.4 : 1
          onToggled: (v) => AppearanceService.setTransparency(v)
        }
      }

      Divider { width: parent.width }

      SettingRow {
        width: parent.width
        label: "BLUR"
        description: "Background blur under panels"
        Toggle {
          toggleWidth: 38
          toggleHeight: 20
          checked: Store.appearance.blur
          enabled: !AppearanceService.locked
          opacity: AppearanceService.locked ? 0.4 : 1
          onToggled: (v) => AppearanceService.setBlur(v)
        }
      }

      Item {
        width: parent.width
        height: Theme.spaceSm
        visible: Store.appearance.blur
      }

      SliderControl {
        width: parent.width
        visible: Store.appearance.blur
        label: "BLUR AMOUNT"
        from: 1
        to: 10
        stepSize: 1
        displayMin: 1
        displayMax: 10
        value: Store.appearance.blurAmount
        onMoved: (v) => AppearanceService.setBlurAmount(v)
      }
    }
  }

  Card {
    width: parent.width
    title: "TYPOGRAPHY"
    description: "Fonts and text size across the shell"

    Column {
      width: parent.width
      spacing: Theme.spaceMd

      Repeater {
        model: [
          { key: "ui", label: "UI FONT", current: () => Theme.fontFamily, stored: () => Store.appearance.fontUi },
          { key: "display", label: "DISPLAY FONT", current: () => Theme.fontFamilyDisplay, stored: () => Store.appearance.fontDisplay },
          { key: "mono", label: "MONO FONT", current: () => Theme.fontFamilyMono, stored: () => Store.appearance.fontMono }
        ]

        delegate: Column {
          id: fontRow
          required property var modelData
          width: parent.width
          spacing: Theme.spaceXs

          Text {
            text: fontRow.modelData.label
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSizeCaption
            font.family: Theme.fontFamilyMono
            font.letterSpacing: 0.08
          }

          SelectDropdown {
            width: parent.width
            placeholder: "THEME DEFAULT · " + fontRow.modelData.current()
            value: fontRow.modelData.stored()
            items: root._fontItems
            fontRole: "value"
            onItemSelected: (item) => AppearanceService.setFont(fontRow.modelData.key, item.value)
          }
        }
      }

      SliderControl {
        width: parent.width
        label: "FONT SIZE"
        from: 0.8
        to: 1.3
        stepSize: 0.05
        displayMin: 80
        displayMax: 130
        unit: "%"
        value: Store.appearance.fontScale
        onMoved: (v) => AppearanceService.setFontScale(v)
      }
    }
  }

  Card {
    width: parent.width
    title: "SHELL MODE"
    description: "How the desktop behaves — bar, spacing density, effects and timing"

    BentoSwitcher {
      width: parent.width
      columns: 3
      currentIndex: ModeService.mode
      items: [0, 1, 2, 3, 4].map((i) => ModeService.modeInfo[i])
      onSelected: (idx) => ModeService.setMode(idx)
    }
  }

  function colorToName(c: color): string {
    var names = Theme.predefinedAccents
    for (var i = 0; i < names.length; i++) {
      if (names[i].color.toUpperCase() === c.toString().toUpperCase())
        return names[i].name
    }
    
    return "CUSTOM"
  }
}
