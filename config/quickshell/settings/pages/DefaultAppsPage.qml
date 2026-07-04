pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../styles"
import "../../services"
import "../../components"

ColumnLayout {
  id: root
  spacing: Theme.spaceLg
  width: parent.width

  PageHeader { title: "DEFAULT APPS" }

  Card {
    Layout.fillWidth: true
    title: "DEFAULT APPLICATIONS"
    description: "Apps used by keybinds, launchers and shell actions"

    Column {
      width: parent.width
      spacing: 0

      Repeater {
        model: DefaultAppsService.categories

        Column {
          id: catRow
          width: parent.width
          required property var modelData
          required property int index

          readonly property var current: DefaultAppsService.loaded
            ? DefaultAppsService.appFor(catRow.modelData.id) : ({ id: "", name: "", exec: "" })
          readonly property var options: {
            var list = []
            var cands = DefaultAppsService.candidates[catRow.modelData.id] || []
            for (var i = 0; i < cands.length; i++) {
              list.push({ label: cands[i].name || cands[i].id, value: cands[i].id, app: cands[i] })
            }
            return list
          }

          SettingRow {
            width: parent.width
            label: catRow.modelData.label
            description: catRow.modelData.description

            SelectDropdown {
              width: 220
              items: catRow.options
              value: catRow.current.id || ""
              displayText: catRow.current.name || catRow.current.exec || "None detected"
              placeholder: "Select app..."
              onItemSelected: item => DefaultAppsService.setDefault(catRow.modelData.id, item.app)
            }
          }

          Divider { width: parent.width; visible: catRow.index < DefaultAppsService.categories.length - 1 }
        }
      }
    }
  }

  Item { Layout.fillHeight: true }
}
