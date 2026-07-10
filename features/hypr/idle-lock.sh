#!/usr/bin/env bash
set -euo pipefail

SETTINGS="${XDG_CONFIG_HOME:-$HOME/.config}/aura-os/settings.json"

enabled="$(python3 - "$SETTINGS" <<'PY' 2>/dev/null || echo 1
import json, sys
try:
    with open(sys.argv[1]) as fh:
        s = json.load(fh)
except Exception:
    s = {}
v = (s.get("lock") or {}).get("autoLock", True)
print("1" if v else "0")
PY
)"

[[ "$enabled" == "1" ]] || exit 0
pidof hyprlock >/dev/null 2>&1 || hyprlock &
