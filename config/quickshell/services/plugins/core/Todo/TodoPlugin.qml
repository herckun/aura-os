pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../../styles"
import "../../../../components"
import "../../../../core"
import "../../../../services"

BasePlugin {
  id: root

  // ── Manifest ────────────────────────────────────────────────────
  pluginId: "todo"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Todo",
    description: "Task manager",
    icon: "todo",
    locations: ["overview"],
    overviewTab: { icon: "todo", label: "TODO", key: "2" },
    settings: []
  })

  // ── Public state ─────────────────────────────────────────────────

  // ── Internal state ───────────────────────────────────────────────

  // ── Signal handlers ──────────────────────────────────────────────

  // ── Public API ───────────────────────────────────────────────────

  // ── Helpers ──────────────────────────────────────────────────────

  // ── Timers ───────────────────────────────────────────────────────

  // ── Lifecycle ────────────────────────────────────────────────────

  // ── UI components ────────────────────────────────────────────────
  property Component overviewComponent: FocusScope {
    implicitHeight: col.childrenRect.height + Theme.spaceMd * 2

    Column {
      id: col
      anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceMd }
      spacing: Theme.spaceSm

      RowLayout {
        width: parent.width
        spacing: Theme.spaceSm

        SectionLabel { label: "Tasks"; Layout.alignment: Qt.AlignVCenter }

        Badge {
          text: TodoService.activeCount + " ACTIVE"
          variant: "default"
          size: "sm"
          visible: TodoService.activeCount > 0
        }

        Item { Layout.fillWidth: true }

        Button {
          shape: "link"
          text: "CLEAR DONE"
          visible: TodoService.tasks.length > 0
          onClicked: TodoService.clearDone()
        }
      }

      Input {
        id: todoInput
        width: parent.width
        iconName: "plus"
        placeholder: "Add task…"
        showClearButton: false
        focus: true
        onAccepted: {
          if (todoInput.text.trim() !== "") {
            TodoService.add(todoInput.text.trim())
            todoInput.input.text = ""
          }
        }
      }

      Flickable {
        width: parent.width
        height: Math.min(todoCol.implicitHeight + Theme.spaceXs * 2, 260)
        contentHeight: todoCol.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: todoCol
          width: parent.width
          spacing: Theme.spaceXs

          Repeater {
            model: TodoService.tasks

            delegate: TodoItem {
              required property var modelData
              width: todoCol.width
              taskId: modelData.id
              taskText: modelData.text
              taskDone: modelData.done
              showDelete: true
              onToggled: TodoService.toggle(modelData.id)
              onRemoved: TodoService.remove(modelData.id)
            }
          }

          Item {
            width: parent.width
            height: 150
            visible: TodoService.tasks.length === 0

            EmptyState {
              anchors.centerIn: parent
              width: parent.width
              icon: "todo"
              stateText: "No tasks yet"
              description: "Add one above to get started"
            }
          }
        }
      }
    }
  }
}
