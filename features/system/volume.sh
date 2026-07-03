#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core/bash" && pwd)/bootstrap.sh"

readonly STEP=5

usage() {
  echo "Usage: $0 [up|down|toggle-mute|toggle-mic|set <0-100>]" >&2
}

main() {
  case "${1:-}" in
    up)
      wpctl set-volume @DEFAULT_AUDIO_SINK@ "${STEP}%+"
      wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
      ;;
    down)
      wpctl set-volume @DEFAULT_AUDIO_SINK@ "${STEP}%-"
      ;;
    toggle-mute)
      wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      ;;
    toggle-mic)
      wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
      ;;
    set)
      [[ -n "${2:-}" ]] || { usage; exit 1; }
      wpctl set-volume @DEFAULT_AUDIO_SINK@ "${2}%"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
