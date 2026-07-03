#!/usr/bin/env bash

if [[ -n "${AURA_BASH_LOG_LOADED:-}" ]]; then
  return 0
fi
AURA_BASH_LOG_LOADED=1

AURA_LOG_LEVEL="${AURA_LOG_LEVEL:-${LOG_LEVEL:-info}}"

aura_log_level_num() {
  case "$1" in
    debug) printf '0\n' ;;
    info) printf '1\n' ;;
    warn) printf '2\n' ;;
    error) printf '3\n' ;;
    *) printf '1\n' ;;
  esac
}

aura_log() {
  local level current target label color reset timestamp
  level="$1"
  shift
  current="$(aura_log_level_num "$AURA_LOG_LEVEL")"
  target="$(aura_log_level_num "$level")"
  (( target < current )) && return 0

  label="$(printf '%s' "$level" | tr '[:lower:]' '[:upper:]')"
  timestamp="$(date '+%H:%M:%S')"
  reset=''
  color=''

  if [[ -t 2 ]]; then
    case "$level" in
      debug) color='\033[36m' ;;
      info) color='\033[34m' ;;
      warn) color='\033[33m' ;;
      error) color='\033[31m' ;;
    esac
    reset='\033[0m'
  fi

  printf '%b[%s] [%s]%b %s\n' "$color" "$timestamp" "$label" "$reset" "$*" >&2
}

log_debug() { aura_log debug "$@"; }
log_info() { aura_log info "$@"; }
log_warn() { aura_log warn "$@"; }
log_error() { aura_log error "$@"; }
log_ok() {
  if [[ -t 2 ]]; then
    printf '\033[32m[%s] [OK]\033[0m %s\n' "$(date '+%H:%M:%S')" "$*" >&2
  else
    printf '[%s] [OK] %s\n' "$(date '+%H:%M:%S')" "$*" >&2
  fi
}
