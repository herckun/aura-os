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

  PageHeader { title: "APPEARANCE" }

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
    }
  }

  Card {
    width: parent.width
    title: "SHELL MODE"
    description: "Choose your desktop experience — sets layout, theme, and visual effects"

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
