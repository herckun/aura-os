import QtQuick
import QtQuick.Layouts
import "../../../core"
import "../../../styles"
import "../../../services"
import "../../../components"

Surface {
  id: root

  property var plugin: null
  property string location: ""

  signal closed()

  readonly property bool pluginEnabled: plugin && PluginService.isPluginEnabledForLocation(plugin.id, location)
  readonly property bool hasSettings: !!(plugin && plugin.manifest && plugin.manifest.settings && plugin.manifest.settings.length > 0)

  width: parent ? parent.width : 0
  height: detailCol.implicitHeight + Theme.spaceMd * 2
  radius: Theme.radiusMedium
  level: 2

  Column {
    id: detailCol
    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceMd }
    spacing: Theme.spaceSm

    RowLayout {
      width: parent.width
      spacing: Theme.spaceSm

      Rectangle {
        Layout.preferredWidth: 36
        Layout.preferredHeight: 36
        radius: Theme.radiusSmall
        color: root.pluginEnabled ? Theme.accent : Theme.controlBackground

        Icon {
          anchors.centerIn: parent
          source: Icons.get(root.plugin?.manifest?.icon || "cpu")
          size: 18
          color: root.pluginEnabled ? Theme.contrastTextColor(Theme.accent) : Theme.textDisabled
        }
      }

      Column {
        Layout.fillWidth: true
        spacing: Theme.spaceXxs

        Text {
          width: parent.width
          text: (root.plugin?.manifest?.name || "").toUpperCase()
          color: Theme.textDisplay
          font.pixelSize: Theme.fontSizeLabel
          font.family: Theme.fontFamilyMono
          font.weight: Font.Bold
          font.letterSpacing: 0.08
          elide: Text.ElideRight
        }

        Text {
          width: parent.width
          text: root.plugin?.manifest?.description || ""
          color: Theme.textDisabled
          font.pixelSize: Theme.fontSizeMicro
          font.family: Theme.fontFamilyMono
          elide: Text.ElideRight
          visible: text !== ""
        }
      }

      Badge {
        text: root.location === "controlcenter_row" ? "CONTROL CENTER"
            : root.location === "controlcenter_toggle" ? "QUICK TOGGLES"
            : root.location.replace(/_/g, " ").toUpperCase()
        size: "sm"
        visible: root.location !== ""
        bgColor: Theme.backgroundTertiary
        textColor: Theme.textSecondary
      }

      Toggle {
        toggleWidth: 38
        toggleHeight: 20
        checked: root.pluginEnabled
        onToggled: (v) => PluginService.setPluginEnabledForLocation(root.plugin.id, root.location, v)
      }

      Button {
        shape: "icon"
        width: 26; height: 26
        icon: "x"
        size: "xs"
        showBackground: false
        onClicked: root.closed()
      }
    }

    Divider {
      width: parent.width
      visible: root.hasSettings && root.pluginEnabled
    }

    PluginSettingEditors {
      width: parent.width
      plugin: root.plugin
      location: root.location
      visible: root.hasSettings && root.pluginEnabled
    }

    Text {
      text: root.hasSettings ? "ENABLE TO CONFIGURE" : "NO SETTINGS"
      color: Theme.textDisabled
      font.pixelSize: Theme.fontSizeMicro
      font.family: Theme.fontFamilyMono
      font.letterSpacing: 0.1
      visible: !root.pluginEnabled || !root.hasSettings
    }
  }
}
