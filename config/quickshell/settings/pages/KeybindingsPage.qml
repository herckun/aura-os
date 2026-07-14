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
  property string _validationError: ""
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

  function _isModifierKey(k: int): bool {
    return k === Qt.Key_Shift || k === Qt.Key_Control || k === Qt.Key_Meta ||
           k === Qt.Key_Alt || k === Qt.Key_AltGr || k === Qt.Key_Super_L || k === Qt.Key_Super_R
  }

  function _modsFromEvent(mods: int, pressedKey: int): string {
    var parts = []
    if ((mods & Qt.MetaModifier) || pressedKey === Qt.Key_Meta || pressedKey === Qt.Key_Super_L || pressedKey === Qt.Key_Super_R) parts.push("SUPER")
    if ((mods & Qt.ControlModifier) || pressedKey === Qt.Key_Control) parts.push("CTRL")
    if ((mods & Qt.AltModifier) || pressedKey === Qt.Key_Alt) parts.push("ALT")
    if ((mods & Qt.ShiftModifier) || pressedKey === Qt.Key_Shift) parts.push("SHIFT")
    return parts.join(" ")
  }

  function _qtKeyToHypr(event: var): string {
    var k = event.key
    if (k >= Qt.Key_A && k <= Qt.Key_Z) return String.fromCharCode(65 + (k - Qt.Key_A))
    if (k >= Qt.Key_0 && k <= Qt.Key_9) return String.fromCharCode(48 + (k - Qt.Key_0))
    if (k >= Qt.Key_F1 && k <= Qt.Key_F35) return "F" + (k - Qt.Key_F1 + 1)
    var m = {}
    m[Qt.Key_Return] = "Return"
    m[Qt.Key_Enter] = "Return"
    m[Qt.Key_Space] = "space"
    m[Qt.Key_Tab] = "Tab"
    m[Qt.Key_Backspace] = "BackSpace"
    m[Qt.Key_Delete] = "Delete"
    m[Qt.Key_Insert] = "Insert"
    m[Qt.Key_Home] = "Home"
    m[Qt.Key_End] = "End"
    m[Qt.Key_PageUp] = "Prior"
    m[Qt.Key_PageDown] = "Next"
    m[Qt.Key_Up] = "Up"
    m[Qt.Key_Down] = "Down"
    m[Qt.Key_Left] = "Left"
    m[Qt.Key_Right] = "Right"
    m[Qt.Key_Comma] = "comma"
    m[Qt.Key_Period] = "period"
    m[Qt.Key_Slash] = "slash"
    m[Qt.Key_Backslash] = "backslash"
    m[Qt.Key_Minus] = "minus"
    m[Qt.Key_Equal] = "equal"
    m[Qt.Key_Semicolon] = "semicolon"
    m[Qt.Key_Apostrophe] = "apostrophe"
    m[Qt.Key_BracketLeft] = "bracketleft"
    m[Qt.Key_BracketRight] = "bracketright"
    m[Qt.Key_QuoteLeft] = "grave"
    m[Qt.Key_Print] = "Print"
    m[Qt.Key_VolumeUp] = "XF86AudioRaiseVolume"
    m[Qt.Key_VolumeDown] = "XF86AudioLowerVolume"
    m[Qt.Key_VolumeMute] = "XF86AudioMute"
    m[Qt.Key_MicMute] = "XF86AudioMicMute"
    m[Qt.Key_MonBrightnessUp] = "XF86MonBrightnessUp"
    m[Qt.Key_MonBrightnessDown] = "XF86MonBrightnessDown"
    m[Qt.Key_MediaPlay] = "XF86AudioPlay"
    m[Qt.Key_MediaTogglePlayPause] = "XF86AudioPlay"
    m[Qt.Key_MediaNext] = "XF86AudioNext"
    m[Qt.Key_MediaPrevious] = "XF86AudioPrev"
    if (m[k] !== undefined) return m[k]
    if (event.text && event.text.trim() !== "") return event.text
    return ""
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

    PageHeader { title: "KEYBINDINGS"; description: "Keyboard shortcuts and custom binds" }

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
          antialiasing: true
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
    closeOnConfirm: false

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
            width: (parent.width - parent.spacing * 2) * 0.45
            placeholder: "SUPER"
          }

          Input {
            id: keyInput
            width: (parent.width - parent.spacing * 2) * 0.45
            placeholder: "Return"
          }

          Button {
            shape: "icon"
            icon: "keyboard"
            tooltip: keyCapture.capturing ? "LISTENING..." : "RECORD SHORTCUT"
            active: keyCapture.capturing
            anchors.verticalCenter: parent.verticalCenter
            onClicked: keyCapture.capturing ? keyCapture.stop() : keyCapture.start()
          }
        }

        Surface {
          width: parent.width
          height: captureLabel.implicitHeight + Theme.spaceSm * 2
          radius: Theme.radiusSmall
          antialiasing: true
          visible: keyCapture.capturing
          color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08)
          border.color: Theme.accent

          Text {
            id: captureLabel
            anchors.centerIn: parent
            text: keyCapture.heldMods !== ""
              ? keyCapture.heldMods + " + ..."
              : "PRESS A KEY COMBINATION — ESC TO CANCEL"
            color: Theme.accent
            font.pixelSize: Theme.fontSizeCaption
            font.family: Theme.fontFamilyMono
            font.letterSpacing: 0.06
          }
        }

        Item {
          id: keyCapture

          property bool capturing: false
          property string heldMods: ""

          function start(): void {
            capturing = true
            heldMods = ""
            forceActiveFocus()
            KeybindingService.beginCapture()
          }

          function stop(): void {
            capturing = false
            heldMods = ""
            KeybindingService.endCapture()
          }

          Keys.onPressed: function(event) {
            if (!keyCapture.capturing) return
            event.accepted = true
            if (event.key === Qt.Key_Escape) {
              keyCapture.stop()
              return
            }
            if (root._isModifierKey(event.key)) {
              keyCapture.heldMods = root._modsFromEvent(event.modifiers, event.key)
              return
            }
            var keyName = root._qtKeyToHypr(event)
            if (keyName === "") return
            modInput.input.text = root._modsFromEvent(event.modifiers, 0)
            keyInput.input.text = keyName
            keyCapture.stop()
          }

          Keys.onReleased: function(event) {
            if (!keyCapture.capturing) return
            event.accepted = true
            if (root._isModifierKey(event.key)) {
              keyCapture.heldMods = root._modsFromEvent(event.modifiers, 0)
            }
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

        BentoSwitcher {
          width: parent.width
          columns: 3
          cellHeight: 64
          currentIndex: root._editActionType === "shell" ? 0 : root._editActionType === "hypr" ? 1 : 2
          items: [
            { name: "SHELL", icon: "terminal", description: "QuickShell panels" },
            { name: "HYPRLAND", icon: "layout-grid", description: "Window management" },
            { name: "CUSTOM", icon: "code", description: "Any command" }
          ]
          onSelected: function(index) {
            root._editActionType = ["shell", "hypr", "custom"][index]
            root._editAction = ""
            root._editArgs = ({})
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

      Text {
        width: parent.width
        text: root._validationError
        color: Theme.error
        font.pixelSize: Theme.fontSizeCaption
        font.family: Theme.fontFamilyMono
        wrapMode: Text.WordWrap
        visible: root._validationError !== ""
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
      keyCapture.stop()
      root._validationError = ""
      modInput.input.text = root._editMod
      keyInput.input.text = root._editKey
      descInput.input.text = root._editDesc
      if (root._editActionType === "custom") {
        customCmdInput.input.text = root._editAction
      }
    }

    onClosed: {
      keyCapture.stop()
      root._validationError = ""
    }

    onConfirmed: {
      root._editMod = modInput.text
      root._editKey = keyInput.text
      root._editDesc = descInput.text

      if (root._editActionType === "custom") {
        root._editAction = customCmdInput.text
      }

      var err = KeybindingService.validateBinding({
        mod: root._editMod,
        key: root._editKey,
        description: root._editDesc,
        actionType: root._editActionType,
        action: root._editAction,
        args: root._editArgs
      })
      if (err !== "") {
        root._validationError = err
        return
      }
      root._validationError = ""
      editModal.open = false
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
              antialiasing: true
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
          antialiasing: true
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
