import QtQuick
import QtQuick.Layouts
import "../styles"
import "../core"
import "../components"

Card {
  id: root
  Layout.fillWidth: true
  title: "CREDITS"
  description: "The people and projects this shell stands on"

  property var credits: AppInfo.credits

  Column {
    width: parent.width
    spacing: Theme.spaceXs

    Repeater {
      model: root.credits

      delegate: Rectangle {
        id: row
        required property var modelData
        readonly property bool hasUrl: (modelData.url || "") !== ""

        width: parent.width
        height: 52
        radius: Theme.radiusSmall
        antialiasing: true
        color: rowMa.containsMouse && hasUrl ? Theme.controlBackgroundHover : Theme.controlBackground
        border.width: Theme.borderWidth
        border.color: rowMa.containsMouse && hasUrl ? Theme.borderActive : Theme.border

        Behavior on color { enabled: Theme.animationsEnabled; ColorAnimation { duration: Theme.animationFast } }

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: Theme.spaceSm
          anchors.rightMargin: Theme.spaceSm
          spacing: Theme.spaceSm

          Rectangle {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            radius: Theme.radiusSmall
            antialiasing: true
            color: Theme.backgroundTertiary
            border.width: Theme.borderWidth
            border.color: Theme.borderVisible

            Icon {
              anchors.centerIn: parent
              source: Icons.get(row.modelData.icon || "user")
              size: 15
              color: Theme.accent
            }
          }

          Column {
            Layout.fillWidth: true
            spacing: Theme.spaceXxs

            Text {
              width: parent.width
              text: (row.modelData.name || "").toUpperCase()
              color: Theme.textPrimary
              font.pixelSize: Theme.fontSizeCaption
              font.family: Theme.fontFamilyMono
              font.weight: Font.Bold
              font.letterSpacing: 0.06
              elide: Text.ElideRight
            }

            Text {
              width: parent.width
              text: row.modelData.role || ""
              color: Theme.textDisabled
              font.pixelSize: Theme.fontSizeMicro
              font.family: Theme.fontFamilyMono
              elide: Text.ElideRight
              visible: text !== ""
            }
          }

          Icon {
            source: Icons.get("external-link")
            size: 13
            color: rowMa.containsMouse ? Theme.accent : Theme.textDisabled
            visible: row.hasUrl
          }
        }

        MouseArea {
          id: rowMa
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: row.hasUrl ? Qt.PointingHandCursor : Qt.ArrowCursor
          onClicked: if (row.hasUrl) Qt.openUrlExternally(row.modelData.url)
        }
      }
    }

    Item { width: 1; height: Theme.spaceXs }

    Row {
      spacing: Theme.spaceXs

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "TYPE"
        color: Theme.textDisabled
        font.pixelSize: Theme.fontSizeMicro
        font.family: Theme.fontFamilyMono
        font.letterSpacing: 0.12
        rightPadding: Theme.spaceXs
      }

      Repeater {
        model: ["SPACE GROTESK", "SPACE MONO", "DOTO"]
        delegate: Badge {
          required property string modelData
          text: modelData
          variant: "default"
          size: "sm"
        }
      }
    }
  }
}
