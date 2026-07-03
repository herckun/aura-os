#!/usr/bin/env bash

if [[ -n "${AURA_BASH_PATHS_LOADED:-}" ]]; then
  return 0
fi
AURA_BASH_PATHS_LOADED=1

aura_init_paths() {
  local core_dir repo_dir env_cache_var default_cache_dir
  core_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  repo_dir="${AURA_REPO_DIR:-$(cd "$core_dir/../.." && pwd)}"
  env_cache_var="${APP_ENV_PREFIX:-AURA_OS}_CACHE_DIR"
  default_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/${APP_CACHE_KEY:-${APP_NAME:-aura-os}}"

  export AURA_REPO_DIR="$repo_dir"
  export AURA_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
  export AURA_CACHE_DIR="${!env_cache_var:-$default_cache_dir}"
  export AURA_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
  export AURA_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/${APP_CACHE_KEY:-${APP_NAME:-aura-os}}"
}

aura_repo_path() {
  printf '%s/%s\n' "$AURA_REPO_DIR" "$1"
}

aura_init_paths
