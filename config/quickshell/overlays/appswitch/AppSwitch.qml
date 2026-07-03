import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../styles"
import "../../services/hyprland"
import "../../core"
import "../../components"

OverlayPanel {
  id: root

  centered: true
  closeOnEscape: true
  closeOnBackdrop: true

  onPanelClosed: {
    _idleTimer.stop()
    root._committed = true
  }

  property var windows: []
  property int selectedIndex: 0
  property int _windowCount: 0
  property bool _committed: false

  function press(): void {
    if (_committed) {
      _committed = false
      _refreshWindows()
      if (_windowCount > 1) root.selectedIndex = 1
      root.visible = true
      _idleTimer.restart()
      return
    }

    _refreshWindows()
    _idleTimer.restart()

    if (!root.visible) {
      root.selectedIndex = root._windowCount > 1 ? 1 : 0
      root.visible = true
    } else {
      if (root._windowCount > 0) {
        root.selectedIndex = (root.selectedIndex + 1) % root._windowCount
      }
    }
  }

  function release(): void {
    if (!_committed && root.visible) {
      _commitSelection()
    }
  }

  function _refreshWindows(): void {
    var clients = HyprlandService.clients
    if (!clients) { root.windows = []; root._windowCount = 0; return }
    var sorted = clients.slice()
    sorted.sort(function(a, b) { return (a.focusHistoryID || 0) - (b.focusHistoryID || 0) })
    root.windows = sorted
    root._windowCount = root.windows.length
  }

  function _commitSelection(): void {
    _idleTimer.stop()
    if (_committed) return
    _committed = true
    if (_windowCount === 0) { root.visible = false; return }
    var win = root.windows[root.selectedIndex]
    root.visible = false
    if (win && win.address) {
      HyprlandService.focusWindow(win.address)
    }
  }

  function _findToplevelForAddress(addr: string): var {
    if (!addr) return null
    var toplevels = Hyprland.toplevels.values
    if (!toplevels) return null
    var normalizedAddr = addr.toLowerCase().replace(/^0x/, "")
    for (var i = 0; i < toplevels.length; i++) {
      var tl = toplevels[i]
      if (tl && tl.address && tl.address.toLowerCase() === normalizedAddr) {
        return tl.wayland || null
      }
    }
    return null
  }

  Timer {
    id: _idleTimer
    interval: 2000
    onTriggered: root._commitSelection()
  }

  fullContent: Item {
    id: focusScope
    anchors.fill: parent
    focus: root.visible

    Keys.onPressed: function(event) {
      if (!root.visible) return
      _idleTimer.restart()

      switch (event.key) {
      case Qt.Key_Tab:
      case Qt.Key_Backtab:
        if (root._windowCount > 0) {
          root.selectedIndex = (root.selectedIndex + 1) % root._windowCount
        }
        event.accepted = true
        break
      case Qt.Key_Return:
      case Qt.Key_Enter:
        root._commitSelection()
        event.accepted = true
        break
      }
    }

    // ── Empty state ─────────────────────────────────────
    Column {
      anchors.centerIn: parent
      spacing: Theme.spaceMd
      visible: root._windowCount === 0 && root.visible
      opacity: root.visible ? 1 : 0

      Behavior on opacity {
        enabled: Theme.animationsEnabled
        NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic }
      }

      Rectangle {
        width: 72; height: 72
        radius: Theme.radiusLarge
        color: Qt.rgba(Theme.textDisabled.r, Theme.textDisabled.g, Theme.textDisabled.b, 0.08)
        border.width: 1
        border.color: Qt.rgba(Theme.textDisabled.r, Theme.textDisabled.g, Theme.textDisabled.b, 0.1)
        anchors.horizontalCenter: parent.horizontalCenter

        Icon {
          anchors.centerIn: parent
          source: Icons.get("window")
          size: 36
          color: Theme.textDisabled
        }
      }

      Text {
        text: "No windows"
        color: Theme.textSecondary
        font.pixelSize: Theme.fontSizeBody
        font.family: Theme.fontFamily
        font.weight: Font.Medium
        anchors.horizontalCenter: parent.horizontalCenter
      }
    }

    // ── Main content ────────────────────────────────────
    Item {
      id: contentArea
      anchors.centerIn: parent
      width: Math.min(parent.width * 0.85, root._windowCount * 264 + Math.max(0, root._windowCount - 1) * Theme.spaceLg + Theme.spaceXl * 2)
      height: 370
      visible: root._windowCount > 0 && root.visible

      scale: root.visible ? 1 : 0.94
      opacity: root.visible ? 1 : 0

      Behavior on scale {
        enabled: Theme.animationsEnabled
        NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic }
      }
      Behavior on opacity {
        enabled: Theme.animationsEnabled
        NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic }
      }

      Rectangle {
        id: counterBadge
        anchors.top: parent.top
        anchors.topMargin: -Theme.spaceLg
        anchors.horizontalCenter: parent.horizontalCenter
        width: counterText.implicitWidth + Theme.spaceMd * 2
        height: 30
        radius: Theme.radiusPill
        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
        border.width: 1
        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)

        Text {
          id: counterText
          anchors.centerIn: parent
          text: (root.selectedIndex + 1) + " / " + root._windowCount
          color: Theme.accent
          font.pixelSize: Theme.fontSizeCaption
          font.family: Theme.fontFamilyMono
          font.weight: Font.Bold
        }
      }

      Row {
        id: tilesRow
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 14
        spacing: Theme.spaceLg

        Repeater {
          model: root.windows

          delegate: Item {
            id: tileItem

            required property var modelData
            required property int index

            property bool isSelected: index === root.selectedIndex
            property var waylandToplevel: root._findToplevelForAddress(tileItem.modelData.address || "")

            width: isSelected ? 252 : 210
            height: isSelected ? 310 : 245
            y: isSelected ? -22 : 18
            opacity: isSelected ? 1.0 : 0.55

            Behavior on width { enabled: Theme.animationsEnabled; NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }
            Behavior on height { enabled: Theme.animationsEnabled; NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }
            Behavior on y { enabled: Theme.animationsEnabled; NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }
            Behavior on opacity { enabled: Theme.animationsEnabled; NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }

            Rectangle {
              visible: tileItem.isSelected
              width: tileCard.width + 16
              height: tileCard.height + 16
              x: tileCard.x - 8
              y: tileCard.y - 8
              radius: tileCard.radius + 8
              color: "transparent"
              border.width: 1
              border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2)
            }

            Rectangle {
              width: tileCard.width
              height: tileCard.height
              x: tileCard.x
              y: tileCard.y + (tileItem.isSelected ? 10 : 5)
              radius: tileCard.radius
              color: Qt.rgba(0, 0, 0, tileItem.isSelected ? 0.4 : 0.1)
              z: -1

              Behavior on y { enabled: Theme.animationsEnabled; NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }
              Behavior on color { enabled: Theme.animationsEnabled; ColorAnimation { duration: Theme.animationFast } }
            }

            Rectangle {
              id: tileCard
              anchors.fill: parent
              radius: Theme.radiusLarge
              color: Theme.backgroundSecondary
              border.width: tileItem.isSelected ? 2 : 1
              border.color: tileItem.isSelected ? Theme.accent : Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.25)

              Behavior on border.color { enabled: Theme.animationsEnabled; ColorAnimation { duration: Theme.animationFast } }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                z: 10
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.selectedIndex = tileItem.index
                  root._commitSelection()
                }
                onEntered: { if (!tileItem.isSelected) tileCard.border.color = Theme.controlBorderHover }
                onExited: { if (!tileItem.isSelected) tileCard.border.color = Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.25) }
              }

              Column {
                anchors.fill: parent
                anchors.margins: Theme.spaceSm
                spacing: Theme.spaceXs

                Rectangle {
                  width: parent.width
                  height: parent.height - 56
                  radius: Theme.radiusMedium
                  color: Theme.background
                  clip: true

                  Loader {
                    anchors.fill: parent
                    anchors.margins: 1
                    active: tileItem.waylandToplevel !== null
                    sourceComponent: ScreencopyView {
                      captureSource: tileItem.waylandToplevel
                      live: false
                      visible: hasContent
                      Component.onCompleted: captureFrame()
                    }
                  }

                  Column {
                    anchors.centerIn: parent
                    spacing: Theme.spaceSm
                    visible: {
                      var loader = parent.parent.children[1]
                      return !loader || !loader.item || !loader.item.hasContent
                    }

                    Rectangle {
                      width: 44; height: 44
                      radius: Theme.radiusMedium
                      color: Qt.rgba(Theme.textDisabled.r, Theme.textDisabled.g, Theme.textDisabled.b, 0.08)
                      border.width: 1
                      border.color: Qt.rgba(Theme.textDisabled.r, Theme.textDisabled.g, Theme.textDisabled.b, 0.1)
                      anchors.horizontalCenter: parent.horizontalCenter

                      Icon {
                        anchors.centerIn: parent
                        source: Icons.get("window")
                        size: 22
                        color: Theme.textDisabled
                      }
                    }
                  }

                  Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 40
                    gradient: Gradient {
                      GradientStop { position: 0.0; color: "transparent" }
                      GradientStop { position: 1.0; color: Qt.rgba(Theme.backgroundSecondary.r, Theme.backgroundSecondary.g, Theme.backgroundSecondary.b, 0.9) }
                    }
                  }

                  Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    anchors.bottomMargin: 6
                    height: 18
                    radius: Theme.radiusSmall
                    color: Qt.rgba(0, 0, 0, 0.45)

                    Text {
                      anchors.centerIn: parent
                      text: tileItem.modelData.class || "unknown"
                      color: Qt.rgba(1, 1, 1, 0.85)
                      font.pixelSize: 9
                      font.family: Theme.fontFamilyMono
                      font.weight: Font.Medium
                      elide: Text.ElideRight
                      width: parent.width - Theme.spaceSm * 2
                      horizontalAlignment: Text.AlignHCenter
                    }
                  }
                }

                Column {
                  width: parent.width
                  spacing: 3

                  Text {
                    text: {
                      var title = tileItem.modelData.title || ""
                      if (title.length > 24) title = title.substring(0, 24) + "..."
                      return title || tileItem.modelData.class || "Unknown"
                    }
                    color: tileItem.isSelected ? Theme.textPrimary : Theme.textSecondary
                    font.pixelSize: Theme.fontSizeCaption
                    font.family: Theme.fontFamily
                    font.weight: tileItem.isSelected ? Font.DemiBold : Font.Normal
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    elide: Text.ElideRight
                    width: parent.width
                  }

                  Rectangle {
                    width: wsRow.width + Theme.spaceSm * 2
                    height: 16
                    radius: Theme.radiusPill
                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, tileItem.isSelected ? 0.15 : 0.06)
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: tileItem.modelData.workspace && tileItem.modelData.workspace.id !== undefined

                    Row {
                      id: wsRow
                      anchors.centerIn: parent
                      spacing: 3

                      Rectangle {
                        width: 5; height: 5
                        radius: 3
                        anchors.verticalCenter: parent.verticalCenter
                        color: tileItem.isSelected ? Theme.accent : Qt.rgba(Theme.textDisabled.r, Theme.textDisabled.g, Theme.textDisabled.b, 0.4)
                      }

                      Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                          var ws = tileItem.modelData.workspace
                          if (ws && ws.name) return ws.name
                          if (ws && ws.id !== undefined) return "WS " + ws.id
                          return ""
                        }
                        color: tileItem.isSelected ? Theme.accent : Theme.textDisabled
                        font.pixelSize: 8
                        font.family: Theme.fontFamilyMono
                        font.weight: Font.Bold
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

    }
  }

  overlayFooter: Surface {
    color: Theme.backgroundTertiary
    bordered: true
    radius: Theme.radiusPill
    visible: root._windowCount > 0
    implicitWidth: hintRow.implicitWidth + Theme.spaceLg * 2
    implicitHeight: hintRow.implicitHeight + Theme.spaceSm * 2

    Row {
      id: hintRow
      anchors.centerIn: parent
      spacing: Theme.spaceMd

      KeyHint { anchors.verticalCenter: parent.verticalCenter; key: "TAB"; label: "cycle" }
      KeyHint { anchors.verticalCenter: parent.verticalCenter; key: "\u21B5"; label: "select" }
      KeyHint { anchors.verticalCenter: parent.verticalCenter; key: "ESC"; label: "dismiss" }
    }
  }
}
