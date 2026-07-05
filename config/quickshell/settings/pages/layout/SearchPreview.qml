import QtQuick
import QtQuick.Layouts
import "../../../core"
import "../../../styles"
import "../../../services"
import "../../../components"

Stage {
  id: root

  Rectangle {
    id: panel
    width: Math.round(parent.width * 0.85)
    height: panelCol.implicitHeight + Theme.spaceMd * 2
    anchors.horizontalCenter: parent.horizontalCenter
    radius: Theme.radiusLarge
    color: Qt.rgba(0, 0, 0, 0.82)
    border.width: Theme.borderWidth
    border.color: Theme.borderVisible

    Column {
      id: panelCol
      anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceMd }
      spacing: Theme.spaceSm

      Rectangle {
        width: parent.width
        height: 38
        radius: Theme.radiusMedium
        color: Theme.backgroundSecondary
        border.width: Theme.borderWidth
        border.color: Theme.borderVisible

        Row {
          anchors { left: parent.left; leftMargin: Theme.spaceSm; verticalCenter: parent.verticalCenter }
          spacing: Theme.spaceXs

          Icon {
            anchors.verticalCenter: parent.verticalCenter
            source: Icons.get("magnifying-glass")
            size: 14
            color: Theme.accent
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "SEARCH ANYTHING…"
            color: Theme.textDisabled
            font.pixelSize: Theme.fontSizeCaption
            font.family: Theme.fontFamilyMono
            font.letterSpacing: 0.08
          }
        }
      }

      Repeater {
        model: SearchService.catalog

        delegate: Rectangle {
          id: row
          required property var modelData
          width: panelCol.width
          height: 48
          radius: Theme.radiusMedium
          color: rowHover.containsMouse ? Theme.controlBackgroundHover : Theme.controlBackground
          border.width: Theme.borderWidth
          border.color: rowHover.containsMouse ? Theme.borderActive : Theme.border
          opacity: modelData.enabled ? 1 : 0.55

          Behavior on opacity { enabled: Theme.animationsEnabled; NumberAnimation { duration: Theme.animationFast } }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spaceSm
            anchors.rightMargin: Theme.spaceSm
            spacing: Theme.spaceSm

            Rectangle {
              Layout.preferredWidth: 28
              Layout.preferredHeight: 28
              radius: Theme.radiusSmall
              color: row.modelData.enabled ? Theme.accent : Theme.controlBackgroundHover

              Icon {
                anchors.centerIn: parent
                source: Icons.get(row.modelData.icon)
                size: 14
                color: row.modelData.enabled ? Theme.contrastTextColor(Theme.accent) : Theme.textDisabled
              }
            }

            Column {
              Layout.fillWidth: true
              spacing: Theme.spaceXxs

              Text {
                width: parent.width
                text: row.modelData.label.toUpperCase()
                color: row.modelData.enabled ? Theme.textPrimary : Theme.textSecondary
                font.pixelSize: Theme.fontSizeCaption
                font.family: Theme.fontFamilyMono
                font.weight: Font.Bold
                font.letterSpacing: 0.06
                elide: Text.ElideRight
              }

              Text {
                width: parent.width
                text: row.modelData.description
                color: Theme.textDisabled
                font.pixelSize: Theme.fontSizeMicro
                font.family: Theme.fontFamilyMono
                elide: Text.ElideRight
                visible: text !== ""
              }
            }

            Row {
              spacing: Theme.spaceXxs

              Repeater {
                model: row.modelData.prefixes

                delegate: Badge {
                  required property string modelData
                  text: modelData
                  size: "sm"
                }
              }
            }

            Toggle {
              toggleWidth: 38
              toggleHeight: 20
              checked: row.modelData.enabled
              onToggled: (v) => SearchService.setProviderEnabled(row.modelData.id, v)
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
      }
    }
  }
}
