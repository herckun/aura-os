import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../../styles"
import "../../core"
import "../../services"
import "../../components"

Column {
    id: root
    spacing: Theme.spaceLg
    width: parent.width

    property bool _busy: WallpaperService.downloadStatus !== ""

    property var historyModel: {
        var items = WallpaperService.wallpaperHistory;
        var max = 11;
        var result = [];
        var limit = Math.min(items.length, max);
        for (var i = 0; i < limit; i++) {
            result.push({
                path: items[i].path,
                time: items[i].time,
                isPickMore: false
            });
        }
        result.push({
            path: "",
            time: 0,
            isPickMore: true
        });
        return result;
    }

    PageHeader {
        title: "WALLPAPER"
    }

    // ── Preview + Actions Row ────────────────────────────────────────
    RowLayout {
        width: parent.width
        spacing: Theme.spaceMd

        Item {
            Layout.fillWidth: true
            Layout.preferredWidth: 5
            Layout.fillHeight: true
            Layout.preferredHeight: 220

            Surface {
                anchors.fill: parent
                radius: Theme.radiusLarge
                level: 2
            }

            Image {
                id: wallpaperImg
                anchors.fill: parent
                anchors.margins: Theme.borderWidth
                source: WallpaperService.wallpaperPath ? "file://" + WallpaperService.wallpaperPath : ""
                fillMode: Image.PreserveAspectCrop
                visible: false
                smooth: true
            }

            Rectangle {
                id: roundMask
                anchors.fill: parent
                anchors.margins: Theme.borderWidth
                radius: Theme.radiusLarge
                color: "white"
                visible: false
            }

            OpacityMask {
                anchors.fill: parent
                anchors.margins: Theme.borderWidth
                source: wallpaperImg
                maskSource: roundMask
                visible: WallpaperService.wallpaperPath !== "" && wallpaperImg.status === Image.Ready
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: 32
                radius: Theme.radiusLarge
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: "transparent"
                    }
                    GradientStop {
                        position: 1.0
                        color: "#AA000000"
                    }
                }
                visible: WallpaperService.wallpaperPath !== ""
            }

            Text {
                anchors {
                    left: parent.left
                    bottom: parent.bottom
                    leftMargin: Theme.spaceSm
                    bottomMargin: Theme.spaceXs
                }
                text: WallpaperService.wallpaperPath ? WallpaperService.wallpaperPath.split("/").pop() : ""
                color: Theme.textPrimary
                font.pixelSize: Theme.fontSizeMicro
                font.family: Theme.fontFamilyMono
                visible: WallpaperService.wallpaperPath !== ""
            }

            Rectangle {
                anchors {
                    right: parent.right
                    top: parent.top
                    rightMargin: Theme.spaceSm
                    topMargin: Theme.spaceSm
                }
                width: dlText.implicitWidth + Theme.spaceSm * 2
                height: dlText.implicitHeight + Theme.spaceXs * 2
                radius: Theme.radiusSmall
                color: Theme.accent
                visible: WallpaperService.downloadStatus !== ""

                Text {
                    id: dlText
                    anchors.centerIn: parent
                    text: WallpaperService.downloadStatus
                    color: Theme.background
                    font.pixelSize: Theme.fontSizeMicro
                    font.family: Theme.fontFamilyMono
                    font.weight: Font.Bold
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: Theme.spaceSm
                visible: WallpaperService.wallpaperPath === "" && !_busy

                Icon {
                    source: Icons.get("image")
                    size: 28
                    color: Theme.textDisabled
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    text: "NO WALLPAPER"
                    color: Theme.textDisabled
                    font.pixelSize: Theme.fontSizeMicro
                    font.family: Theme.fontFamilyMono
                    font.letterSpacing: 0.06
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        ColumnLayout {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            spacing: Theme.spaceXs

            Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: "PICK"
                size: "sm"
                paddingX: Theme.spaceSm
                paddingY: Theme.spaceMd
                busy: WallpaperService.pickerOpen
                onClicked: WallpaperService.pickWallpaper()
            }

            Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: "NEXT"
                icon: "skip-forward"
                size: "sm"
                paddingX: Theme.spaceSm
                paddingY: Theme.spaceMd
                bgColor: "transparent"
                bgHoverColor: Theme.controlBackgroundHover
                onClicked: WallpaperService.cycleWallpaper()
            }

            Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: "RANDOM"
                icon: "arrows-shuffle"
                size: "sm"
                paddingX: Theme.spaceSm
                paddingY: Theme.spaceMd
                bgColor: "transparent"
                bgHoverColor: Theme.controlBackgroundHover
                busy: WallpaperService.downloadStatus !== ""
                onClicked: {
                    NotificationService.systemNotify("WALLPAPER", "Downloading random wallpaper...", 1);
                    WallpaperService.downloadRandom();
                }
            }

            Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: "ANIME"
                icon: "cat"
                size: "sm"
                paddingX: Theme.spaceSm
                paddingY: Theme.spaceMd
                bgColor: "transparent"
                bgHoverColor: Theme.controlBackgroundHover
                busy: WallpaperService.downloadStatus !== ""
                onClicked: {
                    NotificationService.systemNotify("WALLPAPER", "Downloading random anime wallpaper...", 1);
                    WallpaperService.downloadRandomType("anime");
                }
            }

            Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: "MONO"
                icon: "circle-half"
                size: "sm"
                paddingX: Theme.spaceSm
                paddingY: Theme.spaceMd
                bgColor: "transparent"
                bgHoverColor: Theme.controlBackgroundHover
                busy: WallpaperService.downloadStatus !== ""
                onClicked: {
                    NotificationService.systemNotify("WALLPAPER", "Downloading random monochrome wallpaper...", 1);
                    WallpaperService.downloadRandomType("monochrome");
                }
            }
        }
    }

    // ── Auto-Cycle ──────────────────────────────────────────────────
    Card {
        id: cycleCard
        width: parent.width
        title: "AUTO-CYCLE"

        property var intervalMinutes: [1, 5, 15, 30, 60, 180]
        property var carouselProviders: ["random", "anime", "monochrome"]
        property var carouselLabels: ["ALL", "ANIME", "MONO"]

        function intervalLabel(minutes) {
            return minutes >= 60 ? (minutes / 60) + "H" : minutes + "M"
        }

        function intervalIndex(minutes) {
            var best = 0
            for (var i = 1; i < intervalMinutes.length; i++) {
                if (Math.abs(intervalMinutes[i] - minutes) < Math.abs(intervalMinutes[best] - minutes)) best = i
            }
            return best
        }

        function providerIndex(type) {
            var i = carouselProviders.indexOf(type)
            return i >= 0 ? i : 0
        }

        Column {
            width: parent.width
            spacing: 0

            SettingRow {
                width: parent.width
                label: "CYCLE WALLPAPERS"
                description: "Periodically switch to the next wallpaper in your folder"

                Toggle {
                    toggleWidth: 38
                    toggleHeight: 20
                    checked: WallpaperService.autoCycle
                    onToggled: v => WallpaperService.setAutoCycle(v)
                }
            }

            Divider {
                width: parent.width
                visible: WallpaperService.autoCycle
            }

            SettingRow {
                width: parent.width
                label: "INTERVAL"
                visible: WallpaperService.autoCycle

                OptionSwitcher {
                    size: "sm"
                    options: cycleCard.intervalMinutes.map(cycleCard.intervalLabel)
                    currentIndex: cycleCard.intervalIndex(WallpaperService.autoCycleMinutes)
                    onSelected: i => WallpaperService.setAutoCycleMinutes(cycleCard.intervalMinutes[i])
                }
            }

            Divider {
                width: parent.width
            }

            SettingRow {
                width: parent.width
                label: "CAROUSEL"
                description: "Periodically download a fresh wallpaper from the web"

                Toggle {
                    toggleWidth: 38
                    toggleHeight: 20
                    checked: WallpaperService.carousel
                    onToggled: v => WallpaperService.setCarousel(v)
                }
            }

            Divider {
                width: parent.width
                visible: WallpaperService.carousel
            }

            SettingRow {
                width: parent.width
                label: "SOURCE"
                visible: WallpaperService.carousel

                OptionSwitcher {
                    size: "sm"
                    options: cycleCard.carouselLabels
                    currentIndex: cycleCard.providerIndex(WallpaperService.carouselProvider)
                    onSelected: i => WallpaperService.setCarouselProvider(cycleCard.carouselProviders[i])
                }
            }

            SettingRow {
                width: parent.width
                label: "INTERVAL"
                visible: WallpaperService.carousel

                OptionSwitcher {
                    size: "sm"
                    options: cycleCard.intervalMinutes.map(cycleCard.intervalLabel)
                    currentIndex: cycleCard.intervalIndex(WallpaperService.carouselMinutes)
                    onSelected: i => WallpaperService.setCarouselMinutes(cycleCard.intervalMinutes[i])
                }
            }

            SettingRow {
                width: parent.width
                label: "REMEMBER"
                description: "Keep carousel downloads on disk and in history after they rotate out"
                visible: WallpaperService.carousel

                Toggle {
                    toggleWidth: 38
                    toggleHeight: 20
                    checked: WallpaperService.carouselRemember
                    onToggled: v => WallpaperService.setCarouselRemember(v)
                }
            }
        }
    }

    // ── Wallpapers ──────────────────────────────────────────────────
    Card {
        id: historyCard
        width: parent.width
        title: "WALLPAPERS"
        description: "Recent wallpapers — click to switch"
        visible: root.historyModel.length > 0

        property real tileW: (historyFlow.width - Theme.spaceSm * 3) / 4
        property real tileH: tileW * 9 / 16

        Flow {
            id: historyFlow
            width: parent.width
            spacing: Theme.spaceSm

            Repeater {
                model: root.historyModel

                delegate: Item {
                    required property var modelData
                    property bool isCurrent: !modelData.isPickMore && modelData.path === WallpaperService.wallpaperPath
                    property bool hovered: historyHover.containsMouse || removeHover.containsMouse
                    width: historyCard.tileW
                    height: historyCard.tileH

                    Rectangle {
                        id: tileBg
                        anchors.fill: parent
                        radius: Theme.radiusSmall
                        color: Theme.backgroundTertiary
                        border.width: parent.isCurrent ? 2 : 0
                        border.color: Theme.accent
                        visible: !modelData.isPickMore
                        Behavior on color {
                            enabled: Theme.animationsEnabled
                            ColorAnimation {
                                duration: Theme.animationFast
                            }
                        }
                        Behavior on border.color {
                            enabled: Theme.animationsEnabled
                            ColorAnimation {
                                duration: Theme.animationNormal
                            }
                        }
                    }

                    Image {
                        id: tileImg
                        anchors.fill: parent
                        source: modelData.isPickMore ? "" : "file://" + modelData.path
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        asynchronous: true
                        visible: false
                    }

                    Rectangle {
                        id: tileMask
                        anchors.fill: parent
                        radius: Theme.radiusSmall
                        color: "white"
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: parent
                        source: tileImg
                        maskSource: tileMask
                        visible: !modelData.isPickMore && tileImg.status === Image.Ready
                    }

                    Rectangle {
                        id: tileOverlay
                        anchors.fill: parent
                        radius: Theme.radiusSmall
                        color: parent.hovered ? "#80000000" : "#30000000"
                        visible: !modelData.isPickMore && (parent.hovered || parent.isCurrent)
                        Behavior on color {
                            enabled: Theme.animationsEnabled
                            ColorAnimation {
                                duration: Theme.animationFast
                            }
                        }

                        Icon {
                            anchors.centerIn: parent
                            source: Icons.get("x")
                            size: 18
                            color: Theme.textPrimary
                            visible: parent.parent.hovered
                            Behavior on opacity {
                                enabled: Theme.animationsEnabled
                                NumberAnimation {
                                    duration: Theme.animationFast
                                }
                            }
                            opacity: parent.parent.hovered ? 1 : 0
                        }
                    }

                    Text {
                        id: tileFilename
                        anchors {
                            left: parent.left
                            bottom: parent.bottom
                            leftMargin: Theme.spaceSm
                            bottomMargin: Theme.spaceXs
                        }
                        text: modelData.isPickMore ? "" : modelData.path.split("/").pop()
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontSizeCaption
                        font.family: Theme.fontFamilyMono
                        elide: Text.ElideRight
                        width: parent.width - Theme.spaceSm * 2
                        visible: !modelData.isPickMore && parent.hovered
                        Behavior on opacity {
                            enabled: Theme.animationsEnabled
                            NumberAnimation {
                                duration: Theme.animationFast
                            }
                        }
                        opacity: parent.hovered ? 1 : 0
                    }

                    Rectangle {
                        id: currentBadge
                        anchors {
                            right: parent.right
                            top: parent.top
                            rightMargin: Theme.spaceXs
                            topMargin: Theme.spaceXs
                        }
                        width: 20
                        height: 20
                        radius: Theme.radiusSmall
                        color: Theme.accent
                        visible: parent.isCurrent
                        Behavior on scale {
                            enabled: Theme.animationsEnabled
                            NumberAnimation {
                                duration: Theme.animationNormal
                                easing.type: Easing.OutBack
                            }
                        }
                        scale: parent.isCurrent ? 1 : 0

                        Text {
                            anchors.centerIn: parent
                            text: "✓"
                            color: Theme.background
                            font.pixelSize: 11
                            font.weight: Font.Bold
                        }
                    }

                    Surface {
                        anchors.fill: parent
                        radius: Theme.radiusSmall
                        color: pickMoreHover.containsMouse ? Theme.controlBackgroundHover : Theme.backgroundTertiary
                        visible: modelData.isPickMore
                        Behavior on color {
                            enabled: Theme.animationsEnabled
                            ColorAnimation {
                                duration: Theme.animationFast
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.spaceXs

                            Spinner {
                                spinnerSize: 24
                                spinnerColor: Theme.textSecondary
                                anchors.horizontalCenter: parent.horizontalCenter
                                visible: WallpaperService.pickerOpen
                            }

                            Icon {
                                source: Icons.get("plus")
                                size: 24
                                color: Theme.textSecondary
                                anchors.horizontalCenter: parent.horizontalCenter
                                visible: !WallpaperService.pickerOpen
                            }

                            Text {
                                text: WallpaperService.pickerOpen ? "OPENING..." : "PICK"
                                color: Theme.textSecondary
                                font.pixelSize: Theme.fontSizeCaption
                                font.family: Theme.fontFamilyMono
                                font.letterSpacing: 0.06
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        MouseArea {
                            id: pickMoreHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: WallpaperService.pickerOpen ? Qt.WaitCursor : Qt.PointingHandCursor
                            enabled: !WallpaperService.pickerOpen
                            onClicked: WallpaperService.pickWallpaper()
                        }
                    }

                    MouseArea {
                        id: historyHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        visible: !modelData.isPickMore
                        onClicked: WallpaperService.setWallpaper(modelData.path)
                    }

                    MouseArea {
                        id: removeHover
                        anchors {
                            right: parent.right
                            top: parent.top
                        }
                        width: 28
                        height: 28
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        visible: !modelData.isPickMore
                        onClicked: WallpaperService.removeFromHistory(modelData.path)
                    }
                }
            }
        }
    }

    // ── Palette ──────────────────────────────────────────────────────
    Card {
        width: parent.width
        title: "PALETTE"
        description: "Tap to set as accent color"

        GridLayout {
            width: parent.width
            columns: 6
            columnSpacing: Theme.spaceSm
            rowSpacing: Theme.spaceSm

            Repeater {
                model: [
                    {
                        name: "PRIMARY",
                        col: WallpaperService.primary
                    },
                    {
                        name: "SECONDARY",
                        col: WallpaperService.secondary
                    },
                    {
                        name: "TERTIARY",
                        col: WallpaperService.tertiary
                    },
                    {
                        name: "ACCENT",
                        col: WallpaperService.accent
                    },
                    {
                        name: "BG",
                        col: WallpaperService.background
                    },
                    {
                        name: "SURFACE",
                        col: WallpaperService.surface
                    },
                    {
                        name: "LIGHT",
                        col: WallpaperService.primaryLight
                    },
                    {
                        name: "DARK",
                        col: WallpaperService.primaryDark
                    }
                ]

                delegate: ColorSwatch {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    swatchColor: modelData.col || Theme.border
                    label: modelData.name
                    onClicked: {
                        if (modelData.col)
                            Theme.setAccent(modelData.col.toString());
                    }
                }
            }
        }
    }
}
