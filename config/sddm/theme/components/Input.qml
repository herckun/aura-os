import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: input

    signal accepted

    property string placeholder: ""
    property alias input: textField
    property bool isPassword: false
    property bool splitBorderRadius: false
    property alias text: textField.text
    property string icon: ""
    property bool enabled: true

    width: Config.passwordInputWidth * Config.generalScale
    height: Config.passwordInputHeight * Config.generalScale

    Rectangle {
        id: inputBg
        anchors.fill: parent
        color: Config.passwordInputBackgroundColor
        opacity: Config.passwordInputBackgroundOpacity
        radius: input.splitBorderRadius ? Config.passwordInputBorderRadiusRight * Config.generalScale : Config.passwordInputBorderRadiusLeft * Config.generalScale

        Behavior on opacity { enabled: Config.enableAnimations; NumberAnimation { duration: 200 } }
    }

    Rectangle {
        id: inputBorder
        anchors.fill: parent
        color: "transparent"
        radius: inputBg.radius
        border.width: Config.passwordInputBorderSize * Config.generalScale
        border.color: textField.activeFocus ? Config.accent : Config.passwordInputBorderColor

        Behavior on border.color { enabled: Config.enableAnimations; ColorAnimation { duration: 200 } }
    }

    TextField {
        id: textField
        anchors.fill: parent
        color: Config.passwordInputContentColor
        enabled: input.enabled
        echoMode: input.isPassword ? TextInput.Password : TextInput.Normal
        passwordCharacter: Config.passwordInputMaskedCharacter
        activeFocusOnTab: true
        selectByMouse: true
        verticalAlignment: TextField.AlignVCenter
        font.family: Config.passwordInputFontFamily
        font.pixelSize: Math.max(8, Config.passwordInputFontSize * Config.generalScale)
        background: null
        leftPadding: iconRow.x + iconRow.width + (Config.passwordInputDisplayIcon ? 4 : 12)
        rightPadding: 12
        onAccepted: input.accepted()

        Row {
            id: iconRow
            anchors.verticalCenter: parent.verticalCenter
            x: Config.passwordInputDisplayIcon ? 10 : 4
            spacing: 0

            Rectangle {
                id: iconContainer
                color: "transparent"
                visible: Config.passwordInputDisplayIcon
                height: textField.height
                width: height * 0.6

                Image {
                    id: icon
                    source: input.icon
                    anchors.centerIn: parent
                    width: Math.max(1, Config.passwordInputIconSize * Config.generalScale)
                    height: width
                    sourceSize: Qt.size(width, height)
                    fillMode: Image.PreserveAspectFit
                    opacity: input.enabled ? 1.0 : 0.3

                    Behavior on opacity { enabled: Config.enableAnimations; NumberAnimation { duration: 250 } }

                    MultiEffect {
                        source: parent
                        anchors.fill: parent
                        colorization: 1
                        colorizationColor: textField.activeFocus ? Config.accent : textField.color
                    }
                }
            }

            Text {
                id: placeholderLabel
                anchors.verticalCenter: parent.verticalCenter
                padding: 0
                visible: textField.text.length === 0 && (!textField.preeditText || textField.preeditText.length === 0)
                text: input.placeholder
                color: Config.textSecondaryColor
                font.pixelSize: Math.max(8, textField.font.pixelSize || 13)
                font.family: textField.font.family || Config.themeFontFamily
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: textField.verticalAlignment
                font.italic: false
                opacity: 0.6
            }
        }
    }
}
