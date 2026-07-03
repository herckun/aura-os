import QtQuick
import "../../../../styles"
import "../../../../components"

ListRow {
  id: root

  property string taskId: ""
  property string taskText: ""
  property bool taskDone: false
  property bool showDelete: false

  signal toggled()
  signal removed()

  title: root.taskText
  titleColor: root.taskDone ? Theme.textDisabled : Theme.textPrimary
  titleStrikeout: root.taskDone

  leading: Checkbox {
    width: 18
    height: 18
    checked: root.taskDone
    onToggled: root.toggled()
  }

  trailing: Button {
    shape: "icon"
    icon: "xmark"
    size: "xs"
    width: 22
    height: 22
    opacity: (root.showDelete && root.hovered) ? 1 : 0
    onClicked: root.removed()

    Behavior on opacity {
      enabled: Theme.animationsEnabled
      NumberAnimation { duration: Theme.animationFast }
    }
  }
}
