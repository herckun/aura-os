#!/usr/bin/env bash

if [[ -n "${AURA_BASH_BOOTSTRAP_LOADED:-}" ]]; then
  return 0
fi
AURA_BASH_BOOTSTRAP_LOADED=1

_aura_bootstrap_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export AURA_CORE_BASH_DIR="$_aura_bootstrap_dir"
# shellcheck disable=SC2155 — single assignment, failure is non-critical
export AURA_REPO_DIR="$(cd "$_aura_bootstrap_dir/../.." && pwd)"
export AURA_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
export AURA_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export AURA_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"

# shellcheck source=/dev/null
source "$_aura_bootstrap_dir/app.sh"
# shellcheck source=/dev/null
source "$_aura_bootstrap_dir/paths.sh"
# shellcheck source=/dev/null
source "$_aura_bootstrap_dir/log.sh"
# shellcheck source=/dev/null
source "$_aura_bootstrap_dir/deps.sh"
# shellcheck source=/dev/null
source "$_aura_bootstrap_dir/fs.sh"
# shellcheck source=/dev/null
source "$_aura_bootstrap_dir/validate.sh"
# shellcheck source=/dev/null
source "$_aura_bootstrap_dir/colors.sh"
# shellcheck source=/dev/null
source "$_aura_bootstrap_dir/json.sh"

unset _aura_bootstrap_dir
