pragma Singleton

import QtQuick

/*
    `config["option"]` is used in some places instead of `config.boolValue("option")` so we can default to `true`.
    https://github.com/sddm/sddm/wiki/Theming#new-explicitly-typed-api-since-sddm-020
*/
QtObject {
    // [General]
    property real generalScale: config.realValue("scale") || 1.0
    property bool enableAnimations: config['enable-animations'] === "false" ? false : true
    property color accent: "#5B9BF6"
    property int shellMode: 0
    property string animatedBackgroundPlaceholder: config.stringValue("animated-background-placeholder")
    property string backgroundFillMode: config.stringValue("background-fill-mode") || "fill"

    // Dynamic theme.json styles (loaded at startup)
    property color backgroundColor: "#000000"
    property color backgroundSecondaryColor: "#111111"
    property color borderColor: "#222222"
    property color textPrimaryColor: "#E8E8E8"
    property color textSecondaryColor: "#999999"
    property string themeFontFamily: "Space Grotesk, sans-serif"
    property int themeControlHeight: 36
    property int themeRadiusSmall: 4
    property int themeRadiusMedium: 8
    property int themeRadiusUI: 12

    // [LoginScreen]
    property string loginScreenBackground: config.stringValue("LoginScreen/background") || "default.jpg"
    property string wallpaperPath: ""
    property bool loginScreenUseBackgroundColor: config.boolValue('LoginScreen/use-background-color')
    property color loginScreenBackgroundColor: config.stringValue("LoginScreen/background-color") || backgroundColor
    property int loginScreenBlur: config.intValue("LoginScreen/blur")
    property real loginScreenBrightness: config.realValue("LoginScreen/brightness")
    property real loginScreenSaturation: config.realValue("LoginScreen/saturation")
    property int loginScreenBlurTyping: config.intValue("LoginScreen/blur-typing") || 28
    property real loginScreenBrightnessTyping: config.realValue("LoginScreen/brightness-typing")
    property real loginScreenSaturationTyping: config.realValue("LoginScreen/saturation-typing")

    // [LoginScreen.LoginArea]
    property string loginAreaPosition: config.stringValue("LoginScreen.LoginArea/position") || "center"
    property int loginAreaMargin: config.intValue("LoginScreen.LoginArea/margin")

    // [LoginScreen.LoginArea.Avatar]
    property string avatarShape: config.stringValue("LoginScreen.LoginArea.Avatar/shape") || "circle"
    property int avatarBorderRadius: config.intValue("LoginScreen.LoginArea.Avatar/border-radius") || themeRadiusMedium
    property int avatarActiveSize: config.intValue("LoginScreen.LoginArea.Avatar/active-size") || 80
    property int avatarInactiveSize: config.intValue("LoginScreen.LoginArea.Avatar/inactive-size") || 56
    property real avatarInactiveOpacity: config.realValue("LoginScreen.LoginArea.Avatar/inactive-opacity") || 0.35
    property int avatarActiveBorderSize: config.intValue("LoginScreen.LoginArea.Avatar/active-border-size") || 0
    property int avatarInactiveBorderSize: config.intValue("LoginScreen.LoginArea.Avatar/inactive-border-size") || 0
    property color avatarActiveBorderColor: accent
    property color avatarInactiveBorderColor: config.stringValue("LoginScreen.LoginArea.Avatar/inactive-border-color") || borderColor

    // [LoginScreen.LoginArea.Username]
    property string usernameFontFamily: config.stringValue("LoginScreen.LoginArea.Username/font-family") || themeFontFamily
    property int usernameFontSize: config.intValue("LoginScreen.LoginArea.Username/font-size") || 16
    property int usernameFontWeight: config.intValue("LoginScreen.LoginArea.Username/font-weight") || 600
    property color usernameColor: config.stringValue("LoginScreen.LoginArea.Username/color") || textPrimaryColor
    property int usernameMargin: config.intValue("LoginScreen.LoginArea.Username/margin") || 12

    // [LoginScreen.LoginArea.PasswordInput]
    property int passwordInputWidth: config.intValue("LoginScreen.LoginArea.PasswordInput/width") || 240
    property int passwordInputHeight: config.intValue("LoginScreen.LoginArea.PasswordInput/height") || themeControlHeight
    property bool passwordInputDisplayIcon: config['LoginScreen.LoginArea.PasswordInput/display-icon'] === "false" ? false : true
    property string passwordInputFontFamily: config.stringValue("LoginScreen.LoginArea.PasswordInput/font-family") || themeFontFamily
    property int passwordInputFontSize: config.intValue("LoginScreen.LoginArea.PasswordInput/font-size") || 13
    property string passwordInputIcon: config.stringValue("LoginScreen.LoginArea.PasswordInput/icon") || "password.svg"
    property int passwordInputIconSize: config.intValue("LoginScreen.LoginArea.PasswordInput/icon-size") || 14
    property color passwordInputContentColor: config.stringValue("LoginScreen.LoginArea.PasswordInput/content-color") || textPrimaryColor
    property color passwordInputBackgroundColor: config.stringValue("LoginScreen.LoginArea.PasswordInput/background-color") || backgroundSecondaryColor
    property real passwordInputBackgroundOpacity: config.realValue("LoginScreen.LoginArea.PasswordInput/background-opacity")
    property int passwordInputBorderSize: config.intValue("LoginScreen.LoginArea.PasswordInput/border-size")
    property color passwordInputBorderColor: config.stringValue("LoginScreen.LoginArea.PasswordInput/border-color") || borderColor
    property int passwordInputBorderRadiusLeft: config.intValue("LoginScreen.LoginArea.PasswordInput/border-radius-left") || themeRadiusUI
    property int passwordInputBorderRadiusRight: config.intValue("LoginScreen.LoginArea.PasswordInput/border-radius-right") || themeRadiusUI
    property int passwordInputMarginTop: config.intValue("LoginScreen.LoginArea.PasswordInput/margin-top")
    property string passwordInputMaskedCharacter: "\u25CF"

    // [LoginScreen.LoginArea.LoginButton]
    property color loginButtonBackgroundColor: accent
    property real loginButtonBackgroundOpacity: config.realValue("LoginScreen.LoginArea.LoginButton/background-opacity")
    property color loginButtonActiveBackgroundColor: accent
    property real loginButtonActiveBackgroundOpacity: config.realValue("LoginScreen.LoginArea.LoginButton/active-background-opacity")
    property string loginButtonIcon: config.stringValue("LoginScreen.LoginArea.LoginButton/icon") || "arrow-right.svg"
    property int loginButtonIconSize: config.intValue("LoginScreen.LoginArea.LoginButton/icon-size") || 16
    property color loginButtonContentColor: config.stringValue("LoginScreen.LoginArea.LoginButton/content-color") || Config.contrastTextColor(accent)
    property color loginButtonActiveContentColor: config.stringValue("LoginScreen.LoginArea.LoginButton/active-content-color") || Config.contrastTextColor(accent)
    property int loginButtonBorderSize: config.intValue("LoginScreen.LoginArea.LoginButton/border-size")
    property color loginButtonBorderColor: accent
    property int loginButtonBorderRadiusLeft: config.intValue("LoginScreen.LoginArea.LoginButton/border-radius-left") || themeRadiusUI
    property int loginButtonBorderRadiusRight: config.intValue("LoginScreen.LoginArea.LoginButton/border-radius-right") || themeRadiusUI
    property int loginButtonMarginLeft: config.intValue("LoginScreen.LoginArea.LoginButton/margin-left")
    property bool loginButtonShowTextIfNoPassword: config['LoginScreen.LoginArea.LoginButton/show-text-if-no-password'] === "false" ? false : true
    property bool loginButtonHideIfNotNeeded: config.boolValue("LoginScreen.LoginArea.LoginButton/hide-if-not-needed")
    property string loginButtonFontFamily: config.stringValue("LoginScreen.LoginArea.LoginButton/font-family") || themeFontFamily
    property int loginButtonFontSize: config.intValue("LoginScreen.LoginArea.LoginButton/font-size") || 12
    property int loginButtonFontWeight: config.intValue("LoginScreen.LoginArea.LoginButton/font-weight") || 600

    // [LoginScreen.LoginArea.Spinner]
    property bool spinnerDisplayText: config['LoginScreen.LoginArea.Spinner/display-text'] === "false" ? false : true
    property string spinnerText: config.stringValue("LoginScreen.LoginArea.Spinner/text") || "Logging in"
    property string spinnerFontFamily: config.stringValue("LoginScreen.LoginArea.Spinner/font-family") || themeFontFamily
    property int spinnerFontWeight: config.intValue("LoginScreen.LoginArea.Spinner/font-weight") || 400
    property int spinnerFontSize: config.intValue("LoginScreen.LoginArea.Spinner/font-size") || 12
    property int spinnerIconSize: config.intValue("LoginScreen.LoginArea.Spinner/icon-size") || 24
    property string spinnerIcon: config.stringValue("LoginScreen.LoginArea.Spinner/icon") || "spinner.svg"
    property color spinnerColor: accent
    property int spinnerSpacing: config.intValue("LoginScreen.LoginArea.Spinner/spacing")

    // [LoginScreen.LoginArea.WarningMessage]
    property string warningMessageFontFamily: config.stringValue("LoginScreen.LoginArea.WarningMessage/font-family") || themeFontFamily
    property int warningMessageFontSize: config.intValue("LoginScreen.LoginArea.WarningMessage/font-size") || 11
    property int warningMessageFontWeight: config.intValue("LoginScreen.LoginArea.WarningMessage/font-weight") || 400
    property color warningMessageNormalColor: config.stringValue("LoginScreen.LoginArea.WarningMessage/normal-color") || textSecondaryColor
    property color warningMessageWarningColor: accent
    property color warningMessageErrorColor: accent
    property int warningMessageMarginTop: config.intValue("LoginScreen.LoginArea.WarningMessage/margin-top")

    // [LoginScreen.MenuArea.Buttons]
    property int menuAreaButtonsMarginTop: config.intValue("LoginScreen.MenuArea.Buttons/margin-top") || 40
    property int menuAreaButtonsMarginRight: config.intValue("LoginScreen.MenuArea.Buttons/margin-right") || 40
    property int menuAreaButtonsMarginBottom: config.intValue("LoginScreen.MenuArea.Buttons/margin-bottom") || 40
    property int menuAreaButtonsMarginLeft: config.intValue("LoginScreen.MenuArea.Buttons/margin-left") || 40
    property int menuAreaButtonsSize: config.intValue("LoginScreen.MenuArea.Buttons/size") || 32
    property int menuAreaButtonsBorderRadius: config.intValue("LoginScreen.MenuArea.Buttons/border-radius") || themeRadiusUI
    property int menuAreaButtonsSpacing: config.intValue("LoginScreen.MenuArea.Buttons/spacing") || 6
    property string menuAreaButtonsFontFamily: config.stringValue("LoginScreen.MenuArea.Buttons/font-family") || themeFontFamily

    // [LoginScreen.MenuArea.Popups]
    property int menuAreaPopupsMaxHeight: config.intValue("LoginScreen.MenuArea.Popups/max-height") || 300
    property int menuAreaPopupsItemHeight: config.intValue("LoginScreen.MenuArea.Popups/item-height") || 32
    property int menuAreaPopupsSpacing: config.intValue("LoginScreen.MenuArea.Popups/item-spacing")
    property int menuAreaPopupsPadding: config.intValue("LoginScreen.MenuArea.Popups/padding")
    property bool menuAreaPopupsDisplayScrollbar: config["LoginScreen.MenuArea.Popups/display-scrollbar"] === "false" ? false : true
    property int menuAreaPopupsMargin: config.intValue("LoginScreen.MenuArea.Popups/margin")
    property color menuAreaPopupsBackgroundColor: config.stringValue("LoginScreen.MenuArea.Popups/background-color") || backgroundSecondaryColor
    property real menuAreaPopupsBackgroundOpacity: config.realValue("LoginScreen.MenuArea.Popups/background-opacity")
    property color menuAreaPopupsActiveOptionBackgroundColor: accent
    property real menuAreaPopupsActiveOptionBackgroundOpacity: config.realValue("LoginScreen.MenuArea.Popups/active-option-background-opacity")
    property color menuAreaPopupsContentColor: config.stringValue("LoginScreen.MenuArea.Popups/content-color") || textSecondaryColor
    property color menuAreaPopupsActiveContentColor: config.stringValue("LoginScreen.MenuArea.Popups/active-content-color") || textPrimaryColor
    property string menuAreaPopupsFontFamily: config.stringValue("LoginScreen.MenuArea.Popups/font-family") || themeFontFamily
    property int menuAreaPopupsBorderSize: config.intValue("LoginScreen.MenuArea.Popups/border-size")
    property color menuAreaPopupsBorderColor: config.stringValue("LoginScreen.MenuArea.Popups/border-color") || borderColor
    property int menuAreaPopupsFontSize: config.intValue("LoginScreen.MenuArea.Popups/font-size") || 11
    property int menuAreaPopupsIconSize: config.intValue("LoginScreen.MenuArea.Popups/icon-size") || 14

    // [LoginScreen.MenuArea.Session]
    property bool sessionDisplay: config["LoginScreen.MenuArea.Session/display"] === "false" ? false : true
    property string sessionPosition: config.stringValue("LoginScreen.MenuArea.Session/position")
    property int sessionIndex: config.intValue("LoginScreen.MenuArea.Session/index")
    property string sessionPopupDirection: config.stringValue("LoginScreen.MenuArea.Session/popup-direction") || "up"
    property string sessionPopupAlign: config.stringValue("LoginScreen.MenuArea.Session/popup-align") || "center"
    property bool sessionDisplaySessionName: config['LoginScreen.MenuArea.Session/display-session-name'] === "false" ? false : true
    property int sessionButtonWidth: config.intValue("LoginScreen.MenuArea.Session/button-width") || 200
    property int sessionPopupWidth: config.intValue("LoginScreen.MenuArea.Session/popup-width") || 200
    property color sessionBackgroundColor: config.stringValue("LoginScreen.MenuArea.Session/background-color") || backgroundSecondaryColor
    property real sessionBackgroundOpacity: config.realValue("LoginScreen.MenuArea.Session/background-opacity")
    property real sessionActiveBackgroundOpacity: config.realValue("LoginScreen.MenuArea.Session/active-background-opacity")
    property color sessionContentColor: config.stringValue("LoginScreen.MenuArea.Session/content-color") || textSecondaryColor
    property color sessionActiveContentColor: config.stringValue("LoginScreen.MenuArea.Session/active-content-color") || textPrimaryColor
    property int sessionBorderSize: config.intValue("LoginScreen.MenuArea.Session/border-size")
    property int sessionFontSize: config.intValue("LoginScreen.MenuArea.Session/font-size") || 10
    property int sessionIconSize: config.intValue("LoginScreen.MenuArea.Session/icon-size") || 14

    // [LoginScreen.MenuArea.Layout]
    property bool layoutDisplay: config["LoginScreen.MenuArea.Layout/display"] === "false" ? false : true
    property string layoutPosition: config.stringValue("LoginScreen.MenuArea.Layout/position")
    property int layoutIndex: config.intValue("LoginScreen.MenuArea.Layout/index")
    property string layoutPopupDirection: config.stringValue("LoginScreen.MenuArea.Layout/popup-direction") || "up"
    property string layoutPopupAlign: config.stringValue("LoginScreen.MenuArea.Layout/popup-align") || "center"
    property int layoutPopupWidth: config.intValue("LoginScreen.MenuArea.Layout/popup-width") || 180
    property bool layoutDisplayLayoutName: config['LoginScreen.MenuArea.Layout/display-layout-name'] === "false" ? false : true
    property color layoutBackgroundColor: config.stringValue("LoginScreen.MenuArea.Layout/background-color") || backgroundSecondaryColor
    property real layoutBackgroundOpacity: config.realValue("LoginScreen.MenuArea.Layout/background-opacity")
    property real layoutActiveBackgroundOpacity: config.realValue("LoginScreen.MenuArea.Layout/active-background-opacity")
    property color layoutContentColor: config.stringValue("LoginScreen.MenuArea.Layout/content-color") || textSecondaryColor
    property color layoutActiveContentColor: config.stringValue("LoginScreen.MenuArea.Layout/active-content-color") || textPrimaryColor
    property int layoutBorderSize: config.intValue("LoginScreen.MenuArea.Layout/border-size")
    property int layoutFontSize: config.intValue("LoginScreen.MenuArea.Layout/font-size") || 10
    property string layoutIcon: config.stringValue("LoginScreen.MenuArea.Layout/icon") || "language.svg"
    property int layoutIconSize: config.intValue("LoginScreen.MenuArea.Layout/icon-size") || 14

    // [LoginScreen.MenuArea.Power]
    property bool powerDisplay: config["LoginScreen.MenuArea.Power/display"] === "false" ? false : true
    property string powerPosition: config.stringValue("LoginScreen.MenuArea.Power/position")
    property int powerIndex: config.intValue("LoginScreen.MenuArea.Power/index")
    property string powerPopupDirection: config.stringValue("LoginScreen.MenuArea.Power/popup-direction") || "up"
    property string powerPopupAlign: config.stringValue("LoginScreen.MenuArea.Power/popup-align") || "center"
    property int powerPopupWidth: config.intValue("LoginScreen.MenuArea.Power/popup-width") || 100
    property color powerBackgroundColor: config.stringValue("LoginScreen.MenuArea.Power/background-color") || backgroundSecondaryColor
    property real powerBackgroundOpacity: config.realValue("LoginScreen.MenuArea.Power/background-opacity")
    property real powerActiveBackgroundOpacity: config.realValue("LoginScreen.MenuArea.Power/active-background-opacity")
    property color powerContentColor: config.stringValue("LoginScreen.MenuArea.Power/content-color") || textSecondaryColor
    property color powerActiveContentColor: config.stringValue("LoginScreen.MenuArea.Power/active-content-color") || textPrimaryColor
    property int powerBorderSize: config.intValue("LoginScreen.MenuArea.Power/border-size")
    property string powerIcon: config.stringValue("LoginScreen.MenuArea.Power/icon") || "power.svg"
    property int powerIconSize: config.intValue("LoginScreen.MenuArea.Power/icon-size") || 14

    // [Tooltips]
    property bool tooltipsEnable: config['Tooltips/enable'] === "false" ? false : true
    property string tooltipsFontFamily: config.stringValue("Tooltips/font-family") || themeFontFamily
    property int tooltipsFontSize: config.intValue("Tooltips/font-size") || 10
    property color tooltipsContentColor: config.stringValue("Tooltips/content-color") || textPrimaryColor
    property color tooltipsBackgroundColor: config.stringValue("Tooltips/background-color") || backgroundSecondaryColor
    property real tooltipsBackgroundOpacity: config.realValue("Tooltips/background-opacity")
    property int tooltipsBorderRadius: config.intValue("Tooltips/border-radius") || themeRadiusSmall
    property bool tooltipsDisableUser: config.boolValue("Tooltips/disable-user")
    property bool tooltipsDisableLoginButton: config.boolValue("Tooltips/disable-login-button")

    function contrastTextColor(bgColor: color): color {
        var lum = 0.2126 * bgColor.r + 0.7152 * bgColor.g + 0.0722 * bgColor.b
        return lum >= 0.4 ? "#000000" : "#FFFFFF"
    }

    function sortMenuButtons() {
        var menus = [];
        var available_positions = ["top-left", "top-center", "top-right", "center-left", "center-right", "bottom-left", "bottom-center", "bottom-right"];

        if (sessionDisplay)
            menus.push({
                name: "session",
                index: sessionIndex,
                def_index: 0,
                position: available_positions.includes(sessionPosition) ? sessionPosition : "bottom-left"
            });

        if (layoutDisplay)
            menus.push({
                name: "layout",
                index: layoutIndex,
                def_index: 1,
                position: available_positions.includes(layoutPosition) ? layoutPosition : "bottom-right"
            });

        if (powerDisplay)
            menus.push({
                name: "power",
                index: powerIndex,
                def_index: 2,
                position: available_positions.includes(powerPosition) ? powerPosition : "bottom-right"
            });

        return menus.sort((c, n) => c.index - n.index || c.def_index - n.def_index);
    }

    function getIcon(iconName) {
        var ext_arr = iconName.split(".");
        var ext = ext_arr.length > 1 ? ext_arr[ext_arr.length - 1] : "";
        return `../icons/${iconName}${ext === "" ? ".svg" : ""}`;
    }

    Component.onCompleted: {
        var rawPath = config.stringValue("theme-json-path") || "";
        var themePath = rawPath.startsWith("file://") ? rawPath : (rawPath ? "file://" + rawPath : "");
        var xhr = new XMLHttpRequest();
        xhr.open("GET", themePath || "file:///tmp/sddm-theme.json");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText);
                    var acc = data["accent"];
                    if (acc && /^#[0-9a-fA-F]{6}$/.test(acc)) {
                        accent = acc;
                    }
                    var mode = data["shellMode"];
                    if (mode !== undefined && mode >= 0 && mode <= 4) {
                        shellMode = mode;
                    }
                    var bg = data["background"];
                    if (bg) backgroundColor = bg;
                    var bgSec = data["backgroundSecondary"];
                    if (bgSec) backgroundSecondaryColor = bgSec;
                    var borderCol = data["border"];
                    if (borderCol) borderColor = borderCol;
                    var textPri = data["textPrimary"];
                    if (textPri) textPrimaryColor = textPri;
                    var textSec = data["textSecondary"];
                    if (textSec) textSecondaryColor = textSec;
                    var ff = data["fontFamily"];
                    if (ff) themeFontFamily = ff;
                    var ch = data["controlHeight"];
                    if (ch) themeControlHeight = ch;
                    var radSm = data["radiusSmall"];
                    if (radSm) themeRadiusSmall = radSm;
                    var radMed = data["radiusMedium"];
                    if (radMed) themeRadiusMedium = radMed;
                    var radUI = data["radiusUI"];
                    if (radUI) themeRadiusUI = radUI;
                    var wp = data["wallpaper"];
                    if (wp) wallpaperPath = wp;
                } catch(e) {}
            }
        };
        xhr.send();
    }
}
