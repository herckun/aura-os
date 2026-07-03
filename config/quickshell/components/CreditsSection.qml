import QtQuick
import QtQuick.Layouts
import "../styles"
import "../core"

Card {
  id: root
  Layout.fillWidth: true
  title: "CREDITS"

  property var credits: AppInfo.credits

  Column {
    width: parent.width
    spacing: Theme.spaceMd

    Repeater {
      model: root.credits
      delegate: Row {
        spacing: Theme.spaceSm
        width: parent.width

        Text {
          text: (modelData.name || "").toUpperCase()
          color: modelData.url ? Theme.accent : Theme.textPrimary
          font.pixelSize: Theme.fontSizeCaption
          font.family: Theme.fontFamilyMono
          font.bold: true
          width: parent.width * 0.4

          MouseArea {
            anchors.fill: parent
            cursorShape: modelData.url ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
              if (modelData.url)
                Qt.openUrlExternally(modelData.url)
            }
          }
        }

        Text {
          text: (modelData.role || "").toUpperCase()
          color: Theme.textSecondary
          font.pixelSize: Theme.fontSizeCaption
          font.family: Theme.fontFamilyMono
          width: parent.width * 0.6
        }
      }
    }

    Divider {}

    Row {
      spacing: Theme.spaceSm
      Repeater {
        model: ["SPACE GROTESK", "SPACE MONO", "DOTO"]
        delegate: Badge {
          text: modelData
          variant: "default"
          size: "sm"
        }
      }
    }
  }
}
