pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"

Singleton {
  id: svc

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC STATE
  // ═══════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════

  function get(url: string, callback: var, headers: var): void {
    _request("GET", url, null, callback, headers)
  }

  function post(url: string, body: string, callback: var, headers: var): void {
    _request("POST", url, body, callback, headers)
  }

  function put(url: string, body: string, callback: var, headers: var): void {
    _request("PUT", url, body, callback, headers)
  }

  function del(url: string, callback: var, headers: var): void {
    _request("DELETE", url, null, callback, headers)
  }

  // ═══════════════════════════════════════════════════════════════
  //  INTERNAL STATE
  // ═══════════════════════════════════════════════════════════════

  property int _nextId: 0

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════

  function _request(method: string, url: string, body: string, callback: var, headers: var): void {
    var id = "http-" + _nextId++
    var parts = ["curl", "-s", "-S", "-X", method, "--max-time", "15", "-w", "\\n%{http_code}"]

    if (headers) {
      for (var k in headers) {
        parts.push("-H")
        parts.push(k + ": " + headers[k])
      }
    }

    if (body && (method === "POST" || method === "PUT")) {
      parts.push("-H")
      parts.push("Content-Type: application/json")
      parts.push("-d")
      parts.push(body)
    }

    parts.push(url)

    ProcessPool.runTracked("HTTP " + method, parts, {
      id: id,
      callback: function(r) {
        if (!callback) return

        var response = _parseResponse(r.stdout, r.exitCode)
        if (r.exitCode !== 0) {
          callback({ ok: false, status: 0, data: null, error: r.stderr || "Request failed" })
        } else {
          callback(response)
        }
      }
    })
  }

  function _parseResponse(stdout: string, exitCode: int): var {
    if (!stdout || stdout.length === 0) return { ok: false, status: 0, data: null, error: "Empty response" }

    var lines = stdout.trim().split("\n")
    var statusCode = 0
    var body = ""

    if (lines.length >= 2) {
      statusCode = parseInt(lines[lines.length - 1]) || 0
      body = lines.slice(0, -1).join("\n")
    } else {
      body = lines[0]
    }

    var data = null
    if (body.length > 0) {
      try {
        data = JSON.parse(body)
      } catch (e) {
        data = body
      }
    }

    return {
      ok: statusCode >= 200 && statusCode < 300,
      status: statusCode,
      data: data,
      error: statusCode >= 400 ? "HTTP " + statusCode : ""
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  TIMERS
  // ═══════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════

}
