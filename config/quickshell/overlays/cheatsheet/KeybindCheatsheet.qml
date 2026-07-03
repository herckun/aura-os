import QtQuick
import "../../styles"
import "../../components"
import "../../services"

OverlayPanel {
  id: cheatsheet

  framed: true
  panelWidth: 680

  readonly property var keyLabels: ({
    "XF86AudioRaiseVolume": "Vol Up",
    "XF86AudioLowerVolume": "Vol Down",
    "XF86AudioMute": "Mute",
    "XF86AudioMicMute": "Mic Mute",
    "XF86MonBrightnessUp": "Bright Up",
    "XF86MonBrightnessDown": "Bright Down",
    "Return": "Enter",
    "space": "Space",
    "Escape": "Esc",
    "backslash": "\\",
    "slash": "/",
    "period": ".",
    "comma": ",",
    "Up": "↑",
    "Down": "↓",
    "Left": "←",
    "Right": "→"
  })

  function friendlyKey(key: string): string {
    return keyLabels[key] || key
  }

  readonly property var sections: {
    var result = []
    for (var i = 0; i < KeybindingService.categories.length; i++) {
      var cat = KeybindingService.categories[i]
      var catBindings = KeybindingService.getBindingsByCategory(cat.id)
      if (catBindings.length === 0) continue

      var binds = []
      for (var j = 0; j < catBindings.length; j++) {
        var b = catBindings[j]
        var mod = (b.mod || "SUPER").replace(/SUPER/g, "Super").replace(/SHIFT/g, "Shift").replace(/CTRL/g, "Ctrl").replace(/ALT/g, "Alt").trim().replace(/[\s+]+/g, "+")
        binds.push({
          mod: mod,
          key: friendlyKey(b.key || ""),
          desc: b.description || b.id
        })
      }

      result.push({
        title: cat.label,
        binds: binds
      })
    }
    return result
  }

  header: Item {
    width: parent.width
    height: cheatTitle.implicitHeight

    Text {
      id: cheatTitle
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: "KEYBINDS"
      color: Theme.textDisplay
      font.pixelSize: Theme.fontSizeHeading
      font.family: Theme.fontFamilyMono
      font.weight: Font.Bold
      font.letterSpacing: 0.08
    }

    Text {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: "Super + /"
      color: Theme.textDisabled
      font.pixelSize: Theme.fontSizeCaption
      font.family: Theme.fontFamilyMono
    }
  }

  content: Flickable {
    width: parent.width
    height: Math.min(sectionsCol.implicitHeight, (cheatsheet.screen ? cheatsheet.screen.height : 900) * 0.65)
    contentHeight: sectionsCol.implicitHeight
    boundsBehavior: Flickable.StopAtBounds
    clip: true
    interactive: contentHeight > height

    Column {
      id: sectionsCol
      width: parent.width
      spacing: Theme.spaceLg

      Repeater {
        model: cheatsheet.sections

        Column {
          width: parent.width
          spacing: Theme.spaceSm

          SectionHeader { text: modelData.title }

          Grid {
            id: bindGrid
            width: parent.width
            columns: 2
            columnSpacing: Theme.spaceXl
            rowSpacing: Theme.spaceSm

            Repeater {
              model: modelData.binds

              KeyBinding {
                width: (bindGrid.width - Theme.spaceXl) / 2
                mod: modelData.mod
                key: modelData.key
                desc: modelData.desc
              }
            }
          }
        }
      }
    }
  }
}
