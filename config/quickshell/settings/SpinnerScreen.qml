import QtQuick
import QtQuick.Layouts
import "../styles"
import "../components"

Rectangle {
  id: root

  property string label: "LOADING"
  property bool showSpinner: true

  color: Theme.background
  radius: Theme.radiusMedium

  DotMatrixBackground {
    anchors.fill: parent
  }

  ColumnLayout {
    anchors.centerIn: parent
    spacing: Theme.spaceMd

    Spinner {
      visible: root.showSpinner
      spinnerSize: 28
      Layout.alignment: Qt.AlignHCenter
    }

    Text {
      visible: root.label !== ""
      text: root.label.toUpperCase()
      color: Theme.textDisabled
      font.pixelSize: Theme.fontSizeMicro
      font.family: Theme.fontFamilyMono
      font.letterSpacing: 0.1
      Layout.alignment: Qt.AlignHCenter
    }
  }
}
