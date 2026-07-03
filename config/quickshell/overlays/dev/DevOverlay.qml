import QtQuick
import "../../styles"
import "../../components"

OverlayPanel {
  id: devOverlay

  framed: true
  panelWidth: 800

  header: Item {
    width: parent.width
    height: devTitle.implicitHeight

    Text {
      id: devTitle
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: "DEV OVERLAY"
      color: Theme.textDisplay
      font.pixelSize: Theme.fontSizeTitle
      font.family: Theme.fontFamilyMono
      font.weight: Font.Bold
      font.letterSpacing: 0.08
    }

    Text {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: "Super + \\"
      color: Theme.textDisabled
      font.pixelSize: Theme.fontSizeCaption
      font.family: Theme.fontFamilyMono
    }
  }

  content: Flickable {
    width: parent.width
    height: Math.min(bodyRow.implicitHeight, (devOverlay.screen ? devOverlay.screen.height : 900) * 0.72)
    contentHeight: bodyRow.implicitHeight
    boundsBehavior: Flickable.StopAtBounds
    clip: true
    interactive: contentHeight > height

    Row {
      id: bodyRow
      width: parent.width
      spacing: Theme.spaceLg

      Column {
        width: (parent.width - Theme.spaceLg) / 2
        spacing: Theme.spaceLg

        // ── Buttons ──
        Column {
          width: parent.width
          spacing: Theme.spaceSm

          SectionHeader { text: "BUTTONS" }

          Row {
            spacing: Theme.spaceSm
            Button { text: "XS"; size: "xs" }
            Button { text: "SM"; size: "sm" }
            Button { text: "MD"; size: "md" }
            Button { text: "LG"; size: "lg" }
            Button { text: "XL"; size: "xl" }
          }

          Row {
            spacing: Theme.spaceSm
            Button { text: "DEFAULT"; size: "sm" }
            Button { text: "ACCENT"; size: "sm"; variant: "accent" }
            Button { text: "BUSY"; size: "sm"; busy: true }
          }

          Row {
            spacing: Theme.spaceSm
            Button { shape: "circle"; icon: "settings"; size: 28 }
            Button { shape: "circle"; icon: "settings"; size: 28; active: true }
            Button { shape: "circle"; icon: "settings"; size: 28; busy: true }
            Button { shape: "icon"; icon: "copy"; size: 28 }
            Button { shape: "link"; text: "LINK" }
          }

          Row {
            spacing: Theme.spaceSm
            Button { shape: "tile"; text: "WIFI"; icon: "wifi" }
            Button { shape: "tile"; text: "ACTIVE"; icon: "wifi"; active: true }
            Button { shape: "tile"; text: "ACCENT"; icon: "wifi"; variant: "accent" }
          }
        }

        // ── Badges ──
        Column {
          width: parent.width
          spacing: Theme.spaceSm

          SectionHeader { text: "BADGES" }

          Row {
            spacing: Theme.spaceSm
            Badge { text: "XS"; size: "xs" }
            Badge { text: "SM"; size: "sm" }
            Badge { text: "MD"; size: "md" }
            Badge { text: "LG"; size: "lg" }
            Badge { text: "ACCENT"; variant: "accent" }
          }
        }

        // ── Toggle ──
        Column {
          width: parent.width
          spacing: Theme.spaceSm

          SectionHeader { text: "TOGGLE" }

          Row {
            spacing: Theme.spaceMd
            Toggle { checked: true }
            Toggle { checked: false }
            Toggle { checked: true; enabled: false }
          }
        }

        // ── Checkbox ──
        Column {
          width: parent.width
          spacing: Theme.spaceSm

          SectionHeader { text: "CHECKBOX" }

          Row {
            spacing: Theme.spaceMd
            Checkbox { checked: true }
            Checkbox { checked: false }
            Checkbox { checked: true; variant: "success" }
            Checkbox { checked: true; variant: "warning" }
            Checkbox { checked: true; variant: "error" }
          }
        }

        // ── Spinner ──
        Column {
          width: parent.width
          spacing: Theme.spaceSm

          SectionHeader { text: "SPINNER" }

          Row {
            spacing: Theme.spaceXl
            Spinner { spinnerSize: 16; spinnerColor: Theme.accent }
            Spinner { spinnerSize: 24; spinnerColor: Theme.accent }
            Spinner { spinnerSize: 32; spinnerColor: Theme.accent }
            Spinner { spinnerSize: 48; spinnerColor: Theme.textPrimary }
          }
        }

        // ── Progress ──
        Column {
          width: parent.width
          spacing: Theme.spaceSm

          SectionHeader { text: "PROGRESS" }

          Column {
            width: parent.width
            spacing: Theme.spaceXs
            ProgressBar { width: parent.width; value: 0.25; barColor: Theme.accent }
            ProgressBar { width: parent.width; value: 0.5; barColor: Theme.warning }
            ProgressBar { width: parent.width; value: 0.85; barColor: Theme.error }
          }
        }

        // ── Colors ──
        Column {
          width: parent.width
          spacing: Theme.spaceSm

          SectionHeader { text: "COLORS" }

          Grid {
            columns: 4
            spacing: Theme.spaceSm

            Repeater {
              model: [
                { name: "accent", color: Theme.accent },
                { name: "success", color: Theme.success },
                { name: "warning", color: Theme.warning },
                { name: "error", color: Theme.error },
                { name: "text", color: Theme.textPrimary },
                { name: "2nd", color: Theme.textSecondary },
                { name: "disabled", color: Theme.textDisabled },
                { name: "bg", color: Theme.background }
              ]

              Column {
                spacing: Theme.spaceXs
                Rectangle { width: 32; height: 32; radius: Theme.radiusSmall; color: modelData.color; border.width: 1; border.color: Theme.border }
                Text { text: modelData.name; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; anchors.horizontalCenter: parent.horizontalCenter }
              }
            }
          }
        }
      }

      Column {
        width: (parent.width - Theme.spaceLg) / 2
        spacing: Theme.spaceLg

        // ── Slider ──
        Column {
          width: parent.width
          spacing: Theme.spaceSm

          SectionHeader { text: "SLIDER" }

          Column {
            width: parent.width
            spacing: Theme.spaceSm
            Slider { width: parent.width; value: 0.3; accentColor: Theme.accent }
            Slider { width: parent.width; value: 0.6; accentColor: Theme.success }
            Slider { width: parent.width; value: 0.8; accentColor: Theme.warning }
          }
        }

        // ── Stepper ──
        Column {
          width: parent.width
          spacing: Theme.spaceSm

          SectionHeader { text: "STEPPER" }

          Column {
            width: parent.width
            spacing: Theme.spaceSm
            StepperControl { value: 50; minValue: 0; maxValue: 100; unit: "%" }
            StepperControl { value: 8; minValue: 1; maxValue: 16; label: "Volume"; variant: "success" }
          }
        }

        // ── Option Switcher ──
        Column {
          width: parent.width
          spacing: Theme.spaceSm

          SectionHeader { text: "OPTION SWITCHER" }

          OptionSwitcher {
            width: parent.width
            options: ["Default", "Relaxed", "Compact"]
            currentIndex: 0
          }
        }

        // ── Typography ──
        Column {
          width: parent.width
          spacing: Theme.spaceXs

          SectionHeader { text: "TYPOGRAPHY" }

          Text { text: "DisplayLarge 48"; color: Theme.textDisplay; font.pixelSize: Theme.fontSizeDisplayLarge; font.family: Theme.fontFamilyDisplay }
          Text { text: "Display 36"; color: Theme.textDisplay; font.pixelSize: Theme.fontSizeDisplay; font.family: Theme.fontFamilyDisplay }
          Text { text: "Heading 24"; color: Theme.textDisplay; font.pixelSize: Theme.fontSizeHeading; font.family: Theme.fontFamilyMono }
          Text { text: "Title2 20"; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeTitle2; font.family: Theme.fontFamilyMono }
          Text { text: "Title 16"; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeTitle; font.family: Theme.fontFamilyMono }
          Text { text: "Subhead 14"; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeSubhead; font.family: Theme.fontFamilyMono }
          Text { text: "Body 13"; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeBody; font.family: Theme.fontFamilyMono }
          Text { text: "Label 11"; color: Theme.textSecondary; font.pixelSize: Theme.fontSizeLabel; font.family: Theme.fontFamilyMono }
          Text { text: "Caption 10"; color: Theme.textSecondary; font.pixelSize: Theme.fontSizeCaption; font.family: Theme.fontFamilyMono }
          Text { text: "Micro 8"; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono }
        }

        // ── Radii ──
        Column {
          width: parent.width
          spacing: Theme.spaceSm

          SectionHeader { text: "RADII" }

          Row {
            spacing: Theme.spaceSm
            Repeater {
              model: [
                { name: "XS", r: Theme.radiusXs },
                { name: "SM", r: Theme.radiusSmall },
                { name: "MD", r: Theme.radiusMedium },
                { name: "LG", r: Theme.radiusLarge },
                { name: "XL", r: Theme.radiusXLarge },
                { name: "Pill", r: Theme.radiusPill }
              ]

              Column {
                spacing: Theme.spaceXs
                Rectangle { width: 32; height: 32; radius: modelData.r; color: Theme.controlBackground; border.width: 1; border.color: Theme.border }
                Text { text: modelData.name; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; anchors.horizontalCenter: parent.horizontalCenter }
              }
            }
          }
        }

        // ── Spacing ──
        Column {
          width: parent.width
          spacing: Theme.spaceSm

          SectionHeader { text: "SPACING" }

          Row {
            spacing: Theme.spaceSm
            Repeater {
              model: [
                { name: "xxs", s: Theme.spaceXxs },
                { name: "xs", s: Theme.spaceXs },
                { name: "sm", s: Theme.spaceSm },
                { name: "md", s: Theme.spaceMd },
                { name: "lg", s: Theme.spaceLg }
              ]

              Column {
                spacing: Theme.spaceXs
                Rectangle { width: modelData.s * 2; height: 16; radius: Theme.radiusSmall; color: Theme.accent; anchors.horizontalCenter: parent.horizontalCenter }
                Text { text: modelData.name; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; anchors.horizontalCenter: parent.horizontalCenter }
                Text { text: modelData.s; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; anchors.horizontalCenter: parent.horizontalCenter }
              }
            }
          }
        }

        // ── Control States ──
        Column {
          width: parent.width
          spacing: Theme.spaceSm

          SectionHeader { text: "CONTROL STATES" }

          Row {
            spacing: Theme.spaceSm
            Repeater {
              model: [
                { name: "Default", bg: Theme.controlBackground, bd: Theme.controlBorder },
                { name: "Hover", bg: Theme.controlBackgroundHover, bd: Theme.controlBorderHover },
                { name: "Pressed", bg: Theme.controlBackgroundPressed, bd: Theme.controlBorderPressed }
              ]

              Column {
                spacing: Theme.spaceXs
                Rectangle { width: 60; height: 32; radius: Theme.radiusSmall; color: modelData.bg; border.width: 1; border.color: modelData.bd; anchors.horizontalCenter: parent.horizontalCenter }
                Text { text: modelData.name; color: Theme.textDisabled; font.pixelSize: Theme.fontSizeMicro; font.family: Theme.fontFamilyMono; anchors.horizontalCenter: parent.horizontalCenter }
              }
            }
          }
        }

        // ── Style Info ──
        Column {
          width: parent.width
          spacing: Theme.spaceSm

          SectionHeader { text: "STYLE INFO" }

          Grid {
            columns: 2
            columnSpacing: Theme.spaceLg
            rowSpacing: Theme.spaceXs

            Text { text: "Style"; color: Theme.textSecondary; font.pixelSize: Theme.fontSizeCaption; font.family: Theme.fontFamilyMono }
            Text { text: Theme._styleKey; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeCaption; font.family: Theme.fontFamilyMono }

            Text { text: "Radius"; color: Theme.textSecondary; font.pixelSize: Theme.fontSizeCaption; font.family: Theme.fontFamilyMono }
            Text { text: Theme.radiusMedium; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeCaption; font.family: Theme.fontFamilyMono }

            Text { text: "Spacing"; color: Theme.textSecondary; font.pixelSize: Theme.fontSizeCaption; font.family: Theme.fontFamilyMono }
            Text { text: Theme.spaceMd; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeCaption; font.family: Theme.fontFamilyMono }

            Text { text: "Animations"; color: Theme.textSecondary; font.pixelSize: Theme.fontSizeCaption; font.family: Theme.fontFamilyMono }
            Text { text: Theme.animationsEnabled ? "ON" : "OFF"; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeCaption; font.family: Theme.fontFamilyMono }

            Text { text: "Transparency"; color: Theme.textSecondary; font.pixelSize: Theme.fontSizeCaption; font.family: Theme.fontFamilyMono }
            Text { text: Theme.transparencyEnabled ? "ON" : "OFF"; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeCaption; font.family: Theme.fontFamilyMono }

            Text { text: "Blur"; color: Theme.textSecondary; font.pixelSize: Theme.fontSizeCaption; font.family: Theme.fontFamilyMono }
            Text { text: Theme.blurEnabled ? "ON" : "OFF"; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeCaption; font.family: Theme.fontFamilyMono }
          }
        }
      }
    }
  }
}
