import QtQuick
import QtQuick.Layouts
import "../styles"

Surface {
    id: root

    property string title: ""
    property string subtitle: ""
    property color titleColor: Theme.textPrimary
    property bool titleStrikeout: false
    property alias leading: leadingSlot.data
    property alias trailing: trailingSlot.data
    property bool hoverHighlight: true
    readonly property bool hovered: hover.hovered

    signal clicked

    implicitHeight: Math.max(Theme.controlHeight + Theme.spaceMd, rowLayout.implicitHeight + padding * 2)
    height: implicitHeight
    bordered: true
    padding: Theme.spaceSm
    radius: Theme.radiusMedium
    clip: true
    color: (root.hoverHighlight && hover.hovered) ? Theme.controlBackgroundHover : "transparent"

    Behavior on color {
        enabled: Theme.animationsEnabled
        ColorAnimation {
            duration: Theme.animationFast
        }
    }

    HoverHandler {
        id: hover
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: Theme.spaceMd

        Item {
            id: leadingSlot
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
            visible: children.length > 0
        }

        Column {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Theme.spaceXxs

            Text {
                width: parent.width
                text: root.title
                visible: root.title.length > 0
                color: root.titleColor
                font.pixelSize: Theme.fontSizeSubhead
                font.family: Theme.fontFamily
                font.strikeout: root.titleStrikeout
                elide: Text.ElideRight

                Behavior on color {
                    enabled: Theme.animationsEnabled
                    ColorAnimation {
                        duration: Theme.animationFast
                    }
                }
            }
            Text {
                width: parent.width
                text: root.subtitle
                visible: root.subtitle.length > 0
                color: Theme.textDisabled
                font.pixelSize: Theme.fontSizeCaption
                font.family: Theme.fontFamilyMono
                elide: Text.ElideRight
            }
        }

        Item {
            id: trailingSlot
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
            visible: children.length > 0
        }
    }
}
