pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../../../styles"
import "../../../../components"
import "../../../../core"
import "../../../"

BasePlugin {
  id: root

  // ── Manifest ────────────────────────────────────────────────────
  pluginId: "clipboard"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Clipboard",
    description: "Clipboard history",
    icon: "clipboard",
    locations: ["overview"],
    defaultLayout: { "overview": { order: 40 } },
    overviewTab: { icon: "clipboard", label: "CLIP", key: "4" },
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

    Component.onCompleted: ClipboardService.active = true

    Column {
      id: col
      anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceMd }
      spacing: Theme.spaceSm

      RowLayout {
        width: parent.width
        spacing: Theme.spaceSm

        SectionLabel { label: "Clipboard"; Layout.alignment: Qt.AlignVCenter }

        Badge {
          text: ClipboardService.clipboardHistory.length + " ITEMS"
          variant: "default"
          size: "sm"
          visible: ClipboardService.clipboardHistory.length > 0
        }

        Item { Layout.fillWidth: true }

        Button {
          shape: "link"
          text: "CLEAR ALL"
          visible: ClipboardService.clipboardHistory.length > 0
          onClicked: ClipboardService.clearHistory()
        }
      }

      Divider { width: parent.width }

      Flickable {
        width: parent.width
        height: Math.min(clipCol.implicitHeight + Theme.spaceXs * 2, 240)
        contentHeight: clipCol.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: clipCol
          width: parent.width
          spacing: Theme.spaceXs

          Repeater {
            model: ClipboardService.clipboardHistory

            delegate: Surface {
              required property var modelData
              id: clipItem
              width: clipCol.width
              bordered: true
              radius: Theme.radiusMedium
              antialiasing: true
              padding: Theme.spaceMd
              clip: true
              color: clipHover.hovered ? Theme.controlBackgroundHover : "transparent"
              implicitHeight: clipBody.implicitHeight + padding * 2

              property bool _justCopied: false

              Behavior on color {
                enabled: Theme.animationsEnabled
                ColorAnimation { duration: Theme.animationFast }
              }

              HoverHandler { id: clipHover }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  ClipboardService.setClipboard(clipItem.modelData)
                  clipItem._justCopied = true
                  copyTimer.restart()
                }
              }

              RowLayout {
                id: clipBody
                anchors.fill: parent
                spacing: Theme.spaceSm

                ColumnLayout {
                  Layout.fillWidth: true
                  Layout.alignment: Qt.AlignVCenter
                  spacing: Theme.spaceXxs

                  Text {
                    Layout.fillWidth: true
                    text: clipItem.modelData
                    wrapMode: Text.Wrap
                    color: Theme.textPrimary
                    font.pixelSize: Theme.fontSizeSubhead
                    font.family: Theme.fontFamily
                  }

                  Text {
                    text: {
                      var t = clipItem.modelData
                      var lines = t.split("\n").length
                      return t.length + " CHARS · " + lines + " LINE" + (lines !== 1 ? "S" : "")
                    }
                    color: Theme.textDisabled
                    font.pixelSize: Theme.fontSizeCaption
                    font.family: Theme.fontFamilyMono
                  }
                }

                Icon {
                  Layout.alignment: Qt.AlignVCenter
                  source: Icons.get(clipItem._justCopied ? "check" : "copy")
                  size: 14
                  color: clipItem._justCopied ? Theme.accent
                    : clipHover.hovered ? Theme.textSecondary : Theme.textDisabled
                }
              }

              Timer {
                id: copyTimer
                interval: 1200
                onTriggered: clipItem._justCopied = false
              }
            }
          }

          Item {
            width: parent.width
            height: 120
            visible: ClipboardService.clipboardHistory.length === 0

            Column {
              anchors.centerIn: parent
              spacing: Theme.spaceSm

              Icon {
                source: Icons.get("clipboard")
                size: 24
                color: Theme.textDisabled
                anchors.horizontalCenter: parent.horizontalCenter
              }

              Text {
                text: "NO CLIPBOARD HISTORY"
                color: Theme.textDisabled
                font.pixelSize: Theme.fontSizeCaption
                font.family: Theme.fontFamilyMono
                font.letterSpacing: 0.06
                anchors.horizontalCenter: parent.horizontalCenter
              }

              Text {
                text: "Copy something with Ctrl+C or Cmd+C"
                color: Qt.rgba(Theme.textDisabled.r, Theme.textDisabled.g, Theme.textDisabled.b, 0.6)
                font.pixelSize: Theme.fontSizeMicro
                font.family: Theme.fontFamilyMono
                font.letterSpacing: 0.04
                anchors.horizontalCenter: parent.horizontalCenter
              }
            }
          }
        }
      }
    }
  }
}
