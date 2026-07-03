pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../styles"
import "../../core"
import "../../components"
import "../"

BasePlugin {
  id: root

  // ── Manifest ─────────────────────────────────────────────────────
  pluginId: "example"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Example Plugin",
    description: "Template demonstrating the plugin golden rule",
    icon: "info",
    locations: [],
    icons: {},
    settings: []
  })

  // ── Public state ─────────────────────────────────────────────────

  // ── Internal state ───────────────────────────────────────────────

  // ── Signal handlers ──────────────────────────────────────────────

  // ── Public API ───────────────────────────────────────────────────

  // ── Helpers ──────────────────────────────────────────────────────

  // ── Timers ───────────────────────────────────────────────────────

  // ── Lifecycle ────────────────────────────────────────────────────
  function onActivated(): void {}
  function onDeactivated(): void {}
  function onSettingChanged(key, value): void {}
  function stopAllActivity(): void {}

  // ── UI components ────────────────────────────────────────────────
}
