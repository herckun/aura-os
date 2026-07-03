
import QtQuick
import "../../../services"
BasePlugin {
  pluginId: "test-broken"
  manifest: ({})
  Component.onCompleted: {
    console.log("This should never execute")
  }
