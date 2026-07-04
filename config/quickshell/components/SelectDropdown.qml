import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../styles"
import "../core"

Rectangle {
    id: root

    // ── Properties ─────────────────────────────────────────────
    property string placeholder: "Select..."
    property string value: ""
    property string displayText: ""
    property var items: []
    property string textRole: "label"
    property string valueRole: "value"

    // ── Signals ────────────────────────────────────────────────
    signal itemSelected(var item)

    // ── Geometry ───────────────────────────────────────────────
    width: parent ? parent.width : 200
    height: Theme.controlHeight
    radius: Theme.radiusMedium
    color: popup.visible ? Theme.backgroundTertiary : Theme.backgroundSecondary
    border.width: Theme.borderWidth
    border.color: popup.visible ? Theme.accent : Theme.border

    Behavior on border.color {
        enabled: Theme.animationsEnabled
        ColorAnimation {
            duration: Theme.animationFast
        }
    }

    Behavior on color {
        enabled: Theme.animationsEnabled
        ColorAnimation {
            duration: Theme.animationFast
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spaceMd
        anchors.rightMargin: Theme.spaceMd
        spacing: Theme.spaceSm

        Text {
            Layout.fillWidth: true
            text: root.displayText || root.placeholder
            color: root.displayText ? Theme.textPrimary : Theme.textDisabled
            font.pixelSize: Theme.fontSizeCaption
            font.family: Theme.fontFamilyMono
            elide: Text.ElideRight
        }

        Icon {
            source: Icons.get("caret-down")
            size: 10
            color: popup.visible ? Theme.accent : Theme.textDisabled
            rotation: popup.visible ? 180 : 0

            Behavior on rotation {
                enabled: Theme.animationsEnabled
                NumberAnimation {
                    duration: Theme.animationFast
                    easing.type: Easing.OutQuad
                }
            }

            Behavior on color {
                enabled: Theme.animationsEnabled
                ColorAnimation {
                    duration: Theme.animationFast
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.visible = !popup.visible
    }

    Popup {
        id: popup
        x: 0
        y: root.height + Theme.spaceXs
        width: root.width
        height: Math.min(listView.contentHeight + Theme.spaceXs * 2, 200)
        closePolicy: Popup.CloseOnPressOutside
        padding: 0

        background: Rectangle {
            radius: Theme.radiusMedium
            color: Theme.backgroundSecondary
            border.width: Theme.borderWidth
            border.color: Theme.border
        }

        contentItem: ListView {
            id: listView
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.items

            delegate: Rectangle {
                width: listView.width
                height: 36
                radius: Theme.radiusSmall
                color: {
                    if (itemMouse.containsMouse)
                        return Theme.controlBackgroundHover;
                    var itemValue = modelData[root.valueRole] || modelData.value || modelData;
                    if (itemValue === root.value)
                        return Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.1);
                    return "transparent";
                }

                Behavior on color {
                    enabled: Theme.animationsEnabled
                    ColorAnimation {
                        duration: Theme.animationFast
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spaceSm
                    anchors.rightMargin: Theme.spaceSm
                    spacing: Theme.spaceSm

                    Text {
                        Layout.fillWidth: true
                        text: modelData[root.textRole] || modelData.label || modelData
                        color: {
                            var itemValue = modelData[root.valueRole] || modelData.value || modelData;
                            return itemValue === root.value ? Theme.accent : Theme.textPrimary;
                        }
                        font.pixelSize: Theme.fontSizeCaption
                        font.family: Theme.fontFamilyMono
                        elide: Text.ElideRight
                    }

                    Icon {
                        visible: {
                            var itemValue = modelData[root.valueRole] || modelData.value || modelData;
                            return itemValue === root.value;
                        }
                        source: Icons.get("check")
                        size: 12
                        color: Theme.accent
                    }
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.itemSelected(modelData);
                        popup.close();
                    }
                }
            }
        }
    }

    function _updateDisplayText(): void {
        if (!root.value || !root.items || root.items.length === 0)
            return;
        for (var i = 0; i < root.items.length; i++) {
            var item = root.items[i];
            if (!item)
                continue;
            var itemValue = item[root.valueRole] || item.value || item;
            if (itemValue === root.value) {
                root.displayText = item[root.textRole] || item.label || item;
                return;
            }
        }
    }

    Component.onCompleted: _updateDisplayText()
    onValueChanged: _updateDisplayText()
    onItemsChanged: _updateDisplayText()
}
