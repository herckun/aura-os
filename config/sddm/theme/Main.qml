import "."
import QtQuick
import SddmComponents 2.0
import QtQuick.Effects
import QtMultimedia
import "components"

Item {
    id: root

    TextConstants {
        id: textConstants
    }

    property bool capsLockOn: false
    property bool typingPassword: false
    Component.onCompleted: {
        if (keyboard)
            capsLockOn = keyboard.capsLock;
    }
    onCapsLockOnChanged: {
        loginScreen.updateCapsLock();
    }

    Item {
        id: mainFrame
        property variant geometry: screenModel.geometry(screenModel.primary)
        x: geometry.x
        y: geometry.y
        width: geometry.width
        height: geometry.height

        Component.onCompleted: {
            if (Config.generalScale === 1.0) {
                Config.generalScale = height / 1080;
            }
        }

        Image {
            id: backgroundImage
            property string tsource: Config.wallpaperPath || Config.loginScreenBackground

            property bool isVideo: {
                if (!tsource || tsource.toString().length === 0)
                    return false;
                var parts = tsource.toString().split(".");
                if (parts.length === 0)
                    return false;
                var ext = parts[parts.length - 1];
                return ["avi", "mp4", "mov", "mkv", "m4v", "webm"].indexOf(ext) !== -1;
            }
            property bool displayColor: Config.loginScreenUseBackgroundColor
            property string placeholder: Config.animatedBackgroundPlaceholder

            anchors.fill: parent
            source: !isVideo ? (tsource.indexOf("/") === 0 ? tsource : "backgrounds/" + tsource) : ""
            cache: true
            mipmap: true
            fillMode: {
                if (Config.backgroundFillMode === "stretch")
                    return Image.Stretch;
                else if (Config.backgroundFillMode === "fit")
                    return Image.PreserveAspectFit;
                else
                    return Image.PreserveAspectCrop;
            }

            function updateVideo() {
                if (isVideo && tsource.toString().length > 0) {
                    backgroundVideo.source = Qt.resolvedUrl("backgrounds/" + tsource);
                    if (placeholder.length > 0)
                        source = "backgrounds/" + placeholder;
                }
            }

            onSourceChanged: {
                updateVideo();
            }
            Component.onCompleted: {
                updateVideo();
            }
            onStatusChanged: {
                if (status === Image.Error) {
                    if (source !== "backgrounds/default.jpg" && source !== "") {
                        source = "backgrounds/default.jpg";
                    } else if (source === "backgrounds/default.jpg") {
                        displayColor = true;
                    }
                }
            }

            Rectangle {
                id: backgroundColor
                anchors.fill: parent
                anchors.margins: 0
                color: Config.loginScreenUseBackgroundColor ? Config.loginScreenBackgroundColor : "black"
                visible: parent.displayColor || (backgroundVideo.visible && parent.placeholder.length === 0)
            }

            Video {
                id: backgroundVideo
                anchors.fill: parent
                visible: parent.isVideo && !parent.displayColor
                enabled: visible
                autoPlay: false
                loops: MediaPlayer.Infinite
                muted: true
                fillMode: {
                    if (Config.backgroundFillMode === "stretch")
                        return VideoOutput.Stretch;
                    else if (Config.backgroundFillMode === "fit")
                        return VideoOutput.PreserveAspectFit;
                    else
                        return VideoOutput.PreserveAspectCrop;
                }
                onSourceChanged: {
                    if (source && source.toString().length > 0) {
                        backgroundVideo.play();
                    }
                }
                onErrorOccurred: function (error) {
                    if (error !== MediaPlayer.NoError && (!backgroundImage.placeholder || backgroundImage.placeholder.length === 0)) {
                        backgroundImage.displayColor = true;
                    }
                }
            }

            Component.onDestruction: {
                if (backgroundVideo) {
                    backgroundVideo.stop();
                    backgroundVideo.source = "";
                }
            }
        }
        MultiEffect {
            id: backgroundEffect
            source: backgroundImage
            anchors.fill: parent
            blurEnabled: backgroundImage.visible && blurMax > 0
            blur: blurMax > 0 ? 1.0 : 0.0
            autoPaddingEnabled: false

            property int blurMax: root.typingPassword ? Config.loginScreenBlurTyping : Config.loginScreenBlur
            property real brightness: root.typingPassword ? Config.loginScreenBrightnessTyping : Config.loginScreenBrightness
            property real saturation: root.typingPassword ? Config.loginScreenSaturationTyping : Config.loginScreenSaturation

            Behavior on blurMax {
                enabled: Config.enableAnimations
                NumberAnimation {
                    duration: 400
                }
            }
            Behavior on brightness {
                enabled: Config.enableAnimations
                NumberAnimation {
                    duration: 400
                }
            }
            Behavior on saturation {
                enabled: Config.enableAnimations
                NumberAnimation {
                    duration: 400
                }
            }
        }

        Rectangle {
            id: backdrop
            anchors.fill: parent
            color: Config.loginScreenUseBackgroundColor ? Config.loginScreenBackgroundColor : "#000000"
            opacity: Config.loginScreenUseBackgroundColor ? 0.0 : (root.typingPassword ? 0.8 : 0.7)
            z: 1

            Behavior on opacity {
                enabled: Config.enableAnimations
                NumberAnimation {
                    duration: 400
                }
            }
        }

        LoginScreen {
            id: loginScreen
            z: 2
            anchors.fill: parent
            enabled: true
            onPasswordFocusChanged: function (focused) {
                root.typingPassword = focused;
            }
        }
    }
}
