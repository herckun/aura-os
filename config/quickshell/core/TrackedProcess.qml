import QtQuick
import Quickshell.Io

QtObject {
  id: root

  property var command: []
  property var callback: null
  property bool running: false

  property Component _processComponent: Component {
    Process {
      stdout: StdioCollector { waitForEnd: true }
      stderr: StdioCollector { waitForEnd: true }
    }
  }

  property var _proc: null

  function _ensureProc(): void {
    if (!_proc) _proc = _processComponent.createObject(root)
  }

  function start(cmd: var): void {
    _ensureProc()
    _proc.command = cmd
    root.running = true
    _proc.running = true
    _proc.exited.connect(_onExited)
  }

  function _onExited(code: int): void {
    root.running = false
    var result = { exitCode: code, stdout: _proc.stdout.text, stderr: _proc.stderr.text }
    if (root.callback) root.callback(result)
  }

  function stop(): void {
    if (_proc) {
      _proc.running = false
      _proc.exited.disconnect(_onExited)
    }
    root.running = false
  }
}
