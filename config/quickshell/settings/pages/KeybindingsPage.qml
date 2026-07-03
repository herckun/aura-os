import QtQuick
import QtQuick.Layouts
import "../../styles"
import "../../core"
import "../../services"
import "../../components"

Item {
  id: root
  width: parent.width
  implicitHeight: content.implicitHeight
  height: content.implicitHeight

  property string _editingId: ""
  property string _editMod: "SUPER"
  property string _editKey: ""
  property string _editDesc: ""
  property string _editActionType: "shell"
  property string _editAction: ""
  property var _editArgs: ({})
  property var _conflicts: []
  property string _searchQuery: ""
  property var _pendingSave: null
  property var _conflictToResolve: null

  Connections {
    target: KeybindingService
    function onBindingsChanged() { root._conflicts = KeybindingService.getConflicts() }
    function onLoadedChanged() { root._conflicts = KeybindingService.getConflicts() }
  }

  Component.onCompleted: {
    var _kb = KeybindingService
    if (_kb.loaded) root._conflicts = _kb.getConflicts()
  }

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

  function getActionLabel(b: var): string {
    var actionType = b.actionType || "custom"
    var action = b.action || ""

    if (actionType === "shell") {
      if (KeybindingService.shellActions) {
        for (var i = 0; i < KeybindingService.shellActions.length; i++) {
          if (KeybindingService.shellActions[i].id === action) return KeybindingService.shellActions[i].label
        }
      }
      return action
    }

    if (actionType === "hypr") {
      if (KeybindingService.hyprActions) {
        for (var i = 0; i < KeybindingService.hyprActions.length; i++) {
          if (KeybindingService.hyprActions[i].id === action) return KeybindingService.hyprActions[i].label
        }
      }
      return action
    }

    if (actionType === "global") {
      if (KeybindingService.globalActions) {
        for (var i = 0; i < KeybindingService.globalActions.length; i++) {
          if (KeybindingService.globalActions[i].id === action) return KeybindingService.globalActions[i].label
        }
      }
      return action
    }

    return action
  }

  function getActionTypeLabel(b: var): string {
    var actionType = b.actionType || "custom"
    if (actionType === "shell") return "SHELL"
    if (actionType === "hypr") return "HYPRLAND"
    if (actionType === "global") return "GLOBAL"
    return "CUSTOM"
  }

  function getArgsDisplay(b: var): string {
    if (!b.args || typeof b.args !== "object") return ""
    var parts = []
    var keys = Object.keys(b.args)
    for (var i = 0; i < keys.length; i++) {
      parts.push(keys[i] + ": " + b.args[keys[i]])
    }
    return parts.join(", ")
  }

  function getFilteredBindings(categoryId: string): var {
    var allBindings = KeybindingService.getBindingsByCategory(categoryId)
    if (!_searchQuery || _searchQuery.length === 0) return allBindings

    var query = _searchQuery.toLowerCase()
    var filtered = []
    for (var i = 0; i < allBindings.length; i++) {
      var b = allBindings[i]
      var keyStr = friendlyKey(b.mod || "") + " " + friendlyKey(b.key || "")
      var desc = (b.description || "").toLowerCase()
      var action = getActionLabel(b).toLowerCase()

      if (keyStr.toLowerCase().includes(query) || desc.includes(query) || action.includes(query)) {
        filtered.push(b)
      }
    }
    return filtered
  }

  function getHyprActionArgs(actionId: string): var {
    if (!KeybindingService.hyprActions) return []
    for (var i = 0; i < KeybindingService.hyprActions.length; i++) {
      if (KeybindingService.hyprActions[i].id === actionId) {
        return KeybindingService.hyprActions[i].args || []
      }
    }
    return []
  }

  function openEditModal(b: var): void {
    _editingId = b.id
    _editMod = b.mod || "SUPER"
    _editKey = b.key || ""
    _editDesc = b.description || ""
    _editActionType = b.actionType || "custom"
    _editAction = b.action || ""
    _editArgs = b.args || ({})
    editModal.openDialog()
  }

  function checkAndSave(): void {
    var binding = {
      id: root._editingId,
      mod: root._editMod,
      key: root._editKey,
      description: root._editDesc,
      actionType: root._editActionType,
      action: root._editAction,
      args: root._editArgs
    }

    var conflicts = []
    for (var i = 0; i < KeybindingService.bindings.length; i++) {
      var b = KeybindingService.bindings[i]
      if (b.id === binding.id) continue
      if (b.mod === binding.mod && b.key === binding.key && binding.key !== "") {
        conflicts.push(b)
      }
    }

    if (conflicts.length > 0) {
      root._pendingSave = binding
      root._conflictToResolve = conflicts
      conflictModal.openDialog()
    } else {
      saveBinding(binding)
    }
  }

  function saveBinding(binding: var): void {
    if (binding.id === "" || root._editingId === "") {
      var id = binding.description.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "")
      if (!id) id = "custom-" + Date.now()
      binding.id = id
      binding.category = "system"
      KeybindingService.addCustomBinding(binding)
    } else {
      KeybindingService.updateBinding(binding.id, binding)
    }
  }

  function resolveConflictKeepNew(): void {
    if (root._conflictToResolve) {
      for (var i = 0; i < root._conflictToResolve.length; i++) {
        KeybindingService.removeBinding(root._conflictToResolve[i].id)
      }
    }
    if (root._pendingSave) {
      saveBinding(root._pendingSave)
    }
    root._pendingSave = null
    root._conflictToResolve = null
  }

  function resolveConflictKeepOld(): void {
    root._pendingSave = null
    root._conflictToResolve = null
  }

  Column {
    id: content
    width: parent.width
    spacing: Theme.spaceLg

    PageHeader { title: "KEYBINDINGS" }

    // ── Top bar with search ─────────────────────────────────────
    Card {
      width: parent.width

      Column {
        width: parent.width
        spacing: Theme.spaceMd

        RowLayout {
          width: parent.width
          spacing: Theme.spaceMd

          Column {
            Layout.fillWidth: true
            spacing: Theme.spaceXxs

            Text {
              text: (KeybindingService.loaded ? KeybindingService.bindings.length : 0) + " KEYBINDINGS"
              color: Theme.textPrimary
              font.pixelSize: Theme.fontSizeLabel
              font.family: Theme.fontFamilyMono
              font.weight: Font.Bold
              font.letterSpacing: 0.06
            }

            Text {
              text: _conflicts.length > 0
                ? _conflicts.length + " conflict(s) detected"
                : "All keybindings are valid"
              color: _conflicts.length > 0 ? Theme.warning : Theme.success
              font.pixelSize: Theme.fontSizeMicro
              font.family: Theme.fontFamilyMono
            }
          }

          Button {
            text: "RESET"
            size: "sm"
            shape: "link"
            icon: "arrow-clockwise"
            onClicked: KeybindingService.resetToDefaults()
          }

          Button {
            text: "ADD BINDING"
            size: "sm"
            icon: "plus"
            onClicked: {
              root._editingId = ""
              root._editMod = "SUPER"
              root._editKey = ""
              root._editDesc = ""
              root._editActionType = "shell"
              root._editAction = ""
              root._editArgs = ({})
              editModal.openDialog()
            }
          }
        }

        Input {
          id: searchInput
          width: parent.width
          placeholder: "Search by key, description, or action..."
          iconName: "search"
          onTextChanged: root._searchQuery = text
        }
      }
    }

    // ── Conflict warnings ────────────────────────────────────────
    Column {
      width: parent.width
      spacing: Theme.spaceSm
      visible: _conflicts.length > 0

      Repeater {
        model: _conflicts

        Surface {
          width: parent.width
          height: conflictRow.implicitHeight + Theme.spaceMd * 2
          radius: Theme.radiusMedium
          color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.08)
          border.color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.3)

          RowLayout {
            id: conflictRow
            anchors.fill: parent
            anchors.margins: Theme.spaceMd
            spacing: Theme.spaceSm

            Icon {
              source: Icons.get("alert")
              size: 14
              color: Theme.warning
            }

            Text {
              text: "CONFLICT"
              color: Theme.warning
              font.pixelSize: Theme.fontSizeMicro
              font.family: Theme.fontFamilyMono
              font.weight: Font.Bold
              font.letterSpacing: 0.06
            }

            Text {
              text: modelData.key.replace("|", " + ") + " is bound to multiple actions"
              color: Theme.textSecondary
              font.pixelSize: Theme.fontSizeCaption
              font.family: Theme.fontFamily
              Layout.fillWidth: true
            }
          }
        }
      }
    }

    // ── Category sections ────────────────────────────────────────
    Repeater {
      model: KeybindingService.categories

      delegate: Column {
        width: parent.width
        spacing: Theme.spaceSm

        property var category: modelData
        property var catBindings: root.getFilteredBindings(category.id)

        visible: catBindings.length > 0

        Card {
          width: parent.width
          title: category.label
          description: catBindings.length + " binding" + (catBindings.length !== 1 ? "s" : "")

          Column {
            width: parent.width
            spacing: 0

            Repeater {
              model: catBindings

              delegate: KeybindingRow {
                width: parent.width
                binding: modelData
                actionLabel: root.getActionLabel(modelData)
                actionTypeLabel: root.getActionTypeLabel(modelData)
                argsDisplay: root.getArgsDisplay(modelData)
                isCustom: modelData.custom || false
                isReadonly: modelData.readonly || false
                onEditClicked: root.openEditModal(modelData)
                onDeleteClicked: KeybindingService.removeBinding(modelData.id)
              }
            }
          }
        }
      }
    }
  }

  // ── Edit/Add Modal ─────────────────────────────────────────────
  Modal {
    id: editModal
    title: root._editingId === "" ? "ADD KEYBINDING" : "EDIT KEYBINDING"
    description: root._editingId === "" ? "Create a new keybinding" : "Modify " + root._editingId
    iconName: "keyboard"
    confirmLabel: root._editingId === "" ? "ADD" : "SAVE"
    confirmIcon: "check"
    confirmVariant: "accent"
    dismissOnBackdrop: false

    content: [
      Column {
        width: parent.width
        spacing: Theme.spaceSm

        Text {
          text: "KEY COMBINATION"
          color: Theme.textSecondary
          font.pixelSize: Theme.fontSizeMicro
          font.family: Theme.fontFamilyMono
          font.letterSpacing: 0.06
        }

        Row {
          width: parent.width
          spacing: Theme.spaceSm

          Input {
            id: modInput
            width: parent.width * 0.5
            placeholder: "SUPER"
          }

          Input {
            id: keyInput
            width: parent.width * 0.5
            placeholder: "Return"
          }
        }
      },

      Column {
        width: parent.width
        spacing: Theme.spaceXs

        Text {
          text: "DESCRIPTION"
          color: Theme.textSecondary
          font.pixelSize: Theme.fontSizeMicro
          font.family: Theme.fontFamilyMono
          font.letterSpacing: 0.06
        }

        Input {
          id: descInput
          width: parent.width
          placeholder: "What this keybinding does"
        }
      },

      Column {
        width: parent.width
        spacing: Theme.spaceSm

        Text {
          text: "ACTION TYPE"
          color: Theme.textSecondary
          font.pixelSize: Theme.fontSizeMicro
          font.family: Theme.fontFamilyMono
          font.letterSpacing: 0.06
        }

        Row {
          width: parent.width
          spacing: Theme.spaceSm

          Repeater {
            model: [
              { label: "SHELL", value: "shell", icon: "terminal", desc: "QuickShell panels" },
              { label: "HYPRLAND", value: "hypr", icon: "layout-grid", desc: "Window management" },
              { label: "CUSTOM", value: "custom", icon: "code", desc: "Any command" }
            ]

            delegate: Surface {
              width: (parent.width - Theme.spaceSm * 2) / 3
              height: 60
              radius: Theme.radiusMedium
              color: root._editActionType === modelData.value
                ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.1)
                : Theme.backgroundTertiary
              border.color: root._editActionType === modelData.value ? Theme.accent : Theme.border

              Behavior on color {
                enabled: Theme.animationsEnabled
                ColorAnimation { duration: Theme.animationFast }
              }

              Column {
                anchors.centerIn: parent
                spacing: Theme.spaceXs

                Icon {
                  source: Icons.get(modelData.icon)
                  size: 16
                  color: root._editActionType === modelData.value ? Theme.accent : Theme.textSecondary
                  anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                  text: modelData.label
                  color: root._editActionType === modelData.value ? Theme.accent : Theme.textPrimary
                  font.pixelSize: Theme.fontSizeMicro
                  font.family: Theme.fontFamilyMono
                  font.weight: Font.Bold
                  font.letterSpacing: 0.06
                  anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                  text: modelData.desc
                  color: Theme.textDisabled
                  font.pixelSize: 9
                  font.family: Theme.fontFamilyMono
                  anchors.horizontalCenter: parent.horizontalCenter
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root._editActionType = modelData.value
                  root._editAction = ""
                  root._editArgs = ({})
                }
              }
            }
          }
        }
      },

      Column {
        width: parent.width
        spacing: Theme.spaceXs
        visible: root._editActionType === "shell"

        Text {
          text: "ACTION"
          color: Theme.textSecondary
          font.pixelSize: Theme.fontSizeMicro
          font.family: Theme.fontFamilyMono
          font.letterSpacing: 0.06
        }

        SelectDropdown {
          width: parent.width
          placeholder: "Select a shell action..."
          items: KeybindingService.shellActions || []
          textRole: "label"
          valueRole: "id"
          value: root._editAction
          onItemSelected: function(item) {
            root._editAction = item.id
            root._editArgs = ({})
          }
        }
      },

      Column {
        width: parent.width
        spacing: Theme.spaceXs
        visible: root._editActionType === "hypr"

        Text {
          text: "ACTION"
          color: Theme.textSecondary
          font.pixelSize: Theme.fontSizeMicro
          font.family: Theme.fontFamilyMono
          font.letterSpacing: 0.06
        }

        SelectDropdown {
          width: parent.width
          placeholder: "Select a Hyprland action..."
          items: KeybindingService.hyprActions || []
          textRole: "label"
          valueRole: "id"
          value: root._editAction
          onItemSelected: function(item) {
            root._editAction = item.id
            root._editArgs = ({})
          }
        }
      },

      Column {
        width: parent.width
        spacing: Theme.spaceSm
        visible: root._editActionType === "hypr" && _getHyprArgs().length > 0

        function _getHyprArgs(): var {
          return root.getHyprActionArgs(root._editAction)
        }

        Text {
          text: "PARAMETERS"
          color: Theme.textSecondary
          font.pixelSize: Theme.fontSizeMicro
          font.family: Theme.fontFamilyMono
          font.letterSpacing: 0.06
        }

        Repeater {
          model: parent._getHyprArgs()

          Column {
            width: parent.width
            spacing: Theme.spaceXs
            property var argDef: modelData

            Text {
              text: argDef.label || argDef.key
              color: Theme.textSecondary
              font.pixelSize: Theme.fontSizeMicro
              font.family: Theme.fontFamilyMono
            }

            Input {
              id: argInput
              width: parent.width
              placeholder: argDef.type === "number" ? "1-10" : argDef.label
              property string _argKey: argDef.key || ""

              Component.onCompleted: initTimer.start()

              Timer {
                id: initTimer
                interval: 50
                repeat: false
                onTriggered: {
                  var val = root._editArgs[argInput._argKey]
                  if (val !== undefined && val !== null && val !== "") {
                    argInput.input.text = String(val)
                  }
                }
              }

              onTextChanged: {
                var args = Object.assign({}, root._editArgs)
                if (argDef.type === "number") {
                  args[argInput._argKey] = parseInt(text) || text
                } else {
                  args[argInput._argKey] = text
                }
                root._editArgs = args
              }
            }
          }
        }
      },

      Column {
        width: parent.width
        spacing: Theme.spaceXs
        visible: root._editActionType === "custom"

        Text {
          text: "COMMAND"
          color: Theme.textSecondary
          font.pixelSize: Theme.fontSizeMicro
          font.family: Theme.fontFamilyMono
          font.letterSpacing: 0.06
        }

        Input {
          id: customCmdInput
          width: parent.width
          placeholder: "kitty, nautilus, firefox, etc."
        }
      }
    ]

    onOpened: {
      modInput.input.text = root._editMod
      keyInput.input.text = root._editKey
      descInput.input.text = root._editDesc
      if (root._editActionType === "custom") {
        customCmdInput.input.text = root._editAction
      }
    }

    onConfirmed: {
      root._editMod = modInput.text
      root._editKey = keyInput.text
      root._editDesc = descInput.text

      if (root._editActionType === "custom") {
        root._editAction = customCmdInput.text
      }

      root.checkAndSave()
    }
  }

  // ── Conflict Resolution Modal ──────────────────────────────────
  Modal {
    id: conflictModal
    title: "KEYBINDING CONFLICT"
    description: "The key combination " + (root._pendingSave ? root._pendingSave.mod + " + " + root._pendingSave.key : "") + " is already bound to another action."
    iconName: "alert"
    confirmLabel: "KEEP NEW"
    confirmIcon: "check"
    confirmVariant: "accent"
    cancelLabel: "KEEP OLD"
    dismissOnBackdrop: false

    content: [
      Column {
        width: parent.width
        spacing: Theme.spaceMd

        Text {
          text: "Choose which binding to keep:"
          color: Theme.textSecondary
          font.pixelSize: Theme.fontSizeCaption
          font.family: Theme.fontFamily
        }

        Column {
          width: parent.width
          spacing: Theme.spaceSm

          Repeater {
            model: root._conflictToResolve || []

            Surface {
              width: parent.width
              height: conflictItemRow.implicitHeight + Theme.spaceMd * 2
              radius: Theme.radiusMedium
              level: 2
              border.color: Theme.border

              RowLayout {
                id: conflictItemRow
                anchors.fill: parent
                anchors.margins: Theme.spaceMd
                spacing: Theme.spaceSm

                Icon {
                  source: Icons.get("alert")
                  size: 14
                  color: Theme.warning
                }

                Column {
                  Layout.fillWidth: true
                  spacing: Theme.spaceXxs

                  Text {
                    text: modelData.description || modelData.id
                    color: Theme.textPrimary
                    font.pixelSize: Theme.fontSizeCaption
                    font.family: Theme.fontFamily
                    font.weight: Font.Medium
                  }

                  Text {
                    text: (modelData.actionType || "custom") + ": " + (modelData.action || "")
                    color: Theme.textDisabled
                    font.pixelSize: Theme.fontSizeMicro
                    font.family: Theme.fontFamilyMono
                  }
                }
              }
            }
          }
        }

        Surface {
          width: parent.width
          height: newItemRow.implicitHeight + Theme.spaceMd * 2
          radius: Theme.radiusMedium
          color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08)
          border.color: Theme.accent

          RowLayout {
            id: newItemRow
            anchors.fill: parent
            anchors.margins: Theme.spaceMd
            spacing: Theme.spaceSm

            Icon {
              source: Icons.get("plus")
              size: 14
              color: Theme.accent
            }

            Column {
              Layout.fillWidth: true
              spacing: Theme.spaceXxs

              Text {
                text: root._pendingSave ? (root._pendingSave.description || "New binding") : ""
                color: Theme.accent
                font.pixelSize: Theme.fontSizeCaption
                font.family: Theme.fontFamily
                font.weight: Font.Medium
              }

              Text {
                text: root._pendingSave ? ((root._pendingSave.actionType || "custom") + ": " + (root._pendingSave.action || "")) : ""
                color: Theme.textDisabled
                font.pixelSize: Theme.fontSizeMicro
                font.family: Theme.fontFamilyMono
              }
            }
          }
        }
      }
    ]

    onConfirmed: root.resolveConflictKeepNew()
    onRejected: root.resolveConflictKeepOld()
  }
}
