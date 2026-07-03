import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import "../styles"
import "../core"

Item {
  id: root

  // ── Properties ─────────────────────────────────────────────
  property bool open: false
  property string title: ""
  property string description: ""
  property string iconName: ""
  property int dialogWidth: 380
  property bool dismissOnBackdrop: true
  property bool closeOnConfirm: true
  property bool closeOnReject: true
  property bool confirmOnEnter: true
  property bool busy: false
  property bool showActions: true
  property bool showCancel: true
  property string confirmLabel: "CONFIRM"
  property string cancelLabel: "CANCEL"
  property string confirmIcon: ""
  property variant confirmVariant: "accent"
  property bool confirmEnabled: true

  property alias content: contentArea.data

  // ── Signals ────────────────────────────────────────────────
  signal opened()
  signal closed()
  signal confirmed()
  signal rejected()

  // ── State ──────────────────────────────────────────────────
  visible: open
  z: 9999

  Component.onCompleted: {
    if (Window.window && Window.window.contentItem) {
      root.parent = Window.window.contentItem
    }
  }
  anchors.fill: parent

  Rectangle {
    id: backdrop
    anchors.fill: parent
    color: Theme.background
    opacity: root.open ? 0.65 : 0
    Behavior on opacity {
      enabled: Theme.animationsEnabled
      NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutQuad }
    }
    MouseArea {
      anchors.fill: parent
      enabled: root.open && root.dismissOnBackdrop && !root.busy
      onClicked: root.reject()
    }
  }

  FocusScope {
    id: dialogScope
    anchors.centerIn: parent
    width: Math.min(root.dialogWidth, parent.width - Theme.spaceXl * 2)
    height: dialogCard.implicitHeight
    visible: root.open
    focus: root.open

    onVisibleChanged: if (visible) forceActiveFocus()
    onActiveFocusChanged: if (activeFocus) forceActiveFocus()

    Keys.onEscapePressed: function(event) {
      if (!root.busy) { root.reject(); event.accepted = true }
    }
    Keys.onReturnPressed: function(event) {
      if (root.confirmOnEnter && !root.busy && root.confirmEnabled) { root.confirm(); event.accepted = true }
    }
    Keys.onEnterPressed: function(event) {
      if (root.confirmOnEnter && !root.busy && root.confirmEnabled) { root.confirm(); event.accepted = true }
    }

    Rectangle {
      id: dialogCard
      anchors.fill: parent
      radius: Theme.radiusMedium
      color: Theme.backgroundSecondary
      border.width: Theme.borderWidth
      border.color: Theme.borderVisible
      implicitHeight: dialogLayout.implicitHeight + Theme.spaceLg * 2
      clip: true

      scale: root.open ? 1.0 : 0.96
      opacity: root.open ? 1.0 : 0.0

      Behavior on scale {
        enabled: Theme.animationsEnabled
        NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutQuad }
      }
      Behavior on opacity {
        enabled: Theme.animationsEnabled
        NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutQuad }
      }

      Column {
        id: dialogLayout
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceLg }
        spacing: Theme.spaceMd

        RowLayout {
          width: parent.width
          spacing: Theme.spaceSm
          visible: root.iconName !== "" || root.title !== ""

          Icon {
            source: root.iconName ? Icons.get(root.iconName) : ""
            size: 16
            color: Theme.accent
            visible: root.iconName !== ""
            Layout.alignment: Qt.AlignVCenter
          }

          Text {
            text: (root.title || "").toUpperCase()
            color: Theme.textDisplay
            font.pixelSize: Theme.fontSizeLabel
            font.family: Theme.fontFamilyMono
            font.weight: Font.Medium
            font.letterSpacing: 0.1
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
          }

          Button {
            shape: "icon"
            icon: "xmark"
            size: 24
            iconSize: 12
            visible: root.showCancel && !root.busy
            onClicked: root.reject()
            Layout.alignment: Qt.AlignVCenter
          }
        }

        Text {
          width: parent.width
          visible: root.description !== ""
          text: root.description
          color: Theme.textSecondary
          font.pixelSize: Theme.fontSizeCaption
          font.family: Theme.fontFamilyMono
          font.letterSpacing: 0.04
          wrapMode: Text.WordWrap
        }

        Column {
          id: contentArea
          width: parent.width
          spacing: Theme.spaceSm
        }

        RowLayout {
          width: parent.width
          spacing: Theme.spaceSm
          visible: root.showActions

          Item { Layout.fillWidth: true }

          Button {
            text: root.cancelLabel
            size: "sm"
            visible: root.showCancel && !root.busy
            onClicked: root.reject()
          }

          Button {
            text: root.confirmLabel
            icon: root.confirmIcon
            variant: root.confirmVariant
            size: "sm"
            busy: root.busy
            enabled: root.confirmEnabled && !root.busy
            onClicked: root.confirm()
          }
        }
      }

    }
  }

  onOpenChanged: {
    if (open) {
      root.opened()
      dialogScope.forceActiveFocus()
    } else {
      root.closed()
    }
  }

  // ── Functions ──────────────────────────────────────────────
  function openDialog(): void { root.open = true }
  function close(): void { root.open = false }
  function confirm(): void {
    root.confirmed()
    if (root.closeOnConfirm) root.open = false
  }
  function reject(): void {
    root.rejected()
    if (root.closeOnReject) root.open = false
  }
}
