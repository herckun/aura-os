import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../styles"
import "../../core"
import "../../services"
import "../../components"

ColumnLayout {
  id: root
  spacing: Theme.spaceLg
  width: parent.width

  property var _hw: ({})

  readonly property string _display: Quickshell.screens.length > 0
    ? Quickshell.screens[0].width + " × " + Quickshell.screens[0].height
    : ""

  Component.onCompleted: {
    ProcessPool.runTracked("About: hardware info", [
      "sh", "-c",
      'echo "cpu=$(grep -m1 \'model name\' /proc/cpuinfo | cut -d: -f2- | sed \'s/^ //\')"; ' +
      'gpu=$(lspci 2>/dev/null | grep -iE "vga|3d controller" | head -1 | sed "s/^.*: //; s/ (rev.*//"); ' +
      'case "$gpu" in *\\[*\\]*) gpu=$(printf "%s" "$gpu" | sed "s/.*\\[\\(.*\\)\\].*/\\1/");; esac; ' +
      'echo "gpu=$gpu"; ' +
      'echo "distro=$(. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME")"; ' +
      'echo "kernel=$(uname -r)"; ' +
      'echo "host=$(hostnamectl hostname 2>/dev/null || cat /etc/hostname 2>/dev/null)"; ' +
      'echo "hypr=$(hyprctl version 2>/dev/null | head -1 | sed \'s/Hyprland //; s/ built.*//\')"; ' +
      'echo "mem=$(free -h --si 2>/dev/null | awk \'/^Mem:/ {print $2}\')"'
    ], {
      id: "about-hw",
      silent: true,
      callback: function(r) {
        var out = ({})
        var lines = (r.stdout || "").split("\n")
        for (var i = 0; i < lines.length; i++) {
          var eq = lines[i].indexOf("=")
          if (eq > 0) out[lines[i].substring(0, eq)] = lines[i].substring(eq + 1).trim()
        }
        root._hw = out
      }
    })
  }

  PageHeader { title: "ABOUT" }

  // ── Hero ────────────────────────────────────────
  Rectangle {
    Layout.fillWidth: true
    implicitHeight: heroCol.implicitHeight + Theme.spaceLg * 2
    radius: Theme.radiusMedium
    color: Theme.backgroundSecondary
    border.width: Theme.borderWidth
    border.color: Theme.border

    Column {
      id: heroCol
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width
      spacing: Theme.spaceSm
      topPadding: Theme.spaceMd
      bottomPadding: Theme.spaceMd

      Image {
        anchors.horizontalCenter: parent.horizontalCenter
        source: AppInfo.logoPath()
        sourceSize.width: 64
        sourceSize.height: 64
        width: 64
        height: 64
        asynchronous: true
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: AppInfo.displayName.toUpperCase()
        color: Theme.textDisplay
        font.pixelSize: Theme.fontSizeHeading
        font.family: Theme.fontFamilyDisplay
        font.letterSpacing: 4
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.spaceXs

        Badge { text: "V" + AppInfo.version; size: "sm" }

        Badge {
          text: (root._hw.host || "").toUpperCase()
          size: "sm"
          visible: (root._hw.host || "") !== ""
          bgColor: Theme.backgroundTertiary
          textColor: Theme.textSecondary
        }
      }
    }
  }

  // ── System ──────────────────────────────────────
  Card {
    Layout.fillWidth: true
    title: "SYSTEM"

    Grid {
      id: specGrid
      width: parent.width
      columns: 2
      columnSpacing: Theme.spaceSm
      rowSpacing: Theme.spaceSm

      readonly property real tileWidth: (width - columnSpacing) / 2

      SpecTile { icon: "cpu";      label: "PROCESSOR"; value: root._hw.cpu || "…" }
      SpecTile { icon: "display";  label: "GRAPHICS";  value: root._hw.gpu || "…" }
      SpecTile { icon: "database"; label: "MEMORY";    value: (root._hw.mem || "…") + (ResourceService.memUsed > 0 ? "  ·  " + Math.round(ResourceService.memPct) + "% USED" : "") }
      SpecTile { icon: "monitor";  label: "DISPLAY";   value: root._display }
      SpecTile { icon: "package";  label: "OS";        value: root._hw.distro || "…" }
      SpecTile { icon: "terminal"; label: "KERNEL";    value: root._hw.kernel || "…" }
      SpecTile { icon: "layout-grid"; label: "WINDOW MANAGER"; value: "HYPRLAND " + (root._hw.hypr || "") }
      SpecTile { icon: "clock";    label: "UPTIME";    value: ResourceService.uptime || "…" }
    }
  }

  component SpecTile: Rectangle {
    id: tile

    property string icon: ""
    property string label: ""
    property string value: ""

    width: parent && parent.tileWidth !== undefined ? parent.tileWidth : 200
    height: tileCol.implicitHeight + Theme.spaceSm * 2
    radius: Theme.radiusSmall
    color: Theme.controlBackground
    border.width: Theme.borderWidth
    border.color: Theme.border

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: Theme.spaceSm
      anchors.rightMargin: Theme.spaceSm
      spacing: Theme.spaceSm

      Icon {
        source: Icons.get(tile.icon)
        size: 15
        color: Theme.accent
      }

      Column {
        id: tileCol
        Layout.fillWidth: true
        spacing: Theme.spaceXxs

        Text {
          text: tile.label
          color: Theme.textDisabled
          font.pixelSize: Theme.fontSizeMicro
          font.family: Theme.fontFamilyMono
          font.letterSpacing: 0.12
        }

        Text {
          width: parent.width
          text: tile.value.toUpperCase()
          color: Theme.textPrimary
          font.pixelSize: Theme.fontSizeCaption
          font.family: Theme.fontFamilyMono
          font.weight: Font.Bold
          font.letterSpacing: 0.02
          elide: Text.ElideRight
          maximumLineCount: 1
        }
      }
    }
  }

  CreditsSection {}

  Text {
    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
    text: AppInfo.displayName + " v" + AppInfo.version
    color: Theme.textDisabled
    font.pixelSize: Theme.fontSizeMicro
    font.family: Theme.fontFamilyMono
    font.letterSpacing: 2
  }

  Item { Layout.fillHeight: true }
}
