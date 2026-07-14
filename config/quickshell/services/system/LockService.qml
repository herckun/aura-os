pragma Singleton
import QtQml
import Quickshell
import "../../core"

Singleton {
  id: svc

  readonly property bool autoLock: Store.lock.autoLock
  readonly property int autoLockMinutes: Store.lock.autoLockMinutes

  function setAutoLock(on: bool): void {
    Store.lock.autoLock = on
  }

  function setAutoLockMinutes(min: int): void {
    Store.lock.autoLockMinutes = Math.max(1, Math.min(720, Math.round(min)))
  }

  function toggleAutoLock(): void {
    Store.lock.autoLock = !Store.lock.autoLock
  }

  function lock(): void {
    ProcessPool.runDetached(["sh", "-c", "pidof hyprlock >/dev/null || hyprlock"])
  }
}
