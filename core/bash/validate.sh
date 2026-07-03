#!/usr/bin/env bash

if [[ -n "${AURA_BASH_VALIDATE_LOADED:-}" ]]; then
  return 0
fi
AURA_BASH_VALIDATE_LOADED=1

is_hex_color() {
  local value="${1#\#}"
  [[ "$value" =~ ^[0-9A-Fa-f]{6}$ ]]
}

require_file() {
  if [[ ! -f "$1" ]]; then
    log_error "Required file not found: $1"
    return 1
  fi
}

require_dir() {
  if [[ ! -d "$1" ]]; then
    log_error "Required directory not found: $1"
    return 1
  fi
}

require_hex_color() {
  if ! is_hex_color "$1"; then
    log_error "Invalid hex color: $1"
    return 1
  fi
}
