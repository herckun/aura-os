pragma Singleton
import QtQuick
import Quickshell

Singleton {
  id: root

  property string level: "info"

  function _levelNum(name: string): int {
    switch (name) {
      case "debug": return 0
      case "info": return 1
      case "warn": return 2
      case "error": return 3
      default: return 1
    }
  }

  function log(category: string, msgLevel: string, message: string): void {
    if (_levelNum(msgLevel) < _levelNum(level)) return
    var prefix = "[" + category + "]"
    switch (msgLevel) {
      case "debug": console.debug(prefix, message); break
      case "info": console.log(prefix, message); break
      case "warn": console.warn(prefix, message); break
      case "error": console.error(prefix, message); break
      default: console.log(prefix, message); break
    }
  }

  function debug(category: string, message: string): void { log(category, "debug", message) }
  function info(category: string, message: string): void { log(category, "info", message) }
  function warn(category: string, message: string): void { log(category, "warn", message) }
  function error(category: string, message: string): void { log(category, "error", message) }
}
