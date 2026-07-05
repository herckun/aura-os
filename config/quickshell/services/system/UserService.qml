pragma Singleton
import QtQml
import QtQuick
import Quickshell
import "../../core"

Singleton {
  id: svc

  readonly property string userName: Quickshell.env("USER") || "user"
  property string realName: ""
  property string avatarPath: ""
  property bool avatarExists: false
  property int avatarRev: 0
  property string lastError: ""
  property bool busy: false

  readonly property string displayName: realName !== "" ? realName : userName
  readonly property string avatarSource: avatarExists && avatarPath !== "" ? "file://" + avatarPath + "?" + avatarRev : ""
  readonly property string initial: displayName.charAt(0).toUpperCase()

  function init(): void {}

  function refresh(): void {
    ProcessPool.runTracked("User: read profile", [
      "sh", "-c",
      'u=$(id -u); p="org.freedesktop.Accounts /org/freedesktop/Accounts/User$u org.freedesktop.Accounts.User"; ' +
      'rn=$(busctl --system get-property $p RealName 2>/dev/null); ' +
      'ic=$(busctl --system get-property $p IconFile 2>/dev/null); ' +
      'printf "%s\\n%s\\n" "$rn" "$ic"; ' +
      'f=$(printf "%s" "$ic" | sed \'s/^s "//; s/"$//\'); [ -n "$f" ] && [ -f "$f" ] && echo 1 || echo 0'
    ], {
      id: "user-profile-read",
      silent: true,
      callback: function(r) {
        var lines = (r.stdout || "").split("\n")
        svc.realName = svc._unquote(lines[0] || "")
        svc.avatarPath = svc._unquote(lines[1] || "")
        svc.avatarExists = (lines[2] || "0").trim() === "1"
        svc.avatarRev++
      }
    })
  }

  function setRealName(name: string): void {
    var trimmed = (name || "").trim()
    if (trimmed === "" || trimmed === realName) return
    svc.busy = true
    svc.lastError = ""
    ProcessPool.runTracked("User: set name", [
      "sh", "-c",
      'busctl --system call org.freedesktop.Accounts "/org/freedesktop/Accounts/User$(id -u)" org.freedesktop.Accounts.User SetRealName s "$1"',
      "--", trimmed
    ], {
      id: "user-set-name",
      callback: function(r) {
        svc.busy = false
        if (r.exitCode !== 0) svc.lastError = (r.stderr || "Could not update the display name").trim()
        else svc.refresh()
      }
    })
  }

  function setAvatar(sourcePath: string): void {
    if (!sourcePath || sourcePath.length === 0) return
    svc.busy = true
    svc.lastError = ""
    ProcessPool.runTracked("User: set avatar", [
      "sh", "-c",
      'cp -f "$1" "$HOME/.face" && busctl --system call org.freedesktop.Accounts "/org/freedesktop/Accounts/User$(id -u)" org.freedesktop.Accounts.User SetIconFile s "$HOME/.face"',
      "--", sourcePath
    ], {
      id: "user-set-avatar",
      callback: function(r) {
        svc.busy = false
        if (r.exitCode !== 0) svc.lastError = (r.stderr || "Could not update the avatar").trim()
        else svc.refresh()
      }
    })
  }

  function pickAvatar(): void {
    ProcessPool.runTracked("User: pick avatar",
      "kdialog --getopenfilename \"$HOME/Pictures\" '*.png *.jpg *.jpeg *.webp'",
      {
        id: "user-pick-avatar",
        shell: true,
        callback: function(r) {
          if (r.exitCode === 0 && r.stdout.trim().length > 0) svc.setAvatar(r.stdout.trim())
        }
      }
    )
  }

  function _unquote(raw: string): string {
    var t = raw.trim()
    if (t.indexOf('s "') === 0) t = t.substring(3, t.length - 1)
    return t
  }

  Component.onCompleted: refresh()
}
