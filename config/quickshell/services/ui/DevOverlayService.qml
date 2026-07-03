pragma Singleton
import QtQuick
import Quickshell
import "../../core"

Singleton {
  id: svc

  property bool visible: false

  function toggle(): void {
    visible = !visible
  }
}
