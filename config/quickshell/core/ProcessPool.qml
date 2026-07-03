pragma Singleton
import QtQml
import QtQuick
import Quickshell
import Quickshell.Io
import "./"

Singleton {
    id: root

    signal busyChanged(string id, bool active)

    property int defaultTimeout: 30000
    property int maxQueue: 50
    property int parallelWarnThreshold: 24

    // ── Internal state ──────────────────────────────────────────
    property bool _running: false
    property var _queue: []
    property int _queueHead: 0
    property string _currentLabel: ""
    property string _currentId: ""
    property bool _currentSilent: false
    property var _resultCallback: null
    property bool _serialFinished: true

    property var _tracked: ([])
    property int _trackedIdCounter: 0
    property var _trackedComponent: null
    property var _pool: ([])

    property var _busyCounts: ({})
    property var _slotTimers: ({})
    property var _timerPool: ([])

    // ── Busy refcounting ────────────────────────────────────────
    function _busyAcquire(id: string): void {
        if (!id)
            return;
        var c = (_busyCounts[id] || 0) + 1;
        _busyCounts[id] = c;
        if (c === 1)
            busyChanged(id, true);
    }

    function _busyRelease(id: string): void {
        if (!id)
            return;
        var c = (_busyCounts[id] || 0) - 1;
        if (c <= 0) {
            if (_busyCounts[id]) {
                _busyCounts[id] = 0;
                busyChanged(id, false);
            }
        } else {
            _busyCounts[id] = c;
        }
    }

    function isBusy(id: string): bool {
        return !!_busyCounts[id];
    }

    function isRunning(handle: var): bool {
        return !!(handle && handle.running);
    }

    // ── Helpers ─────────────────────────────────────────────────
    function _normalizeCommand(command, opts: var): var {
        if (Array.isArray(command) && !(opts && opts.shell === true))
            return command;
        if (opts && opts.shell === true)
            return ["sh", "-c", Array.isArray(command) ? command.join(" ") : String(command)];
        return ["sh", "-c", String(command)];
    }

    function _safeCall(cb: var, result: var, label: string): void {
        if (!cb)
            return;
        try {
            cb(result);
        } catch (e) {
            Logger.warn("process", "callback error in '" + label + "': " + e);
        }
    }

    function _errText(s): string {
        s = (s || "").trim();
        return s.length > 400 ? s.slice(0, 400) + "…" : s;
    }

    // ── Pooled one-shot timers ──────────────────────────────────
    Component {
        id: timerFactory
        Timer {
            repeat: false
            property var onFire: null
            onTriggered: {
                var f = onFire;
                if (f)
                    f();
            }
        }
    }

    function _acquireTimer(): var {
        if (_timerPool.length > 0)
            return _timerPool.pop();
        return timerFactory.createObject(root);
    }

    function _releaseTimer(t: var): void {
        if (!t)
            return;
        t.stop();
        t.onFire = null;
        if (_timerPool.length < 16)
            _timerPool.push(t);
        else
            t.destroy();
    }

    // ── Serial queue (single Process) ───────────────────────────
    Timer {
        id: serialTimeoutTimer
        repeat: false
        onTriggered: {
            if (!root._running || root._serialFinished)
                return;
            Logger.warn("process", root._currentLabel + " timed out after " + interval + "ms, killing");
            proc.running = false;
            serialForceTimer.restart();
        }
    }

    Timer {
        id: serialForceTimer
        interval: 2000
        repeat: false
        onTriggered: {
            if (root._running && !root._serialFinished)
                root._finalizeSerial({
                    exitCode: -1,
                    stdout: "",
                    stderr: "timed out",
                    label: root._currentLabel,
                    timedOut: true
                });
        }
    }

    Process {
        id: proc
        stdout: StdioCollector {
            waitForEnd: true
        }
        stderr: StdioCollector {
            waitForEnd: true
        }

        onExited: function (code) {
            root._finalizeSerial({
                exitCode: code,
                stdout: stdout.text,
                stderr: stderr.text,
                label: root._currentLabel
            });
        }
    }

    function _finalizeSerial(result: var): void {
        if (_serialFinished)
            return;
        _serialFinished = true;
        serialTimeoutTimer.stop();
        serialForceTimer.stop();

        var id = _currentId;
        var callback = _resultCallback;
        var silent = _currentSilent;

        _running = false;
        _resultCallback = null;
        _currentId = "";
        _currentSilent = false;

        if (!silent && result.exitCode !== 0 && !result.timedOut)
            Logger.warn("process", result.label + " failed: " + _errText(result.stderr));

        _busyRelease(id);
        _safeCall(callback, result, result.label);
        _drainQueue();
    }

    function _runInternal(label: string, command, id: string, callback: var, silent: bool, opts: var): void {
        _running = true;
        _serialFinished = false;
        _currentLabel = label;
        _currentId = id;
        _currentSilent = silent;
        _resultCallback = callback || null;

        var timeoutMs = (opts && opts.timeout !== undefined) ? opts.timeout : defaultTimeout;
        if (timeoutMs > 0) {
            serialTimeoutTimer.interval = timeoutMs;
            serialTimeoutTimer.restart();
        } else {
            serialTimeoutTimer.stop();
        }

        proc.command = _normalizeCommand(command, opts);
        proc.running = true;
    }

    function _dequeue(): var {
        if (_queueHead >= _queue.length) {
            if (_queue.length > 0) {
                _queue = [];
                _queueHead = 0;
            }
            return null;
        }
        var e = _queue[_queueHead];
        _queue[_queueHead] = null;
        _queueHead++;
        if (_queueHead >= 32) {
            _queue = _queue.slice(_queueHead);
            _queueHead = 0;
        }
        return e;
    }

    function _queuedCount(): int {
        return _queue.length - _queueHead;
    }

    function _drainQueue(): void {
        if (_running)
            return;
        var next = _dequeue();
        if (!next)
            return;
        _runInternal(next.label, next.command, next.id, next.callback, next.silent, next.opts || {});
    }

    function runQueued(label: string, command, opts: var): void {
        opts = opts || ({});
        var entry = {
            label: label,
            command: command,
            id: opts.id || "",
            callback: opts.callback || null,
            silent: opts.silent || false,
            opts: opts
        };

        if (_running) {
            if (opts.coalesce === true) {
                for (var i = _queueHead; i < _queue.length; i++) {
                    var q = _queue[i];
                    if (q && q.label === entry.label && q.id === entry.id) {
                        q.command = entry.command;
                        q.callback = entry.callback;
                        q.silent = entry.silent;
                        q.opts = entry.opts;
                        return;
                    }
                }
            }
            _busyAcquire(entry.id);
            _queue.push(entry);
            if (_queuedCount() > maxQueue) {
                var dropped = _dequeue();
                if (dropped) {
                    Logger.warn("process", "queue overflow, dropping: " + (dropped.label || dropped.id));
                    _busyRelease(dropped.id);
                }
            }
            return;
        }

        _busyAcquire(entry.id);
        _runInternal(entry.label, entry.command, entry.id, entry.callback, entry.silent, entry.opts);
    }

    function clearQueue(): void {
        for (var i = _queueHead; i < _queue.length; i++) {
            var e = _queue[i];
            if (e)
                _busyRelease(e.id);
        }
        _queue = [];
        _queueHead = 0;
    }

    // ── Parallel tracked (reusable Process pool) ────────────────
    function _ensureComponent(): void {
        if (_trackedComponent)
            return;
        _trackedComponent = Qt.createComponent("TrackedProcess.qml");
        if (_trackedComponent.status === Component.Error)
            Logger.warn("process", "TrackedProcess.qml failed to load: " + _trackedComponent.errorString());
    }

    function _acquireProcess(): var {
        if (_pool.length > 0)
            return _pool.pop();
        _ensureComponent();
        return _trackedComponent.createObject(root);
    }

    function _releaseProcess(item: var): void {
        if (!item)
            return;
        item.stop();
        item.callback = null;
        if (_pool.length < 8)
            _pool.push(item);
        else
            item.destroy();
    }

    function _finishTracked(handle: var, result: var): void {
        if (!handle || handle.finished)
            return;
        handle.finished = true;
        handle.running = false;

        if (handle.timer) {
            _releaseTimer(handle.timer);
            handle.timer = null;
        }

        var idx = _tracked.indexOf(handle);
        if (idx >= 0)
            _tracked.splice(idx, 1);

        _busyRelease(handle.hookId);

        if (!handle.silent && result && result.exitCode !== 0 && !result.stopped && !result.timedOut)
            Logger.warn("process", handle.label + " failed: " + _errText(result.stderr));

        var processObj = handle.proc;
        handle.proc = null;
        _releaseProcess(processObj);

        var cb = handle.callback;
        handle.callback = null;
        _safeCall(cb, result || {
            exitCode: -1,
            stdout: "",
            stderr: "",
            label: handle.label
        }, handle.label);
    }

    function runTracked(label: string, command, opts: var): var {
        opts = opts || ({});
        var handle = {
            id: _trackedIdCounter++,
            label: label,
            command: command,
            hookId: opts.id || "",
            callback: opts.callback || null,
            silent: opts.silent === true,
            running: false,
            finished: false,
            proc: null,
            timer: null
        };

        var processObj = _acquireProcess();
        if (!processObj) {
            Logger.warn("process", "could not create process for: " + label);
            _safeCall(handle.callback, {
                exitCode: -1,
                stdout: "",
                stderr: "process creation failed",
                label: label
            }, label);
            handle.finished = true;
            return handle;
        }

        handle.proc = processObj;
        handle.running = true;
        _tracked.push(handle);

        if (_tracked.length > parallelWarnThreshold)
            Logger.warn("process", _tracked.length + " tracked processes running in parallel");

        _busyAcquire(handle.hookId);

        processObj.callback = function (result) {
            result.label = label;
            root._finishTracked(handle, result);
        };

        var timeoutMs = (opts.timeout !== undefined) ? opts.timeout : defaultTimeout;
        if (timeoutMs > 0) {
            var t = _acquireTimer();
            t.interval = timeoutMs;
            t.onFire = function () {
                if (!handle.finished) {
                    Logger.warn("process", label + " timed out after " + timeoutMs + "ms, killing");
                    root._finishTracked(handle, {
                        exitCode: -1,
                        stdout: "",
                        stderr: "timed out",
                        label: label,
                        timedOut: true
                    });
                }
            };
            handle.timer = t;
            t.start();
        }

        processObj.start(_normalizeCommand(command, opts));
        return handle;
    }

    function runDetached(command, opts: var): void {
        opts = opts || ({});
        Quickshell.execDetached(_normalizeCommand(command, opts));
    }

    function runDetachedBusy(command, id: string, duration: int, opts: var): void {
        opts = opts || ({});
        if (id && !_slotTimers[id])
            _busyAcquire(id);
        Quickshell.execDetached(_normalizeCommand(command, opts));
        if (id)
            _scheduleClear(id, duration || 500);
    }

    function stop(handle: var): void {
        if (!handle)
            return;
        handle.callback = null;
        _finishTracked(handle, {
            exitCode: -1,
            stdout: "",
            stderr: "stopped",
            label: handle.label || "",
            stopped: true
        });
    }

    function stopAll(): void {
        var list = _tracked.slice();
        for (var i = 0; i < list.length; i++)
            stop(list[i]);
        clearQueue();
        if (_running && !_serialFinished) {
            proc.running = false;
            serialForceTimer.restart();
        }
    }

    // ── Busy slot timers (for runDetachedBusy) ──────────────────
    function _scheduleClear(id: string, duration: int): void {
        var existing = _slotTimers[id];
        if (existing) {
            _slotTimers[id] = null;
            _releaseTimer(existing);
        }
        var timer = _acquireTimer();
        timer.interval = duration;
        timer.onFire = function () {
            _slotTimers[id] = null;
            _releaseTimer(timer);
            _busyRelease(id);
        };
        _slotTimers[id] = timer;
        timer.start();
    }
}
