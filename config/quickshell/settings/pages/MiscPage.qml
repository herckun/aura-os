import QtQuick
import QtQuick.Layouts
import "../../styles"
import "../../services"
import "../../components"

ColumnLayout {
  id: root
  spacing: Theme.spaceLg
  width: parent.width

  PageHeader { title: "MISC" }

  // ── Hot Areas ───────────────────────────────────────────────
  Card {
    Layout.fillWidth: true
    title: "HOT AREAS"
    description: "Trigger actions by moving cursor to screen edges"

    Column {
      width: parent.width
      spacing: 0

      Repeater {
        model: HotAreasService.areas

        Column {
          width: parent.width
          required property var modelData
          required property int index

          SettingRow {
            width: parent.width
            label: HotAreasService.actionLabels[modelData.action] || modelData.action.toUpperCase()
            description: modelData.position.replace(/-/g, " ").toUpperCase()
            Toggle {
              toggleWidth: 38
              toggleHeight: 20
              checked: HotAreasService.enabledMap[modelData.id] === true
              onToggled: (v) => HotAreasService.setEnabled(modelData.id, v)
            }
          }

          Divider { width: parent.width; visible: index < HotAreasService.areas.length - 1 }
        }
      }
    }
  }

  Item { Layout.fillHeight: true }
}
