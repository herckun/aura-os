import QtQuick
import QtQuick.Layouts
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
          checked: AppearanceService.animationsEnabled
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
          checked: AppearanceService.transparencyEnabled
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
          checked: AppearanceService.blurEnabled
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
      items: [
        { name: "DEFAULT",  icon: "device-desktop", description: "Full desktop with bar and hot areas" },
        { name: "ZEN",     icon: "sun",            description: "Clean canvas — panels appear on demand" },
        { name: "FOCUS",   icon: "target",         description: "Productivity — simplified, distraction-free" },
        { name: "GAMING",  icon: "zap",            description: "Full-screen — minimal overlays" },
        { name: "THEATER", icon: "moon",           description: "Media-centric — large widgets, dark chrome" }
      ]
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
