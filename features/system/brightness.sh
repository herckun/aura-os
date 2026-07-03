#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core/bash" && pwd)/bootstrap.sh"

readonly STEP=10

usage() {
  echo "Usage: $0 [up|down|set <0-100>|get]" >&2
}

main() {
  case "${1:-}" in
    up)
      brightnessctl set "${STEP}%+"
      ;;
    down)
      brightnessctl set "${STEP}%-"
      ;;
    set)
      [[ -n "${2:-}" ]] || { usage; exit 1; }
      brightnessctl set "${2}%"
      ;;
    get)
      brightnessctl g
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
