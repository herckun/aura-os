#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core/bash" && pwd)/bootstrap.sh"

readonly STEP=5

usage() {
  echo "Usage: $0 [up|down|toggle-mute|toggle-mic|set <0-100>]" >&2
}

# ── EE routing: the audible volume lives on the device EasyEffects outputs to ──
sink_target() {
  local name
  name="$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | sed -n 's/.*node\.name = "\([^"]*\)".*/\1/p' | head -1)"
  if [[ "$name" == "easyeffects_sink" ]]; then
    local id
    id="$(pw-dump 2>/dev/null | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit()
props = {}
for o in d:
    if str(o.get('type', '')).endswith('Node'):
        props[o['id']] = (o.get('info') or {}).get('props') or {}
ee = {i for i, p in props.items() if p.get('application.id') == 'com.github.wwmm.easyeffects' or str(p.get('node.name', '')).startswith('ee_')}
sinks = {i for i, p in props.items() if p.get('media.class') == 'Audio/Sink' and p.get('node.name') != 'easyeffects_sink'}
for o in d:
    if not str(o.get('type', '')).endswith('Link'):
        continue
    info = o.get('info') or {}
    if info.get('output-node-id') in ee and info.get('input-node-id') in sinks:
        print(info.get('input-node-id'))
        break
" || true)"
    if [[ -n "$id" ]]; then
      echo "$id"
      return
    fi
  fi
  echo "@DEFAULT_AUDIO_SINK@"
}

main() {
  local sink
  case "${1:-}" in
    up)
      sink="$(sink_target)"
      wpctl set-volume "$sink" "${STEP}%+"
      wpctl set-mute "$sink" 0
      ;;
    down)
      wpctl set-volume "$(sink_target)" "${STEP}%-"
      ;;
    toggle-mute)
      wpctl set-mute "$(sink_target)" toggle
      ;;
    toggle-mic)
      wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
      ;;
    set)
      [[ -n "${2:-}" ]] || { usage; exit 1; }
      wpctl set-volume "$(sink_target)" "${2}%"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
