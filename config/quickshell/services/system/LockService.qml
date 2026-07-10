pragma Singleton
import QtQml
import Quickshell
import "../../core"

Singleton {
  id: svc

  readonly property bool autoLock: Store.lock.autoLock

  function setAutoLock(on: bool): void {
    Store.lock.autoLock = on
  }

  function toggleAutoLock(): void {
    Store.lock.autoLock = !Store.lock.autoLock
  }

  function lock(): void {
    ProcessPool.runDetached(["sh", "-c", "pidof hyprlock >/dev/null || hyprlock"])
  }
}
