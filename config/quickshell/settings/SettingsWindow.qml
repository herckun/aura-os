import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../styles"
import "../core"
import "../services"
import "../components"
import "pages"

FloatingWindow {
  id: settings
  color: Theme.background

  title: "Settings"
  implicitWidth: 1000
  implicitHeight: 660
  minimumSize: Qt.size(400, 350)

  visible: false

  function navigate(pane: string): void {
    currentPane = pane
    visible = true
    try { raise() } catch (e) {}
  }

  property string currentPane: "dashboard"
  property string _pendingPane: ""
  property bool _loading: false
  property bool _pageReady: false

  Timer {
    id: minSpinnerTimer
    interval: 300
    onTriggered: {
      if (settings._pageReady) {
        settings._loading = false
        settings._pageReady = false
      }
    }
  }

  Timer {
    id: loadPageTimer
    interval: 50
    onTriggered: {
      pagesLoader.source = getPageSource(settings._pendingPane)
    }
  }

  function getPageSource(pane: string): string {
    switch (pane) {
      case "dashboard": return "pages/DashboardPage.qml"
      case "appearance": return "pages/AppearancePage.qml"
      case "wallpaper": return "pages/WallpaperPage.qml"
      case "display": return "pages/DisplayPage.qml"
      case "audio": return "pages/AudioPage.qml"
      case "connectivity": return "pages/ConnectivityPage.qml"
      case "keybindings": return "pages/KeybindingsPage.qml"
      case "defaultapps": return "pages/DefaultAppsPage.qml"
      case "user": return "pages/UserPage.qml"
      case "plugins": return "pages/layout/LayoutPage.qml"
      case "misc": return "pages/MiscPage.qml"
      case "about": return "pages/AboutPage.qml"
      default: return "pages/DashboardPage.qml"
    }
  }

  function toggle(): void {
    settings.visible = !settings.visible
    if (settings.visible) try { settings.raise() } catch (e) {}
  }

  Surface {
    anchors.fill: parent
    radius: Theme.radiusLarge
    color: Theme.background

    DotMatrixBackground {
      anchors.fill: parent
    }
  }

  Rectangle {
    id: titleBar
    anchors { top: parent.top; left: parent.left; right: parent.right }
    width: parent.width
    height: 56
    radius: Theme.radiusLarge
    color: "transparent"

    RowLayout {
      anchors { fill: parent; leftMargin: Theme.spaceLg; rightMargin: Theme.spaceMd }
      spacing: Theme.spaceSm

      Icon {
        source: Icons.get("gear-six")
        size: 18
        color: Theme.accent
        Layout.alignment: Qt.AlignVCenter
      }

      Text {
        text: AppInfo.displayName.toUpperCase()
        color: Theme.textDisplay
        font.pixelSize: Theme.fontSizeLabel
        font.family: Theme.fontFamilyDisplay
        font.letterSpacing: 2
        Layout.alignment: Qt.AlignVCenter
      }

      Text {
        text: "SETTINGS"
        color: Theme.textSecondary
        font.pixelSize: Theme.fontSizeCaption
        font.family: Theme.fontFamilyMono
        font.letterSpacing: 1
        Layout.alignment: Qt.AlignVCenter
      }

      Item { Layout.fillWidth: true }

      Button { shape: "icon";
        icon: "xmark"
        tooltip: "CLOSE"
        onClicked: settings.visible = false
        Layout.alignment: Qt.AlignVCenter
      }
    }

    Rectangle {
      anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: Theme.spaceLg; rightMargin: Theme.spaceLg }
      height: 1; color: Theme.border
    }
  }

  RowLayout {
    anchors { top: titleBar.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
    spacing: 0

    Rectangle {
      Layout.preferredWidth: 190
      Layout.fillHeight: true
      Layout.leftMargin: Theme.spaceMd
      Layout.topMargin: Theme.spaceMd
      Layout.bottomMargin: Theme.spaceMd
      radius: Theme.radiusLarge
      color: Theme.transparencyEnabled
        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.06)
        : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.04)
      border.width: 1
      border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)

      ListView {
        id: navList
        anchors { fill: parent; margins: Theme.spaceSm }
        model: ListModel {
          ListElement { sid: "dashboard";    icon: "grid";       label: "DASHBOARD" }
          ListElement { sid: "display";      icon: "monitor";    label: "DISPLAY" }
          ListElement { sid: "audio";        icon: "volume";     label: "AUDIO" }
          ListElement { sid: "connectivity"; icon: "wifi";       label: "CONNECTIVITY" }
          ListElement { sid: "appearance";   icon: "palette";    label: "APPEARANCE" }
          ListElement { sid: "wallpaper";    icon: "image";      label: "WALLPAPER" }
          ListElement { sid: "keybindings";  icon: "keyboard";   label: "KEYBINDINGS" }
          ListElement { sid: "defaultapps";  icon: "rocket";     label: "DEFAULT APPS" }
          ListElement { sid: "user";         icon: "user";       label: "USER" }
          ListElement { sid: "plugins";      icon: "cpu";        label: "PLUGINS" }
          ListElement { sid: "about";        icon: "info";       label: "ABOUT" }
          ListElement { sid: "misc";         icon: "clipboard";  label: "MISC" }
        }
        spacing: Theme.spaceXxs
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        delegate: SettingsMenuItem {
          width: navList.width
          icon: model.icon
          label: model.label
          selected: settings.currentPane === model.sid
          onClicked: settings.currentPane = model.sid
        }

        section.property: ""
        section.delegate: Item {
          width: navList.width
          height: Theme.spaceMd
        }
      }
    }

    Flickable {
      id: contentFlick
      Layout.fillWidth: true
      Layout.fillHeight: true
      contentHeight: contentColumn.implicitHeight + (Theme.spaceLg * 2)
      boundsBehavior: Flickable.StopAtBounds
      clip: true
      interactive: contentHeight > height

      Column {
        id: contentColumn
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: Theme.spaceLg }

        Loader {
          id: pagesLoader
          width: parent.width
          asynchronous: true
          source: getPageSource(settings.currentPane)

          opacity: 0
          y: 8

          Behavior on opacity {
            enabled: Theme.animationsEnabled
            NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic }
          }
          Behavior on y {
            enabled: Theme.animationsEnabled
            NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic }
          }

          onLoaded: {
            contentFlick.contentY = 0
            settings._pageReady = true
            if (!minSpinnerTimer.running) {
              settings._loading = false
              settings._pageReady = false
            }
            opacity = 1
            y = 0
          }
        }
      }

      ScrollBar.vertical: ScrollBar {
        width: 4
        anchors.right: parent.right
        policy: ScrollBar.AsNeeded
        contentItem: Rectangle {
          implicitWidth: 4
          radius: Theme.radiusXs
          color: Theme.borderVisible
        }
      }
    }
  }

  SpinnerScreen {
    id: spinnerOverlay
    visible: settings._loading
    anchors { top: titleBar.bottom; bottom: parent.bottom; right: parent.right }
    width: settings.width - 190 - Theme.spaceMd
  }

  onCurrentPaneChanged: {
    settings._loading = true
    settings._pageReady = false
    settings._pendingPane = settings.currentPane
    pagesLoader.opacity = 0
    pagesLoader.y = 8
    contentFlick.contentY = 0
    minSpinnerTimer.restart()
    loadPageTimer.restart()
  }
}
