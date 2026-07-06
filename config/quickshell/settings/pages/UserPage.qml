import QtQuick
import QtQuick.Layouts
import "../../core"
import "../../styles"
import "../../services"
import "../../components"
import "layout"

Column {
    id: root
    spacing: Theme.spaceLg
    width: parent.width

    PageHeader {
        title: "USER"
    }

    Card {
        width: parent.width
        title: "PROFILE"
        Stage {
            width: parent.width
            minHeight: 190

            Column {
                width: parent.width
                spacing: Theme.spaceSm
                topPadding: Theme.spaceMd
                bottomPadding: Theme.spaceMd

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 96
                    height: 96

                    Avatar {
                        id: avatar
                        anchors.fill: parent
                        size: 96
                        source: UserService.avatarSource
                        fallbackText: UserService.initial
                        ringColor: avatarMa.containsMouse ? Theme.accent : Theme.overlay(0.25)
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Qt.rgba(0, 0, 0, 0.55)
                        visible: avatarMa.containsMouse

                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.spaceXxs

                            Icon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                source: Icons.get("pencil-simple")
                                size: 18
                                color: Theme.textDisplay
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "CHANGE"
                                color: Theme.textDisplay
                                font.pixelSize: Theme.fontSizeMicro
                                font.family: Theme.fontFamilyMono
                                font.letterSpacing: 0.1
                            }
                        }
                    }

                    MouseArea {
                        id: avatarMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: UserService.pickAvatar()
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: UserService.displayName.toUpperCase()
                    color: Theme.textDisplay
                    font.pixelSize: Theme.fontSizeTitle2
                    font.family: Theme.fontFamilyDisplay
                    font.letterSpacing: 2
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "@" + UserService.userName
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontSizeCaption
                    font.family: Theme.fontFamilyMono
                    font.letterSpacing: 0.1
                }
            }
        }

        RowLayout {
            width: parent.width
            spacing: Theme.spaceMd

            Column {
                Layout.fillWidth: true
                spacing: Theme.spaceXs

                Text {
                    text: "DISPLAY NAME"
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontSizeMicro
                    font.family: Theme.fontFamilyMono
                    font.letterSpacing: 0.12
                }

                Input {
                    id: nameField
                    width: parent.width
                    fontSize: Theme.fontSizeBody
                    placeholder: "How should we call you?"
                    defaultText: UserService.realName
                    escapeClears: false

                    Connections {
                        target: nameField.input
                        function onEditingFinished() {
                            UserService.setRealName(nameField.text);
                        }
                    }
                }
            }
        }

        Text {
            width: parent.width
            text: UserService.lastError
            color: Theme.error
            font.pixelSize: Theme.fontSizeMicro
            font.family: Theme.fontFamilyMono
            wrapMode: Text.WordWrap
            visible: UserService.lastError !== ""
        }
    }
}
