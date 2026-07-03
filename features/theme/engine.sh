#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core/bash" && pwd)/bootstrap.sh"

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly THEME_DIR="$SCRIPT_DIR"
readonly STATE_DIR="${AURA_CACHE_DIR}/theme-engine"
readonly GTK_THEME_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/themes/${APP_THEME_KEY}"
readonly KVANTUM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/Kvantum/${APP_DISPLAY}"
readonly KVANTUM_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/Kvantum/kvantum.kvconfig"
readonly KITTY_THEME_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/kitty/current-theme.conf"
readonly FISH_THEME_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/fish/conf.d/${APP_NAME}-theme.fish"
readonly GTK3_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0"
readonly GTK4_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0"
readonly GTK2_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-2.0"
readonly WLEAVE_STYLE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/wleave/style.css"
readonly SDDM_THEME_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/${APP_NAME}/sddm-theme.json"

INPUT_JSON="${1:-"{}"}"
PIDS=()
NAMES=()
FAILURES=0
ROLLBACK_DIR=""

ensure_state_dir() {
  ensure_dir "$STATE_DIR"
}

normalize_input_json() {
  python3 - "$INPUT_JSON" <<'PY'
import json
import sys

raw = sys.argv[1] if len(sys.argv) > 1 else "{}"
defaults = {
    "accent": "D71921",
    "shellMode": 0,
    "transparency": True,
    "animations": True,
    "monochrome": False,
    "blur": True,
}

try:
    data = json.loads(raw or "{}")
    if not isinstance(data, dict):
        raise ValueError("expected object")
except Exception:
    data = {}

accent = str(data.get("accent", defaults["accent"]))
accent = accent.lstrip("#").upper()
if len(accent) != 6 or any(ch not in "0123456789ABCDEF" for ch in accent):
    accent = defaults["accent"]

def to_bool(value, default):
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        return value.strip().lower() in ("1", "true", "yes", "on")
    return default

try:
    shell_mode = int(data.get("shellMode", defaults["shellMode"]))
except Exception:
    shell_mode = defaults["shellMode"]
if shell_mode not in (0, 1, 2, 3, 4):
    shell_mode = defaults["shellMode"]

result = {
    "accent": accent,
    "shellMode": shell_mode,
    "transparency": to_bool(data.get("transparency", defaults["transparency"]), defaults["transparency"]),
    "animations": to_bool(data.get("animations", defaults["animations"]), defaults["animations"]),
    "monochrome": to_bool(data.get("monochrome", defaults["monochrome"]), defaults["monochrome"]),
    "blur": to_bool(data.get("blur", defaults["blur"]), defaults["blur"]),
}
print(json.dumps(result, separators=(",", ":")))
PY
}

backup_path() {
  local path="$1"
  local slot
  slot="$(python3 - "$path" <<'PY'
import hashlib
import sys
print(hashlib.sha1(sys.argv[1].encode()).hexdigest())
PY
)"

  if [[ -e "$path" || -L "$path" ]]; then
    cp -a "$path" "$ROLLBACK_DIR/$slot"
    printf 'present\n' > "$ROLLBACK_DIR/$slot.state"
  else
    printf 'missing\n' > "$ROLLBACK_DIR/$slot.state"
  fi
  printf '%s\n' "$path" >> "$ROLLBACK_DIR/index"
}

restore_backups() {
  [[ -n "$ROLLBACK_DIR" && -d "$ROLLBACK_DIR" && -f "$ROLLBACK_DIR/index" ]] || return 0

  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    local slot state_file state
    slot="$(python3 - "$path" <<'PY'
import hashlib
import sys
print(hashlib.sha1(sys.argv[1].encode()).hexdigest())
PY
)"
    state_file="$ROLLBACK_DIR/$slot.state"
    state="missing"
    [[ -f "$state_file" ]] && read -r state < "$state_file"

    if [[ "$state" == "present" ]]; then
      rm -rf "$path"
      mkdir -p "$(dirname "$path")"
      cp -a "$ROLLBACK_DIR/$slot" "$path"
    else
      rm -rf "$path"
    fi
  done < "$ROLLBACK_DIR/index"
}

prepare_rollback() {
  ROLLBACK_DIR="$(mktemp -d "${STATE_DIR}/rollback.XXXXXX")"
  : > "$ROLLBACK_DIR/index"

  backup_path "$KITTY_THEME_FILE"
  backup_path "$FISH_THEME_FILE"
  backup_path "$GTK3_DIR"
  backup_path "$GTK4_DIR"
  backup_path "$GTK2_DIR"
  backup_path "$GTK_THEME_DIR"
  backup_path "$KVANTUM_DIR"
  backup_path "$KVANTUM_CONFIG"
  backup_path "$WLEAVE_STYLE_FILE"
  backup_path "$SDDM_THEME_FILE"
}

run_bg() {
  local name="$1"
  shift
  local script="$1"
  shift

  if [[ ! -x "$script" ]]; then
    log_warn "Theme generator missing: $name ($script)"
    return 0
  fi

  log_info "Theme generator start: $name"
  "$script" "$@" &
  PIDS+=("$!")
  NAMES+=("$name")
}

wait_for_generators() {
  local i
  for i in "${!PIDS[@]}"; do
    if wait "${PIDS[$i]}"; then
      log_ok "Theme generator done: ${NAMES[$i]}"
    else
      log_error "Theme generator failed: ${NAMES[$i]}"
      FAILURES=$((FAILURES + 1))
    fi
  done
}

cleanup() {
  if (( FAILURES > 0 )); then
    log_warn "Theme engine restoring previous outputs"
    restore_backups || true
  fi
  [[ -n "$ROLLBACK_DIR" && -d "$ROLLBACK_DIR" ]] && rm -rf "$ROLLBACK_DIR"
}
trap cleanup EXIT

main() {
  ensure_state_dir

  local normalized_json
  normalized_json="$(normalize_input_json)"

  prepare_rollback

  run_bg "kitty" "$THEME_DIR/kitty.sh" "$normalized_json"
  run_bg "fish" "$THEME_DIR/fish.sh" "$normalized_json"
  run_bg "gtk-qt" "$THEME_DIR/gtk-qt.sh" "$normalized_json"
  run_bg "wleave" "$THEME_DIR/wleave.sh" "$normalized_json"
  run_bg "sddm" "$THEME_DIR/sddm.sh" "$normalized_json"

  wait_for_generators

  if (( FAILURES > 0 )); then
    log_error "Theme engine failed ($FAILURES generator(s))"
    exit 1
  fi

  log_ok "Theme engine complete"
}

main "$@"
