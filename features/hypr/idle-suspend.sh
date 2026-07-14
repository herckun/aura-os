#!/usr/bin/env bash
set -euo pipefail

SETTINGS="${XDG_CONFIG_HOME:-$HOME/.config}/aura-os/settings.json"

enabled="$(python3 - "$SETTINGS" <<'PY' 2>/dev/null || echo 0
import json, sys
try:
    with open(sys.argv[1]) as fh:
        s = json.load(fh)
except Exception:
    s = {}
v = (s.get("power") or {}).get("autoSuspend", False)
print("1" if v else "0")
PY
)"

[[ "$enabled" == "1" ]] || exit 0
systemctl suspend
