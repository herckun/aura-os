import QtQuick
import QtQuick.Layouts
import "../styles"

Column {
    id: root

    property real from: 0
    property real to: 1
    property real value: 0
    property real stepSize: 0.01
    property string label: ""
    property string unit: ""
    property real displayMin: 0
    property real displayMax: 100
    property real dangerThreshold: -1
    property real criticalThreshold: -1
    property real transitionWidth: 0.08
    property string variant: "accent"
    property color normalColor: "transparent"
    property color dangerColor: Theme.warning
    property color criticalColor: Theme.error
    signal moved(real newValue)

    readonly property color _vn: normalColor.a > 0 ? normalColor : Theme.variantColor(variant)

    readonly property real _ratio: Math.max(0, Math.min(1,
        (root.value - root.from) / (root.to - root.from)))
    readonly property bool _hasThresholds: root.dangerThreshold >= 0 || root.criticalThreshold >= 0

    readonly property real _firstThresholdPos: root.dangerThreshold >= 0 ? root.dangerThreshold :
                                               root.criticalThreshold >= 0 ? root.criticalThreshold : 1.0
    readonly property real _firstTransitionStart: Math.max(0, root._firstThresholdPos - root.transitionWidth)
    readonly property real _secondTransitionStart: root.criticalThreshold >= 0 ?
        Math.max(root.dangerThreshold >= 0 ? root.dangerThreshold : 0, root.criticalThreshold - root.transitionWidth) : 1.0
    readonly property color _firstThresholdColor: root.dangerThreshold >= 0 ? root.dangerColor :
                                                  root.criticalThreshold >= 0 ? root.criticalColor : root._vn
    readonly property color _midGradientColor: root.dangerThreshold >= 0 ? root.dangerColor : root._vn
    readonly property color _endGradientColor: root.criticalThreshold >= 0 ? root.criticalColor :
                                               root.dangerThreshold >= 0 ? root.dangerColor : root._vn

    width: parent.width
    spacing: Theme.spaceSm

    function displayValue(): string {
      var ratio = (root.value - root.from) / (root.to - root.from)
      var display = root.displayMin + ratio * (root.displayMax - root.displayMin)
      return Math.round(display) + root.unit
    }

    function fillColor(): color {
        if (!root._hasThresholds) return root._vn
        if (root.criticalThreshold >= 0 && root._ratio >= root.criticalThreshold) return root.criticalColor
        if (root.dangerThreshold >= 0 && root._ratio >= root.dangerThreshold) return root.dangerColor
        return root._vn
    }

    function textColor(): color {
        if (!root._hasThresholds) return Theme.textPrimary
        if (root.criticalThreshold >= 0 && root._ratio >= root.criticalThreshold) return root.criticalColor
        if (root.dangerThreshold >= 0 && root._ratio >= root.dangerThreshold) return root.dangerColor
        return Theme.textPrimary
    }

    Row {
        width: parent.width

        Text {
            text: root.label
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSizeCaption
            font.family: Theme.fontFamilyMono
            font.letterSpacing: 0.08
            width: parent.width * 0.7
        }

        Text {
            text: root.displayValue()
            color: root.textColor()
            font.pixelSize: Theme.fontSizeLabel
            font.family: Theme.fontFamilyMono
            width: parent.width * 0.3
            horizontalAlignment: Text.AlignRight

            Behavior on color {
                enabled: Theme.animationsEnabled
                ColorAnimation { duration: Theme.animationFast }
            }
        }
    }

    Rectangle {
        width: parent.width
        height: 32
        radius: Theme.radiusPill
        color: Theme.backgroundTertiary
        border.width: Theme.borderWidth
        border.color: Theme.border

        Button {
            id: minusBtn
            shape: "icon"
            anchors.left: parent.left
            width: 32
            height: parent.height
            icon: "minus"
            onClicked: {
                root.moved(Math.max(root.from, root.value - root.stepSize))
            }
        }

        Item {
            id: trackArea
            anchors.left: minusBtn.right
            anchors.right: plusBtn.left
            height: parent.height

            Rectangle {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.spaceXs
                anchors.rightMargin: Theme.spaceXs
                height: 6
                radius: Theme.radiusSmall
                color: Theme.border
            }

            Item {
                id: fillClip
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: Theme.spaceXs
                height: 6
                width: Math.max(0, track.width * root._ratio)
                clip: true

                Rectangle {
                    id: fillGradient
                    width: root._hasThresholds ? track.width : fillClip.width
                    height: 6
                    radius: Theme.radiusSmall
                    color: root.fillColor()

                    gradient: root._hasThresholds ? gradientStops : null

                    Gradient {
                        id: gradientStops
                        orientation: Gradient.Horizontal

                        GradientStop { position: 0.0; color: root._vn }

                        GradientStop { position: root._firstTransitionStart; color: root._vn }

                        GradientStop { position: root._firstThresholdPos; color: root._firstThresholdColor }

                        GradientStop { position: root._secondTransitionStart; color: root._midGradientColor }

                        GradientStop {
                            position: root.criticalThreshold >= 0 ? root.criticalThreshold : 1.0
                            color: root._endGradientColor
                        }

                        GradientStop { position: 1.0; color: root._endGradientColor }
                    }

                    Behavior on color {
                        enabled: Theme.animationsEnabled
                        ColorAnimation { duration: Theme.animationFast }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: (mouse) => { if (pressed) updateValue(mouse) }
                onClicked: (mouse) => updateValue(mouse)

                function updateValue(mouse): void {
                    const pos = Math.max(0, Math.min(track.width, mouse.x))
                    const ratio = pos / track.width
                    const val = root.from + (root.to - root.from) * ratio
                    const stepped = Math.round(val / root.stepSize) * root.stepSize
                    root.moved(Math.max(root.from, Math.min(root.to, stepped)))
                }
            }
        }

        Button {
            id: plusBtn
            shape: "icon"
            anchors.right: parent.right
            width: 32
            height: parent.height
            icon: "plus"
            onClicked: {
                root.moved(Math.min(root.to, root.value + root.stepSize))
            }
        }
    }
}