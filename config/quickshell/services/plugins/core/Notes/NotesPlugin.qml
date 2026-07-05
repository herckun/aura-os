pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../../styles"
import "../../../../components"
import "../../../../core"
import "../../../"

BasePlugin {
  id: root
  visible: false

  // ── Manifest ────────────────────────────────────────────────────
  pluginId: "notes"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Notes",
    description: "Quick markdown scratchpad",
    icon: "note",
    locations: ["overview"],
    defaultLayout: { "overview": { order: 30 } },
    overviewTab: { icon: "note", label: "NOTES", key: "5" },
    settings: []
  })

  // ── Public state ─────────────────────────────────────────────────

  // ── Internal state ───────────────────────────────────────────────
  property string _content: ""

  // ── Signal handlers ──────────────────────────────────────────────

  // ── Public API ───────────────────────────────────────────────────
  function _syncFromStore(): void {
    var val = Store.plugins.settings["notes:content"] ?? ""
    if (val !== _content) _content = val
  }

  function _save(): void {
    Store.plugins.settings = Store.mapSet(Store.plugins.settings, "notes:content", _content)
  }

  function _onContentChanged(): void {
    _saveTimer.restart()
  }

  // ── Helpers ──────────────────────────────────────────────────────

  // ── Timers ───────────────────────────────────────────────────────
  property Timer _saveTimer: Timer {
    interval: 2000
    running: false
    repeat: false
    onTriggered: root._save()
  }

  // ── Lifecycle ────────────────────────────────────────────────────
  Component.onCompleted: {
    _syncFromStore()
  }

  Connections {
    target: Store.plugins
    function onSettingsChanged() {
      root._syncFromStore()
    }
  }

  // ── UI components ────────────────────────────────────────────────
  property Component overviewComponent: FocusScope {
    implicitHeight: notesCol.implicitHeight + Theme.spaceMd * 2

    Column {
      id: notesCol
      anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceMd }
      spacing: Theme.spaceSm

      RowLayout {
        width: parent.width
        spacing: Theme.spaceSm

        SectionLabel { label: "Notes"; Layout.alignment: Qt.AlignVCenter }

        Badge {
          text: _wordCount() + " WORDS"
          variant: "default"
          size: "sm"
          visible: root._content.length > 0
        }

        Item { Layout.fillWidth: true }

        Text {
          text: _lineCount() + " LINES"
          color: Theme.textDisabled
          font.pixelSize: Theme.fontSizeCaption
          font.family: Theme.fontFamilyMono
          font.letterSpacing: 0.04
        }
      }

      Surface {
        width: parent.width
        height: 300
        radius: Theme.radiusMedium
        color: Theme.controlBackground
        border.color: notesInput.activeFocus ? Theme.accent : Theme.borderVisible

        Flickable {
          id: flick
          anchors.fill: parent
          anchors.margins: Theme.spaceSm
          contentHeight: notesInput.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds

          TextEdit {
            id: notesInput
            width: flick.width
            color: Theme.textPrimary
            font.pixelSize: Theme.fontSizeLabel
            font.family: Theme.fontFamilyMono
            wrapMode: TextEdit.Wrap
            selectByMouse: true
            focus: true
            text: root._content
            onTextChanged: {
              if (root._content !== text) {
                root._content = text
                root._onContentChanged()
              }
            }
          }
        }

        Text {
          anchors.centerIn: parent
          text: "Start typing..."
          color: Theme.textDisabled
          font.pixelSize: Theme.fontSizeLabel
          font.family: Theme.fontFamilyMono
          visible: root._content.length === 0 && !notesInput.activeFocus
        }
      }
    }

    function _wordCount(): int {
      var t = root._content.trim()
      if (t.length === 0) return 0
      return t.split(/\s+/).length
    }

    function _lineCount(): int {
      var t = root._content
      if (t.length === 0) return 0
      return t.split("\n").length
    }
  }
}
