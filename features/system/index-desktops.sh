#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core/bash" && pwd)/bootstrap.sh"

main() {
  local dir file name exec icon keywords categories
  for dir in /usr/share/applications /usr/local/share/applications "$HOME/.local/share/applications"; do
    [[ -d "$dir" ]] || continue
    find "$dir" -maxdepth 1 -type f -name '*.desktop'
  done | sort -u | while IFS= read -r file; do
    grep -q '^NoDisplay=true' "$file" 2>/dev/null && continue
    name="$(grep -m1 '^Name=' "$file" | cut -d= -f2- || true)"
    [[ -n "$name" ]] || continue
    exec="$(grep -m1 '^Exec=' "$file" | cut -d= -f2- | sed 's/%[fFuUdDnNickvm]//g' || true)"
    [[ -n "$exec" ]] || continue
    icon="$(grep -m1 '^Icon=' "$file" | cut -d= -f2- || true)"
    keywords="$(grep -m1 '^Keywords=' "$file" | cut -d= -f2- || true)"
    categories="$(grep -m1 '^Categories=' "$file" | cut -d= -f2- || true)"
    printf '%s||%s||%s||%s||%s\n' "$name" "$exec" "$icon" "$keywords" "$categories"
  done
}

main "$@"
