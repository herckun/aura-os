import QtQuick
import QtQuick.Layouts
import "../styles"
import "../core"

Item {
  id: root

  property var binding: null
  property string keyLabel: ""
  property string actionLabel: ""
  property string actionTypeLabel: ""
  property string argsDisplay: ""
  property bool isCustom: false
  property bool isReadonly: false

  signal editClicked()
  signal deleteClicked()

  height: 48

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

  Rectangle {
    anchors.fill: parent
    anchors.leftMargin: -Theme.spaceMd
    anchors.rightMargin: -Theme.spaceMd
    radius: Theme.radiusSmall
    color: hoverArea.containsMouse ? Theme.controlBackgroundHover : "transparent"

    Behavior on color {
      enabled: Theme.animationsEnabled
      ColorAnimation { duration: Theme.animationFast }
    }

    MouseArea {
      id: hoverArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: root.isReadonly ? Qt.ArrowCursor : Qt.PointingHandCursor
      onClicked: {
        if (!root.isReadonly) root.editClicked()
      }
    }
  }

  RowLayout {
    anchors.fill: parent
    spacing: Theme.spaceMd

    Rectangle {
      Layout.preferredWidth: 160
      Layout.preferredHeight: 28
      radius: Theme.radiusSmall
      color: Theme.backgroundTertiary
      border.width: Theme.borderWidth
      border.color: Theme.border

      Row {
        id: keyRow
        anchors.centerIn: parent
        spacing: Theme.space2

        Repeater {
          model: {
            if (!binding || !binding.mod) return []
            return binding.mod.split(/\s+/)
          }

          KeyCap {
            label: root.friendlyKey(modelData)
          }
        }

        Text {
          visible: binding && binding.mod && binding.key
          text: "+"
          color: Theme.textDisabled
          font.pixelSize: Theme.fontSizeMicro
          font.family: Theme.fontFamilyMono
          anchors.verticalCenter: parent.verticalCenter
        }

        KeyCap {
          visible: binding && !!binding.key
          label: root.friendlyKey(binding ? binding.key : "")
          accent: true
        }
      }
    }

    Column {
      Layout.fillWidth: true
      spacing: 2

      Row {
        spacing: Theme.spaceXs
        width: parent.width

        Text {
          text: root.actionLabel
          color: Theme.textPrimary
          font.pixelSize: Theme.fontSizeCaption
          font.family: Theme.fontFamily
          font.weight: Font.Medium
          elide: Text.ElideRight
        }

        Text {
          visible: root.argsDisplay !== ""
          text: "(" + root.argsDisplay + ")"
          color: Theme.textDisabled
          font.pixelSize: Theme.fontSizeMicro
          font.family: Theme.fontFamilyMono
        }
      }

      Row {
        spacing: Theme.spaceSm

        Rectangle {
          width: typeLabel.implicitWidth + Theme.spaceSm * 2
          height: 14
          radius: Theme.radiusXs
          color: {
            if (!binding) return Theme.backgroundTertiary
            return binding.actionType === "shell"
              ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)
              : binding.actionType === "hypr"
                ? Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.15)
                : binding.actionType === "global"
                  ? Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.15)
                  : Qt.rgba(Theme.textSecondary.r, Theme.textSecondary.g, Theme.textSecondary.b, 0.15)
          }

          Text {
            id: typeLabel
            anchors.centerIn: parent
            text: root.actionTypeLabel
            color: {
              if (!binding) return Theme.textSecondary
              return binding.actionType === "shell"
                ? Theme.accent
                : binding.actionType === "hypr"
                  ? Theme.success
                  : binding.actionType === "global"
                    ? Theme.warning
                    : Theme.textSecondary
            }
            font.pixelSize: Theme.fontSizeMicro
            font.family: Theme.fontFamilyMono
            font.weight: Font.Bold
            font.letterSpacing: 0.06
          }
        }

        Rectangle {
          visible: root.isCustom
          width: customLabel.implicitWidth + Theme.spaceSm * 2
          height: 14
          radius: Theme.radiusXs
          color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.15)

          Text {
            id: customLabel
            anchors.centerIn: parent
            text: "CUSTOM"
            color: Theme.warning
            font.pixelSize: Theme.fontSizeMicro
            font.family: Theme.fontFamilyMono
            font.weight: Font.Bold
            font.letterSpacing: 0.06
          }
        }
      }
    }

    Row {
      spacing: Theme.spaceXs

      Button {
        visible: !root.isReadonly
        icon: "pencil-simple"
        size: 24
        iconSize: 10
        shape: "circle"
        onClicked: root.editClicked()
      }

      Button {
        visible: root.isReadonly
        icon: "lock"
        size: 24
        iconSize: 10
        shape: "circle"
        enabled: false
      }

      Button {
        visible: root.isCustom
        icon: "trash"
        size: 24
        iconSize: 10
        shape: "circle"
        onClicked: root.deleteClicked()
      }
    }
  }

  Rectangle {
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: Theme.borderWidth
    color: Theme.border
  }
}
