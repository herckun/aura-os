import QtQuick
import "../../../styles"
import "../../../core"
import "../../../services"
import "../../../components"

Column {
  id: root

  property var plugin: null
  property string location: ""

  readonly property string pluginId: plugin?.id ?? ""
  readonly property var _defs: plugin?.manifest?.settings || []
  readonly property var _localDefs: _defs.filter(function(d) {
    if (d.shared === true) return false
    return !d.locations || d.locations.indexOf(root.location) >= 0
  })
  readonly property var _sharedDefs: _defs.filter(function(d) { return d.shared === true })
  readonly property bool _grouped: _sharedDefs.length > 0

  function _locationLabel(loc: string): string {
    switch (loc) {
      case "controlcenter_row": return "CONTROL CENTER"
      case "controlcenter_toggle": return "QUICK TOGGLES"
      default: return loc.replace(/_/g, " ").toUpperCase()
    }
  }

  width: parent ? parent.width : 0
  spacing: 0

  Component {
    id: editorDelegate

    Loader {
      id: settingLoader
      width: root.width
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
      property real _value: PluginService.getPluginSetting(root.pluginId, settingDef.key, _loc) ?? settingDef.default ?? 0
    }
  }

  Text {
    topPadding: Theme.spaceXs
    bottomPadding: Theme.spaceXs
    leftPadding: Theme.spaceSm
    text: "HERE IN " + root._locationLabel(root.location)
    color: Theme.textDisabled
    font.pixelSize: Theme.fontSizeMicro
    font.family: Theme.fontFamilyMono
    font.letterSpacing: 0.14
    visible: root._grouped && root._localDefs.length > 0
  }

  Repeater {
    model: root._localDefs
    delegate: editorDelegate
  }

  Text {
    topPadding: Theme.spaceSm
    bottomPadding: Theme.spaceXs
    leftPadding: Theme.spaceSm
    text: "EVERYWHERE — SHARED ACROSS LOCATIONS"
    color: Theme.textDisabled
    font.pixelSize: Theme.fontSizeMicro
    font.family: Theme.fontFamilyMono
    font.letterSpacing: 0.14
    visible: root._grouped
  }

  Repeater {
    model: root._sharedDefs
    delegate: editorDelegate
  }

  Component {
    id: stepperComp
    Row {
      property real loaderValue: parent._value
      property string _loc: parent._loc
      width: root.width
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
        onStepped: PluginService.setPluginSetting(root.pluginId, settingDef.key, value, parent._loc)
      }
    }
  }

  Component {
    id: toggleComp
    Row {
      property string _loc: parent._loc
      width: root.width
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
        checked: PluginService.getPluginSetting(root.pluginId, settingDef.key, parent._loc) ?? settingDef.default ?? false
        onToggled: function(v) {
          PluginService.setPluginSetting(root.pluginId, settingDef.key, v, parent._loc)
        }
      }
    }
  }

  Component {
    id: textComp
    Column {
      id: textRoot
      property string _loc: parent._loc
      width: root.width
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
        defaultText: PluginService.getPluginSetting(root.pluginId, settingDef.key, textRoot._loc) ?? settingDef.default ?? ""
        escapeClears: false
        onCleared: PluginService.setPluginSetting(root.pluginId, settingDef.key, "", textRoot._loc)

        Connections {
          target: tField.input
          function onEditingFinished() {
            PluginService.setPluginSetting(root.pluginId, settingDef.key, tField.text, textRoot._loc)
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
      width: root.width
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
          var val = PluginService.getPluginSetting(root.pluginId, settingDef.key, parent._loc)
          for (var i = 0; i < opts.length; i++) if (opts[i] === val) return i
          return 0
        }
        onSelected: (index) => PluginService.setPluginSetting(root.pluginId, settingDef.key, settingDef.options[index], parent._loc)
      }
    }
  }
}
