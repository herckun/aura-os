import QtQuick

Item {
  id: root

  property alias text: label.text
  property alias color: label.color
  property alias font: label.font

  implicitWidth: Math.max(1, _metrics.tightBoundingRect.width)
  implicitHeight: label.implicitHeight

  TextMetrics {
    id: _metrics
    text: label.text
    font: label.font
  }

  Text {
    id: label
    x: -_metrics.tightBoundingRect.x
    anchors.verticalCenter: parent.verticalCenter
  }
}
