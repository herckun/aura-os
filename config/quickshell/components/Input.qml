import QtQuick
import QtQuick.Layouts
import "../styles"
import "../core"

Rectangle {
    id: root

    // ── Signals ──────────────────────────────────────────────
    signal textEdited(string text)
    signal accepted
    signal cleared
    signal upPressed
    signal downPressed
    signal tabPressed
    signal backtabPressed
    signal keyPressed(int key)

    // ── Properties ───────────────────────────────────────────
    property string placeholder: ""
    property string defaultText: ""
    property string text: input.text
    property string iconName: ""
    property bool showClearButton: true
    property int maxHeight: Theme.controlHeight
    property int fontSize: Theme.fontSizeCaption
    property int iconSize: Theme.fontSizeCaption
    property string fontFamily: Theme.fontFamilyMono
    property bool persistentPlaceholder: false
    property alias input: input
    property bool focused: input.activeFocus
    property int echoMode: TextInput.Normal
    property bool revealable: false
    property var blockedKeys: []
    property bool escapeClears: true
    property color focusedBorderColor: Theme.accent
    property color iconColor: Theme.textDisabled
    property color iconFocusedColor: focusedBorderColor
    property bool defaultFocus: false

    width: parent ? parent.width : 200
    height: Math.max(maxHeight, input.implicitHeight + Theme.spaceXs * 2)
    radius: Theme.radiusMedium
    antialiasing: true
    color: Theme.backgroundSecondary
    border.width: Theme.borderWidth
    border.color: input.activeFocus ? focusedBorderColor : Theme.border

    Behavior on border.color {
        enabled: Theme.animationsEnabled
        ColorAnimation { duration: Theme.animationFast }
    }

    function forceFocus(): void {
        input.forceActiveFocus()
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        onClicked: input.forceActiveFocus()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spaceMd
        anchors.rightMargin: Theme.spaceMd
        spacing: Theme.spaceSm

        Icon {
            source: iconName.length > 0 ? Icons.get(iconName) : ""
            visible: iconName.length > 0
            size: root.iconSize
            color: input.activeFocus ? root.iconFocusedColor : root.iconColor
            Layout.alignment: Qt.AlignVCenter
        }

        TextInput {
            id: input
            Layout.fillWidth: true
            color: Theme.textDisplay
            font.pixelSize: root.fontSize
            font.family: root.fontFamily
            clip: true
            selectByMouse: true
            selectionColor: Theme.accent
            verticalAlignment: TextInput.AlignVCenter
            echoMode: root.revealable && revealToggle.revealed ? TextInput.Normal : root.echoMode

            Component.onCompleted: if (root.defaultText.length > 0) text = root.defaultText

            Text {
                text: root.placeholder
                color: Theme.textDisabled
                font: input.font
                visible: !input.text && (root.persistentPlaceholder || !input.activeFocus)
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
            }

            onTextChanged: root.textEdited(text)
            onAccepted: root.accepted()

            Keys.onEscapePressed: function(event) {
                if (root.escapeClears) {
                    text = ""
                    focus = false
                    root.cleared()
                    event.accepted = true
                } else {
                    event.accepted = false
                }
            }

            Keys.onUpPressed: function(event) { root.upPressed(); event.accepted = false }
            Keys.onDownPressed: function(event) { root.downPressed(); event.accepted = false }
            Keys.onTabPressed: function(event) { root.tabPressed(); event.accepted = false }
            Keys.onBacktabPressed: function(event) { root.backtabPressed(); event.accepted = false }

            Keys.onPressed: function(event) {
                root.keyPressed(event.key)
                if (root.blockedKeys.indexOf(event.key) >= 0) {
                    event.accepted = true
                }
            }
        }

        Rectangle {
            id: revealToggle
            property bool revealed: false
            width: Theme.controlHeightSmall
            height: width
            radius: Theme.radiusSmall
            antialiasing: true
            color: revealArea.containsMouse ? Theme.controlBackgroundHover : "transparent"
            visible: root.revealable

            Icon {
                anchors.centerIn: parent
                source: Icons.get(revealToggle.revealed ? "unlock" : "lock")
                size: Theme.fontSizeCaption
                color: revealArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
            }

            MouseArea {
                id: revealArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: revealToggle.revealed = !revealToggle.revealed
            }
        }

        Button {
            shape: "icon"
            icon: "x"
            size: "xs"
            visible: root.showClearButton && input.text.length > 0
            onClicked: {
                input.text = ""
                root.cleared()
            }
        }
    }
}
