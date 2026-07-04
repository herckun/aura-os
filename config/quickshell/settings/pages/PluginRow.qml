import QtQuick
import QtQuick.Layouts
import "../../styles"
import "../../core"
import "../../services"
import "../../components"

Column {
  id: root

  property var plugin: null
  property string location: ""
  property bool enabled: false
  property bool expanded: false
  property int pluginIndex: 0
  property int count: 1
  property bool hasSettings: !!(plugin && plugin.manifest && plugin.manifest.settings && plugin.manifest.settings.length > 0)

  readonly property var _groupSections: (root.plugin && PluginService.loaded)
    ? PluginService.movableSections(root.plugin.id, root.location) : []
  readonly property var _sectionLabels: _groupSections.map(function(s) {
    var parts = s.split("_")
    return (parts[parts.length - 1] || s).charAt(0).toUpperCase()
  })
  readonly property int _currentSectionIndex: (root.plugin && PluginService.loaded)
    ? _groupSections.indexOf(PluginService.currentSection(root.plugin.id, root.location)) : -1

  signal toggleEnabled()
  signal toggleExpanded()
  signal moveUp()
  signal moveDown()

  width: parent ? parent.width : 0
  spacing: 0

  // ── Plugin row ────────────────────────────────────────
  Rectangle {
    width: root.width
    height: 52
    radius: Theme.radiusMedium
    color: rowHover.containsMouse ? Theme.controlBackgroundHover : Theme.backgroundSecondary
    border.width: Theme.borderWidth
    border.color: rowHover.containsMouse ? Theme.borderActive : Theme.border

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: Theme.spaceMd
      anchors.rightMargin: Theme.spaceSm
      spacing: Theme.spaceSm

      // ── Icon ──────────────────────────────────────
      Rectangle {
        Layout.preferredWidth: 32
        Layout.preferredHeight: 32
        radius: Theme.radiusSmall
        color: root.enabled ? Theme.accent : Theme.controlBackground

        Icon {
          anchors.centerIn: parent
          source: Icons.get(root.plugin?.manifest?.icon || "cpu")
          size: 16
          color: root.enabled ? Theme.contrastTextColor(Theme.accent) : Theme.textDisabled
        }
      }

      // ── Name + description ────────────────────────
      Column {
        Layout.fillWidth: true
        spacing: Theme.spaceXxs

        Text {
          width: parent.width
          text: (root.plugin?.manifest?.name || "").toUpperCase()
          color: root.enabled ? Theme.textPrimary : Theme.textSecondary
          font.pixelSize: Theme.fontSizeLabel
          font.family: Theme.fontFamilyMono
          font.weight: Font.Bold
          font.letterSpacing: 0.06
          elide: Text.ElideRight
          maximumLineCount: 1
        }

        Text {
          width: parent.width
          text: root.plugin?.manifest?.description || ""
          color: Theme.textDisabled
          font.pixelSize: Theme.fontSizeMicro
          font.family: Theme.fontFamilyMono
          elide: Text.ElideRight
          maximumLineCount: 1
          visible: text !== ""
        }
      }

      // ── Section mover (grouped locations, e.g. bar) ──
      OptionSwitcher {
        Layout.preferredWidth: root._groupSections.length * 26
        size: "xs"
        options: root._sectionLabels
        currentIndex: root._currentSectionIndex
        visible: root._groupSections.length > 1 && root.enabled
        onSelected: (i) => PluginService.movePluginToLocation(root.plugin.id, root._groupSections[i])
      }

      // ── Reorder buttons ───────────────────────────
      Row {
      spacing: Theme.space2
      visible: root.enabled

        Button {
          shape: "icon"
          width: 22; height: 22
          icon: "chevron.up"
          size: "xs"
          showBackground: false
          visible: root.pluginIndex > 0
          onClicked: root.moveUp()
        }

        Button {
          shape: "icon"
          width: 22; height: 22
          icon: "chevron.down"
          size: "xs"
          showBackground: false
          visible: root.pluginIndex < root.count - 1
          onClicked: root.moveDown()
        }
      }

      // ── Edit button ───────────────────────────────
      Button {
        shape: "icon"
        width: 28; height: 28
        icon: "edit"
        size: "xs"
        showBackground: false
        visible: root.hasSettings && root.enabled
        color: root.expanded ? Theme.accent : Theme.textDisabled
        onClicked: root.toggleExpanded()
      }

      // ── Toggle ────────────────────────────────────
      Toggle {
        checked: root.enabled
        onToggled: root.toggleEnabled()
      }
    }

    MouseArea {
      id: rowHover
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.NoButton
      z: -1
    }
  }

  // ── Settings panel (expands inline) ───────────────────
  Item {
    width: root.width
    height: (root.expanded && root.enabled && root.hasSettings) ? settingsCol.implicitHeight + Theme.spaceMd * 2 : 0
    clip: true

    Behavior on height { enabled: Theme.animationsEnabled; NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.InOutCubic } }

    Surface {
      anchors.fill: parent
      anchors.topMargin: Theme.spaceXs
      radius: Theme.radiusMedium
      level: 2

      Column {
        id: settingsCol
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceMd }
        spacing: 0

        Repeater {
          model: root.plugin?.manifest?.settings || []

          delegate: Loader {
            id: settingLoader
            width: settingsCol.width
            sourceComponent: {
              switch (modelData.type) {
                case "stepper": return stepperComp
                case "toggle": return toggleComp
                case "select": return selectComp
                case "text": return textComp
                default: null
              }
            }

            property var settingDef: modelData
            readonly property string _loc: settingDef.shared ? "" : root.location
            property real _value: PluginService.getPluginSetting(root.plugin.id, settingDef.key, _loc) ?? settingDef.default ?? 0
            property bool _boolValue: PluginService.getPluginSetting(root.plugin.id, settingDef.key, _loc) ?? settingDef.default ?? false
          }
        }
      }
    }

    Component {
      id: stepperComp
      Row {
        property real loaderValue: parent._value
        property string _loc: parent._loc
        width: settingsCol ? settingsCol.width : 0
        height: Theme.controlHeight + Theme.spaceSm
        spacing: Theme.spaceSm

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - Theme.spaceSm - sCtrl.width
          height: parent.height
          color: "transparent"

          Column {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: Theme.spaceSm }
            spacing: Theme.spaceXs

            Text {
              text: settingDef.label || ""
              color: Theme.textPrimary
              font.pixelSize: Theme.fontSizeLabel
              font.family: Theme.fontFamilyMono
              font.letterSpacing: 0.04
            }
            Text {
              text: settingDef.description || ""
              color: Theme.textDisabled
              font.pixelSize: Theme.fontSizeMicro
              font.family: Theme.fontFamilyMono
              visible: text !== ""
            }
          }
        }

        StepperControl {
          id: sCtrl
          anchors.verticalCenter: parent.verticalCenter
          value: parent.loaderValue
          stepSize: settingDef.step || 1
          minValue: settingDef.min || 0
          maxValue: settingDef.max || 100
          unit: settingDef.unit || ""
          onStepped: PluginService.setPluginSetting(root.plugin.id, settingDef.key, value, parent._loc)
        }
      }
    }

    Component {
      id: toggleComp
      Row {
        property string _loc: parent._loc
        width: settingsCol ? settingsCol.width : 0
        height: Theme.controlHeight + Theme.spaceSm
        spacing: Theme.spaceSm

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - Theme.spaceSm - tCtrl.width
          height: parent.height
          color: "transparent"

          Column {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: Theme.spaceSm }
            spacing: Theme.spaceXs

            Text {
              text: settingDef.label || ""
              color: Theme.textPrimary
              font.pixelSize: Theme.fontSizeLabel
              font.family: Theme.fontFamilyMono
              font.letterSpacing: 0.04
            }
            Text {
              text: settingDef.description || ""
              color: Theme.textDisabled
              font.pixelSize: Theme.fontSizeMicro
              font.family: Theme.fontFamilyMono
              visible: text !== ""
            }
          }
        }

        Toggle {
          id: tCtrl
          toggleWidth: 38
          toggleHeight: 20
          anchors.verticalCenter: parent.verticalCenter
          checked: PluginService.getPluginSetting(root.plugin.id, settingDef.key, parent._loc) ?? settingDef.default ?? false
          onToggled: function(v) {
            PluginService.setPluginSetting(root.plugin.id, settingDef.key, v, parent._loc)
          }
        }
      }
    }

    Component {
      id: textComp
      Column {
        id: textRoot
        property string _loc: parent._loc
        width: settingsCol ? settingsCol.width : 0
        spacing: Theme.spaceXs
        topPadding: Theme.spaceXs
        bottomPadding: Theme.spaceSm

        Column {
          width: parent.width
          leftPadding: Theme.spaceSm
          spacing: Theme.spaceXs

          Text {
            text: settingDef.label || ""
            color: Theme.textPrimary
            font.pixelSize: Theme.fontSizeLabel
            font.family: Theme.fontFamilyMono
            font.letterSpacing: 0.04
          }
          Text {
            text: settingDef.description || ""
            color: Theme.textDisabled
            font.pixelSize: Theme.fontSizeMicro
            font.family: Theme.fontFamilyMono
            visible: text !== ""
          }
        }

        Input {
          id: tField
          width: parent.width
          fontSize: Theme.fontSizeLabel
          placeholder: settingDef.placeholder || ""
          defaultText: PluginService.getPluginSetting(root.plugin.id, settingDef.key, textRoot._loc) ?? settingDef.default ?? ""
          escapeClears: false
          onCleared: PluginService.setPluginSetting(root.plugin.id, settingDef.key, "", textRoot._loc)

          Connections {
            target: tField.input
            function onEditingFinished() {
              PluginService.setPluginSetting(root.plugin.id, settingDef.key, tField.text, textRoot._loc)
            }
          }
        }
      }
    }

    Component {
      id: selectComp
      Row {
        property string _loc: parent._loc
        property string _ctrlSize: settingDef.controlSize || "md"
        width: settingsCol ? settingsCol.width : 0
        height: (_ctrlSize === "xs" ? Theme.controlHeightSmall - 4 : _ctrlSize === "sm" ? Theme.controlHeightSmall : Theme.controlHeight) + Theme.spaceSm
        spacing: Theme.spaceSm

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - Theme.spaceSm - selCtrl.width
          height: parent.height
          color: "transparent"

          Column {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: Theme.spaceSm }
            spacing: Theme.spaceXs

            Text {
              text: settingDef.label || ""
              color: Theme.textPrimary
              font.pixelSize: Theme.fontSizeLabel
              font.family: Theme.fontFamilyMono
              font.letterSpacing: 0.04
            }
            Text {
              text: settingDef.description || ""
              color: Theme.textDisabled
              font.pixelSize: Theme.fontSizeMicro
              font.family: Theme.fontFamilyMono
              visible: text !== ""
            }
          }
        }

        OptionSwitcher {
          id: selCtrl
          anchors.verticalCenter: parent.verticalCenter
          size: parent._ctrlSize
          options: settingDef.options || []
          currentIndex: {
            var opts = settingDef.options || []
            var val = PluginService.getPluginSetting(root.plugin.id, settingDef.key, parent._loc)
            for (var i = 0; i < opts.length; i++) if (opts[i] === val) return i
            return 0
          }
          onSelected: (index) => PluginService.setPluginSetting(root.plugin.id, settingDef.key, settingDef.options[index], parent._loc)
        }
      }
    }
  }
}
