pragma ComponentBehavior: Bound

import QtQuick
import QtQml
import QtQuick.Layouts
import "../../../../styles"
import "../../../../components"
import "../../../../services"
import "../../../../core"

BasePlugin {
    id: root

    // ── Manifest ────────────────────────────────────────────────────
    pluginId: "lyrics"
    manifest: ({
            author: "herckun",
            version: "1.0",
            shellVersion: "2.0",
            name: "Lyrics",
            description: "Synced lyrics from currently playing track",
            icon: "music-note",
            locations: ["desktop"],
            defaultLayout: {
                "desktop": {
                    enabled: false,
                    settings: {
                        showBackground: true
                    }
                }
            },
            settings: [
                {
                    key: "draggable",
                    label: "DRAGGABLE",
                    description: "Allow repositioning by dragging",
                    type: "toggle",
                    default: true
                },
                {
                    key: "autoPosition",
                    label: "AUTO POSITION",
                    description: "Find best position on wallpaper automatically",
                    type: "toggle",
                    default: false
                },
                {
                    key: "showBackground",
                    label: "BACKGROUND",
                    description: "Show background behind widget",
                    type: "toggle",
                    default: true
                },
                {
                    key: "fontSize",
                    label: "FONT SIZE",
                    description: "Lyrics text size",
                    type: "stepper",
                    min: 16,
                    max: 32,
                    step: 2,
                    unit: "px",
                    default: 22
                },
                {
                    key: "maxLines",
                    label: "VISIBLE LINES",
                    description: "Number of lyric lines to show",
                    type: "stepper",
                    min: 3,
                    max: 11,
                    step: 2,
                    default: 7
                },
                {
                    key: "widgetWidth",
                    label: "WIDTH",
                    description: "Widget width",
                    type: "stepper",
                    min: 300,
                    max: 600,
                    step: 20,
                    unit: "px",
                    default: 420
                }
            ]
        })

    // ── Public state ─────────────────────────────────────────────────

    // ── Internal state ───────────────────────────────────────────────

    // ── Signal handlers ──────────────────────────────────────────────

    // ── Public API ───────────────────────────────────────────────────

    // ── Helpers ──────────────────────────────────────────────────────

    // ── Timers ───────────────────────────────────────────────────────

    // ── Lifecycle ────────────────────────────────────────────────────

    // ── UI components ────────────────────────────────────────────────
    property Component desktopComponent: Item {
        id: lyricsContainer
        width: _widgetWidth
        height: _totalHeight

        property int _fontSize: PluginService.getPluginSetting("lyrics", "fontSize", "desktop") ?? 22
        property int _maxLines: PluginService.getPluginSetting("lyrics", "maxLines", "desktop") ?? 7
        property int _widgetWidth: PluginService.getPluginSetting("lyrics", "widgetWidth", "desktop") ?? 420
        property var desktopWidget: null

        readonly property int _minLineHeight: _fontSize + 16
        readonly property int _lyricsAreaHeight: _maxLines * _minLineHeight
        readonly property int _headerHeight: 72
        readonly property int _footerHeight: 40
        readonly property int _totalHeight: _headerHeight + _lyricsAreaHeight + _footerHeight

        readonly property color _textColor: desktopWidget ? desktopWidget.widgetTextColor : Theme.textPrimary
        readonly property color _dimColor: desktopWidget ? desktopWidget.widgetDimColor : Theme.textSecondary
        readonly property color _accentColor: desktopWidget ? desktopWidget.widgetAccentColor : Theme.accent
        readonly property color _bgColor: desktopWidget ? desktopWidget._widgetBgColor : "transparent"

        // ── Header ─────────────────────────────────────────────────
        Item {
            id: header
            width: parent.width
            height: lyricsContainer._headerHeight

            Row {
                id: bars
                anchors.left: parent.left
                anchors.leftMargin: Theme.spaceSm
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                visible: MediaService.playbackStatus === "Playing" && LyricsService.hasLyrics

                Repeater {
                    model: 4

                    Rectangle {
                        required property int index
                        width: 3
                        radius: 1.5
                        color: lyricsContainer._accentColor

                        SequentialAnimation on height {
                            running: MediaService.playbackStatus === "Playing"
                            loops: Animation.Infinite
                            NumberAnimation {
                                from: 4
                                to: 16
                                duration: 400 + index * 100
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                from: 16
                                to: 4
                                duration: 400 + index * 100
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }
                }
            }

            Column {
                anchors.left: bars.visible ? bars.right : parent.left
                anchors.leftMargin: Theme.spaceSm
                anchors.right: parent.right
                anchors.rightMargin: Theme.spaceSm
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Text {
                    text: LyricsService.loading ? "Searching..." : LyricsService.currentTrack || "No track"
                    color: lyricsContainer._textColor
                    font.pixelSize: lyricsContainer._fontSize - 6
                    font.weight: Font.Bold
                    font.family: Theme.fontFamilyDisplay
                    elide: Text.ElideRight
                    width: parent.width
                }

                Text {
                    text: LyricsService.currentArtist || ""
                    color: lyricsContainer._dimColor
                    font.pixelSize: lyricsContainer._fontSize - 8
                    font.family: Theme.fontFamilyMono
                    font.letterSpacing: 0.04
                    elide: Text.ElideRight
                    width: parent.width
                    visible: text.length > 0
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Qt.rgba(lyricsContainer._dimColor.r, lyricsContainer._dimColor.g, lyricsContainer._dimColor.b, 0.15)
            }
        }

        // ── Empty / state messages ─────────────────────────────────
        Item {
            anchors.top: header.bottom
            width: parent.width
            height: lyricsContainer._lyricsAreaHeight
            visible: !LyricsService.hasLyrics || MediaService.playbackStatus === "Stopped" || (LyricsService.hasLyrics && LyricsService.currentLineIndex < 0 && MediaService.playbackStatus === "Playing") || (LyricsService.hasLyrics && LyricsService.currentLineIndex >= LyricsService.lines.length - 1 && LyricsService.lines.length > 0)

            Column {
                anchors.centerIn: parent
                spacing: Theme.spaceMd

                Icon {
                    source: {
                        if (LyricsService.loading)
                            return Icons.get("search");
                        if (!MediaService.hasPlayer)
                            return Icons.get("music-note");
                        if (MediaService.playbackStatus === "Stopped")
                            return Icons.get("stop");
                        return "";
                    }
                    size: 48
                    color: lyricsContainer._dimColor
                    opacity: 0.2
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: source !== ""

                    SequentialAnimation on opacity {
                        running: LyricsService.loading
                        loops: Animation.Infinite
                        NumberAnimation {
                            to: 0.4
                            duration: 800
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            to: 0.2
                            duration: 800
                            easing.type: Easing.InOutQuad
                        }
                    }
                }

                Text {
                    text: {
                        if (LyricsService.loading)
                            return "Looking for lyrics...";
                        if (!MediaService.hasPlayer)
                            return "Play something";
                        if (MediaService.playbackStatus === "Stopped")
                            return "Playback stopped";
                        if (!LyricsService.hasLyrics)
                            return "No lyrics found";
                        if (LyricsService.currentLineIndex < 0)
                            return "Get ready";
                        return "End of lyrics";
                    }
                    color: lyricsContainer._dimColor
                    font.pixelSize: lyricsContainer._fontSize - 4
                    font.family: Theme.fontFamilyMono
                    opacity: 0.4
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        // ── Lyrics view ────────────────────────────────────────────
        Item {
            id: lyricsView
            anchors.top: header.bottom
            width: parent.width
            height: lyricsContainer._lyricsAreaHeight
            visible: !LyricsService.loading && LyricsService.hasLyrics && MediaService.playbackStatus !== "Stopped" && LyricsService.currentLineIndex >= 0 && LyricsService.currentLineIndex < LyricsService.lines.length - 1
            clip: true

            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 40
                z: 2
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: lyricsContainer._bgColor
                    }
                    GradientStop {
                        position: 1.0
                        color: "transparent"
                    }
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 40
                z: 2
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: "transparent"
                    }
                    GradientStop {
                        position: 1.0
                        color: lyricsContainer._bgColor
                    }
                }
            }

            Column {
                id: lyricsCol
                width: parent.width
                y: {
                    var idx = LyricsService.currentLineIndex;
                    if (idx < 0)
                        return 0;

                    var currentItem = lyricsCol.children[idx];
                    if (!currentItem)
                        return 0;

                    var centerTarget = lyricsView.height / 2 - currentItem.height / 2;
                    var offset = centerTarget - currentItem.y;
                    var minOffset = -(lyricsCol.height - lyricsView.height);
                    if (minOffset > 0)
                        minOffset = 0;
                    return Math.max(minOffset, Math.min(0, offset));
                }

                Behavior on y {
                    enabled: Theme.animationsEnabled
                    NumberAnimation {
                        duration: Theme.animationNormal
                        easing.type: Easing.OutQuad
                    }
                }

                Repeater {
                    model: {
                        if (!LyricsService.hasLyrics || LyricsService.lines.length === 0)
                            return [];
                        var result = [];
                        for (var i = 0; i < LyricsService.lines.length; i++) {
                            result.push({
                                lineIndex: i,
                                text: LyricsService.lines[i].text,
                                isCurrent: i === LyricsService.currentLineIndex,
                                distance: LyricsService.currentLineIndex >= 0 ? Math.abs(i - LyricsService.currentLineIndex) : 0
                            });
                        }
                        return result;
                    }

                    delegate: Item {
                        required property var modelData
                        width: lyricsCol.width
                        height: Math.max(lyricsContainer._minLineHeight, lineText.implicitHeight + 16)

                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spaceSm
                            anchors.rightMargin: Theme.spaceSm
                            radius: Theme.radiusSmall
                            color: Qt.rgba(lyricsContainer._accentColor.r, lyricsContainer._accentColor.g, lyricsContainer._accentColor.b, 0.08)
                            visible: modelData.isCurrent
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spaceSm
                            anchors.verticalCenter: parent.verticalCenter
                            width: 3
                            height: Math.min(parent.height - 16, lineText.implicitHeight)
                            radius: 1.5
                            color: lyricsContainer._accentColor
                            visible: modelData.isCurrent
                        }

                        Text {
                            id: lineText
                            anchors {
                                left: parent.left
                                leftMargin: Theme.spaceLg
                                right: parent.right
                                rightMargin: Theme.spaceMd
                                verticalCenter: parent.verticalCenter
                            }
                            text: modelData.text
                            color: {
                                if (modelData.isCurrent)
                                    return lyricsContainer._accentColor;
                                if (modelData.distance <= 1)
                                    return lyricsContainer._textColor;
                                return lyricsContainer._dimColor;
                            }
                            font.pixelSize: {
                                if (modelData.isCurrent)
                                    return lyricsContainer._fontSize;
                                if (modelData.distance <= 1)
                                    return lyricsContainer._fontSize - 2;
                                return lyricsContainer._fontSize - 4;
                            }
                            font.weight: modelData.isCurrent ? Font.Bold : (modelData.distance <= 1 ? Font.Medium : Font.Normal)
                            font.family: Theme.fontFamilyDisplay
                            opacity: {
                                if (LyricsService.currentLineIndex < 0)
                                    return 0.6;
                                if (modelData.isCurrent)
                                    return 1.0;
                                if (modelData.distance === 1)
                                    return 0.6;
                                if (modelData.distance === 2)
                                    return 0.35;
                                return 0.15;
                            }
                            wrapMode: Text.WordWrap

                            Behavior on color {
                                enabled: Theme.animationsEnabled
                                ColorAnimation {
                                    duration: Theme.animationNormal
                                }
                            }
                            Behavior on opacity {
                                enabled: Theme.animationsEnabled
                                NumberAnimation {
                                    duration: Theme.animationNormal
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Footer ─────────────────────────────────────────────────
        Item {
            anchors.top: lyricsView.visible ? lyricsView.bottom : header.bottom
            width: parent.width
            height: lyricsContainer._footerHeight

            Row {
                anchors.centerIn: parent
                spacing: Theme.spaceXs
                visible: LyricsService.hasLyrics && LyricsService.lines.length > 0

                Text {
                    text: {
                        var idx = LyricsService.currentLineIndex;
                        if (idx < 0)
                            return "— / " + LyricsService.lines.length;
                        return (idx + 1) + " / " + LyricsService.lines.length;
                    }
                    color: lyricsContainer._dimColor
                    font.pixelSize: Theme.fontSizeMicro
                    font.family: Theme.fontFamilyMono
                    opacity: 0.5
                }
            }
        }
    }
}
