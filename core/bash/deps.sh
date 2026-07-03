#!/usr/bin/env bash

if [[ -n "${AURA_BASH_DEPS_LOADED:-}" ]]; then
  return 0
fi
AURA_BASH_DEPS_LOADED=1

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

require_cmd() {
  if ! have_cmd "$1"; then
    log_error "Required command not found: $1"
    return 1
  fi
}

require_all() {
  local missing=() cmd
  for cmd in "$@"; do
    have_cmd "$cmd" || missing+=("$cmd")
  done

  if (( ${#missing[@]} > 0 )); then
    log_error "Missing commands: ${missing[*]}"
    return 1
  fi
}
