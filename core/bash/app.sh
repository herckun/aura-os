#!/usr/bin/env bash

if [[ -n "${AURA_BASH_APP_LOADED:-}" ]]; then
  return 0
fi
AURA_BASH_APP_LOADED=1

_aura_set_app_defaults() {
  APP_NAME="aura-os"
  APP_DISPLAY="AuraOS"
  APP_VERSION="2.0"
  APP_LOGO="logo"
  APP_THEME_KEY="aura-os"
  APP_CACHE_KEY="aura-os"
  APP_ENV_PREFIX="AURA_OS"
}

aura_load_app_info() {
  local app_dir repo_dir manifest output
  app_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  repo_dir="${AURA_REPO_DIR:-$(cd "$app_dir/../.." && pwd)}"
  manifest="${1:-${APP_MANIFEST:-${AURA_APP_MANIFEST:-$repo_dir/config/manifest.json}}}"

  _aura_set_app_defaults

  if [[ -f "$manifest" ]] && command -v python3 >/dev/null 2>&1; then
    output="$(APP_MANIFEST_PATH="$manifest" python3 - <<'PY'
import json
import os
import shlex
import sys

manifest = os.environ["APP_MANIFEST_PATH"]
with open(manifest, "r", encoding="utf-8") as handle:
    data = json.load(handle)

app = data.get("app", {})
name = app.get("name", "aura-os")
values = {
    "APP_NAME": name,
    "APP_DISPLAY": app.get("displayName", "AuraOS"),
    "APP_VERSION": app.get("version", "2.0"),
    "APP_LOGO": app.get("logo", "logo"),
    "APP_THEME_KEY": app.get("themeKey", name),
    "APP_CACHE_KEY": app.get("cacheKey", name),
    "APP_ENV_PREFIX": name.upper().replace("-", "_"),
}
for key, value in values.items():
    print(f"{key}={shlex.quote(str(value))}")
PY
)" || true

    if [[ -n "$output" ]]; then
      # shellcheck disable=SC2086 — output is structured key=value from controlled Python, eval is intentional
      eval "$output"
    fi
  fi

  export APP_NAME APP_DISPLAY APP_VERSION APP_LOGO APP_THEME_KEY APP_CACHE_KEY APP_ENV_PREFIX
  export AURA_APP_MANIFEST="$manifest"
}

aura_load_app_info

unset -f _aura_set_app_defaults
