pragma ComponentBehavior: Bound

import QtQuick
import QtQml
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
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
            version: "1.1",
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
                    key: "maxLines",
                    label: "VISIBLE LINES",
                    description: "Number of lyric lines to show",
                    type: "stepper",
                    min: 3,
                    max: 11,
                    step: 2,
                    default: 5
                },
                {
                    key: "scale",
                    label: "SCALE",
                    description: "Widget size relative to default",
                    type: "stepper",
                    min: 60,
                    max: 160,
                    step: 10,
                    unit: "%",
                    default: 100
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
        width: 300
        height: header.height + 1 + lyricsContainer._lyricsAreaHeight

        property int _maxLines: PluginService.getPluginSetting("lyrics", "maxLines", "desktop") ?? 5
        property var desktopWidget: null

        readonly property int _lineFont: Theme.fontSizeBody
        readonly property int _minLineHeight: _lineFont + 12
        readonly property int _lyricsAreaHeight: _maxLines * _minLineHeight

        readonly property color _textColor: desktopWidget ? desktopWidget.widgetTextColor : Theme.textPrimary
        readonly property color _dimColor: desktopWidget ? desktopWidget.widgetDimColor : Theme.textSecondary
        readonly property color _accentColor: desktopWidget ? desktopWidget.widgetAccentColor : Theme.accent
        readonly property color _bgColor: desktopWidget ? desktopWidget._widgetBgColor : "transparent"

        // ── Header ─────────────────────────────────────────────────
        Item {
            id: header
            width: parent.width
            height: headerCol.implicitHeight + Theme.spaceSm

            Row {
                id: bars
                anchors.left: parent.left
                anchors.leftMargin: Theme.spaceXs
                anchors.verticalCenter: headerCol.verticalCenter
                spacing: 2
                visible: MediaService.playbackStatus === "Playing" && LyricsService.hasLyrics

                Repeater {
                    model: 3

                    Rectangle {
                        required property int index
                        width: 2
                        radius: 1
                        color: lyricsContainer._accentColor

                        SequentialAnimation on height {
                            running: MediaService.playbackStatus === "Playing"
                            loops: Animation.Infinite
                            NumberAnimation {
                                from: 3
                                to: 11
                                duration: 400 + index * 100
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                from: 11
                                to: 3
                                duration: 400 + index * 100
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }
                }
            }

            Column {
                id: headerCol
                anchors.left: bars.visible ? bars.right : parent.left
                anchors.leftMargin: bars.visible ? Theme.spaceSm : Theme.spaceXs
                anchors.right: counter.left
                anchors.rightMargin: Theme.spaceSm
                anchors.top: parent.top
                spacing: 2

                Text {
                    text: LyricsService.loading ? "SEARCHING..." : (LyricsService.currentTrack || "NO TRACK").toUpperCase()
                    color: lyricsContainer._textColor
                    font.pixelSize: Theme.fontSizeCaption
                    font.weight: Font.Bold
                    font.family: Theme.fontFamilyMono
                    font.letterSpacing: 0.06
                    elide: Text.ElideRight
                    width: parent.width
                }

                Text {
                    text: LyricsService.currentArtist || ""
                    color: lyricsContainer._dimColor
                    font.pixelSize: Theme.fontSizeMicro
                    font.family: Theme.fontFamilyMono
                    font.letterSpacing: 0.04
                    elide: Text.ElideRight
                    width: parent.width
                    visible: text.length > 0
                }
            }

            Text {
                id: counter
                anchors.right: parent.right
                anchors.rightMargin: Theme.spaceXs
                anchors.top: parent.top
                text: {
                    if (!LyricsService.hasLyrics || LyricsService.lines.length === 0)
                        return "";
                    var idx = LyricsService.currentLineIndex;
                    return (idx < 0 ? "—" : idx + 1) + "/" + LyricsService.lines.length;
                }
                color: lyricsContainer._dimColor
                font.pixelSize: Theme.fontSizeMicro
                font.family: Theme.fontFamilyMono
                opacity: 0.6
            }
        }

        Rectangle {
            id: headerDivider
            anchors.top: header.bottom
            width: parent.width
            height: 1
            color: Qt.rgba(lyricsContainer._dimColor.r, lyricsContainer._dimColor.g, lyricsContainer._dimColor.b, 0.15)
        }

        // ── Empty / state messages ─────────────────────────────────
        Item {
            anchors.top: headerDivider.bottom
            width: parent.width
            height: lyricsContainer._lyricsAreaHeight
            visible: !LyricsService.hasLyrics || MediaService.playbackStatus === "Stopped" || (LyricsService.hasLyrics && LyricsService.currentLineIndex < 0 && MediaService.playbackStatus === "Playing") || (LyricsService.hasLyrics && LyricsService.currentLineIndex >= LyricsService.lines.length - 1 && LyricsService.lines.length > 0)

            Column {
                anchors.centerIn: parent
                spacing: Theme.spaceSm

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
                    size: 22
                    color: lyricsContainer._dimColor
                    opacity: 0.25
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: source !== ""

                    SequentialAnimation on opacity {
                        running: LyricsService.loading
                        loops: Animation.Infinite
                        NumberAnimation {
                            to: 0.45
                            duration: 800
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            to: 0.25
                            duration: 800
                            easing.type: Easing.InOutQuad
                        }
                    }
                }

                Text {
                    text: {
                        if (LyricsService.loading)
                            return "LOOKING FOR LYRICS...";
                        if (!MediaService.hasPlayer)
                            return "PLAY SOMETHING";
                        if (MediaService.playbackStatus === "Stopped")
                            return "PLAYBACK STOPPED";
                        if (!LyricsService.hasLyrics)
                            return "NO LYRICS FOUND";
                        if (LyricsService.currentLineIndex < 0)
                            return "GET READY";
                        return "END OF LYRICS";
                    }
                    color: lyricsContainer._dimColor
                    font.pixelSize: Theme.fontSizeMicro
                    font.family: Theme.fontFamilyMono
                    font.letterSpacing: 0.08
                    opacity: 0.5
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        // ── Lyrics view ────────────────────────────────────────────
        Item {
            id: lyricsView
            anchors.top: headerDivider.bottom
            width: parent.width
            height: lyricsContainer._lyricsAreaHeight
            visible: !LyricsService.loading && LyricsService.hasLyrics && MediaService.playbackStatus !== "Stopped" && LyricsService.currentLineIndex >= 0 && LyricsService.currentLineIndex < LyricsService.lines.length - 1
            clip: true

            Item {
                id: lyricsContent
                anchors.fill: parent
                visible: false

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
                                    isCurrent: i === LyricsService.currentLineIndex
                                });
                            }
                            return result;
                        }

                        delegate: Item {
                            required property var modelData
                            width: lyricsCol.width
                            height: Math.max(lyricsContainer._minLineHeight, lineText.implicitHeight + 10)

                            Rectangle {
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.spaceXs
                                anchors.verticalCenter: parent.verticalCenter
                                width: 2
                                height: Math.min(parent.height - 10, lineText.implicitHeight)
                                radius: 1
                                color: lyricsContainer._accentColor
                                visible: modelData.isCurrent
                            }

                            Text {
                                id: lineText
                                anchors {
                                    left: parent.left
                                    leftMargin: Theme.spaceMd
                                    right: parent.right
                                    rightMargin: Theme.spaceSm
                                    verticalCenter: parent.verticalCenter
                                }
                                text: modelData.text
                                color: modelData.isCurrent ? lyricsContainer._accentColor : lyricsContainer._dimColor
                                font.pixelSize: modelData.isCurrent ? lyricsContainer._lineFont : lyricsContainer._lineFont - 1
                                font.weight: modelData.isCurrent ? Font.Bold : Font.Normal
                                font.family: Theme.fontFamilyDisplay
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere

                                Behavior on color {
                                    enabled: Theme.animationsEnabled
                                    ColorAnimation {
                                        duration: Theme.animationNormal
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: fadeMask
                anchors.fill: parent
                visible: false
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: "transparent"
                    }
                    GradientStop {
                        position: 0.22
                        color: "white"
                    }
                    GradientStop {
                        position: 0.78
                        color: "white"
                    }
                    GradientStop {
                        position: 1.0
                        color: "transparent"
                    }
                }
            }

            OpacityMask {
                anchors.fill: parent
                source: lyricsContent
                maskSource: fadeMask
            }
        }
    }
}
