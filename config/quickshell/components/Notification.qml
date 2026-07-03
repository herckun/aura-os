import QtQuick
import QtQuick.Layouts
import "../styles"
import "../core"

Surface {
    id: root

    // ── Properties ─────────────────────────────────────────────
    property string icon: ""
    property string summary: ""
    property string body: ""
    property string appName: ""
    property int urgency: 1
    property var notifTime: new Date()
    property bool showDismiss: true
    property int previewLines: 3

    // ── Signals ────────────────────────────────────────────────
    signal dismissed

    // ── Geometry ───────────────────────────────────────────────
    level: 2
    radius: Theme.radiusMedium
    border.color: Theme.border
    clip: true
    implicitHeight: contentCol.implicitHeight + Theme.spaceMd * 2

    // ── Urgency indicator strip ────────────────────────────
    Rectangle {
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
        }
        // inset by the corner radius — QML clip is rectangular, not rounded
        anchors.topMargin: Theme.radiusMedium
        anchors.bottomMargin: Theme.radiusMedium
        anchors.leftMargin: Theme.borderWidth
        width: 3
        radius: width / 2
        color: root.urgency === 2 ? Theme.error : root.urgency === 0 ? Theme.textDisabled : Theme.accent
        visible: root.urgency !== 1
    }

    function relativeTime(date: var): string {
        var diff = (new Date() - date) / 1000;
        if (diff < 60)
            return "NOW";
        if (diff < 3600)
            return Math.floor(diff / 60) + "M";
        if (diff < 86400)
            return Math.floor(diff / 3600) + "H";
        return Math.floor(diff / 86400) + "D";
    }

    Column {
        id: contentCol
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
        anchors.leftMargin: Theme.spaceMd
        anchors.rightMargin: Theme.spaceMd
        anchors.topMargin: Theme.spaceMd
        anchors.bottomMargin: Theme.spaceMd
        spacing: Theme.spaceSm

        RowLayout {
            width: parent.width
            spacing: Theme.spaceSm

            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: Theme.radiusSmall
                color: Theme.accent

                Icon {
                    anchors.centerIn: parent
                    source: root.icon.indexOf("/") >= 0 ? root.icon : Icons.get(root.icon || "bell")
                    size: 24
                    color: Theme.background
                    byPassColorOverlay: true
                }
            }

            Text {
                text: (root.appName || "APP").toUpperCase()
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSizeMicro
                font.family: Theme.fontFamilyMono
                font.letterSpacing: 0.1
                Layout.fillWidth: true
            }

            Text {
                text: root.relativeTime(root.notifTime)
                color: Theme.textDisabled
                font.pixelSize: Theme.fontSizeMicro
                font.family: Theme.fontFamilyMono
                font.letterSpacing: 0.08
            }

            Button {
                shape: "icon"
                icon: "close"
                size: "xs"
                visible: root.showDismiss
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                Layout.alignment: Qt.AlignTop
                onClicked: root.dismissed()
            }
        }

        Text {
            width: parent.width
            text: root.summary || "Notification"
            color: Theme.textDisplay
            font.pixelSize: Theme.fontSizeLabel
            font.family: Theme.fontFamilyMono
            font.weight: Font.Bold
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        Text {
            width: parent.width
            text: root.body || ""
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSizeCaption
            font.family: Theme.fontFamily
            maximumLineCount: root.previewLines
            elide: Text.ElideRight
            wrapMode: Text.WordWrap
            lineHeight: 1.3
            visible: root.body !== ""
        }
    }
}
