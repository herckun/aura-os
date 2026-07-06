#!/usr/bin/env bash
# Installer orchestrator.
# Usage: ./install.sh [--express|--expert|--uninstall|--add-community <url>|--help]

set -euo pipefail

if [[ -z "${AURA_BASH_BOOTSTRAP_LOADED:-}" ]]; then
  # shellcheck source=/dev/null
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core/bash" && pwd)/bootstrap.sh"
fi

# ── Base paths / identity defaults ───────────────────────────────────
REPO_DIR="${AURA_REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
CONFIG_DIR="${AURA_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}}"
MANIFEST_PATH="$REPO_DIR/config/manifest.json"

APP_NAME="${APP_NAME:-aura-os}"
APP_DISPLAY="${APP_DISPLAY:-AuraOS}"
APP_VERSION="${APP_VERSION:-2.0}"
APP_ENV_PREFIX="${APP_ENV_PREFIX:-AURA_OS}"

load_manifest() {
  [[ -f "$MANIFEST_PATH" ]] || { _err "Manifest not found: $MANIFEST_PATH"; exit 1; }
  local _lib
  _lib="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/manifest_lib.py"
  # shellcheck disable=SC2046 — eval of controlled Python output is intentional
  eval "$(python3 "$_lib" installvars "$MANIFEST_PATH")"
}

# ── Colors / minimal output helpers ──────────────────────────────────
R=$'\033[38;2;215;25;33m'
G=$'\033[0;32m'
Y=$'\033[0;33m'
C=$'\033[0;36m'
W=$'\033[1;37m'
DIM=$'\033[2m'
BOLD=$'\033[1m'
NC=$'\033[0m'

COLS=$(tput cols 2>/dev/null || echo 80)
ROWS=$(tput lines 2>/dev/null || echo 24)

# shellcheck disable=SC2059 — format strings use ANSI color variables intentionally
_err()  { printf "  ${R}✗${NC} %s\n" "$1" >&2; }
# shellcheck disable=SC2059
_ok()   { if $TUI_ACTIVE; then log_ok "$1"; else printf "  ${G}✓${NC} %s\n" "$1"; fi; }
# shellcheck disable=SC2059
_info() { if $TUI_ACTIVE; then log_info "$1"; else printf "  ${DIM}·${NC} %s\n" "$1"; fi; }

_hr() {
  COLS=$(tput cols 2>/dev/null || echo 80)
  # shellcheck disable=SC2059
  printf "  ${DIM}"
  # shellcheck disable=SC2046 — word splitting of seq output is intentional for printf repetition
  printf '%.0s─' $(seq 1 $(( COLS - 4 )))
  # shellcheck disable=SC2059
  printf "${NC}\n"
}

# Manifest-backed identity and dependency inventory.
load_manifest

# ── Derived runtime paths ────────────────────────────────────────────
_envCacheVar="${APP_ENV_PREFIX}_CACHE_DIR"
CACHE_DIR="${AURA_CACHE_DIR:-${!_envCacheVar:-${XDG_CACHE_HOME:-$HOME/.cache}/${APP_NAME}}}"
OLD_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/aura"
BACKUP_DIR="${CACHE_DIR}/backups"
MANIFEST="${CACHE_DIR}/manifest.txt"
STATE_FILE="${CACHE_DIR}/state"

pf() { printf '%s' "$1" | cut -d'|' -f"$2"; }

MANAGED_DIRS=(hypr quickshell features dev core wallpapers kitty fish wleave)

# ── Installer state ──────────────────────────────────────────────────
BACKUP_SNAPSHOT=""
SUDO_REFRESH_PID=""
TUI_ACTIVE=false
TUI_TORN_DOWN=false

INSTALL_ERRORS=()
INSTALL_WARNINGS=()
selected_app_ids=()

MODE="welcome"      # welcome | install | uninstall | community
INSTALL_MODE=""     # express | expert
NO_DEPS=false
NO_BACKUP=false
RESET_LAYOUT=false
NONINTERACTIVE=false
CONFIRM_EACH=false
COMMUNITY_URL=""
PREFER_BIN=true

RUN_BACKUP=true
RUN_DEPS=true
RUN_GPU=true
RUN_FONTS=true
RUN_SCREENSHARE=true
RUN_HYPR=true
RUN_QS=true
RUN_ICONS=true
RUN_SFX=true
RUN_KITTY=true
RUN_FISH=true
RUN_SDDM=true
RUN_WLEAVE=true
RUN_CAVA=true
RUN_SCRIPTS=true
RUN_THEME=true
RUN_PLUGINS=true
RUN_APPS=false

TUI_HEADER_MODE=""
TUI_STEP_NAME=""
TUI_STEP_NUM=0
TUI_STEP_TOTAL=0
TUI_LOGS=()
TUI_LOG_MAX=20
TUI_TOP=0
TUI_BOTTOM=0
TUI_FD=3

cleanup() {
  [[ -n "${SUDO_REFRESH_PID:-}" ]] && kill "$SUDO_REFRESH_PID" 2>/dev/null || true
  if [[ "${TUI_TORN_DOWN:-false}" != "true" ]]; then
    if [[ -e /dev/tty ]]; then
      printf '\033[?25h\033[?1049l\033[H\033[3J\033[2J' >/dev/tty 2>/dev/null || true
    fi 2>/dev/null || true
  fi
}
trap cleanup EXIT
trap 'cleanup; exit 130' INT TERM

# ── Cache migration ──────────────────────────────────────────────────
if [[ -d "$OLD_CACHE_DIR" && ! -d "$CACHE_DIR" ]]; then
  mkdir -p "$(dirname "$CACHE_DIR")"
  mv "$OLD_CACHE_DIR" "$CACHE_DIR" 2>/dev/null || true
fi

# ── Extracted installer modules ──────────────────────────────────────
# shellcheck source=/dev/null
source "$REPO_DIR/features/install/backup.sh"
# shellcheck source=/dev/null
source "$REPO_DIR/features/install/core.sh"
# shellcheck source=/dev/null
source "$REPO_DIR/features/install/plugins.sh"
# shellcheck source=/dev/null
source "$REPO_DIR/features/install/ui.sh"
# shellcheck source=/dev/null
source "$REPO_DIR/features/install/configs.sh"

_show_help() {
  cat <<EOF

  ${APP_DISPLAY} — Hyprland QuickShell Environment

  USAGE
    ./install.sh [MODE] [OPTIONS]

  MODES
    (none)               Interactive welcome screen
    --express            Install everything, best defaults
    --expert             Choose what runs
    --quick              Quick dev deploy (no deps/backup/fonts/sddm/plugins/theme)
    --uninstall          Remove ${APP_DISPLAY} and restore backup
    --add-community URL  Install a community plugin

  OPTIONS
    --no-deps            Skip package installation
    --no-backup          Skip config snapshot
    --skip-icons         Skip icon sync
    --skip-sfx           Skip sound effects sync
    --reset-layout       Reset the plugin layout to defaults (otherwise your layout is preserved)

EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --express)        MODE="install"; INSTALL_MODE="express"; shift ;;
    --expert)         MODE="install"; INSTALL_MODE="expert"; shift ;;
    --quick)          MODE="install"; INSTALL_MODE="express"; NONINTERACTIVE=true; NO_DEPS=true; NO_BACKUP=true; RUN_DEPS=false; RUN_GPU=false; RUN_SCREENSHARE=false; RUN_BACKUP=false; RUN_ICONS=false; RUN_SFX=false; RUN_FONTS=false; RUN_SDDM=false; RUN_THEME=false; RUN_PLUGINS=false; shift ;;
    --uninstall)      MODE="uninstall"; shift ;;
    --add-community)  MODE="community"; COMMUNITY_URL="${2:-}"; shift 2 ;;
    --help|-h)        _show_help ;;
    --no-deps)        NO_DEPS=true; RUN_DEPS=false; RUN_GPU=false; RUN_SCREENSHARE=false; shift ;;
    --no-backup)      NO_BACKUP=true; RUN_BACKUP=false; shift ;;
    --skip-icons)     RUN_ICONS=false; shift ;;
    --skip-sfx)       RUN_SFX=false; shift ;;
    --reset-layout)   RESET_LAYOUT=true; shift ;;
    *) _err "Unknown option: $1"; exit 1 ;;
  esac
done

count_install_steps() {
  TUI_STEP_TOTAL=0
  $RUN_BACKUP && (( TUI_STEP_TOTAL++ )) || true
  $RUN_DEPS && (( TUI_STEP_TOTAL++ )) || true
  $RUN_GPU && (( TUI_STEP_TOTAL++ )) || true
  $RUN_SCREENSHARE && (( TUI_STEP_TOTAL++ )) || true
  $RUN_FONTS && (( TUI_STEP_TOTAL++ )) || true
  { $RUN_APPS && (( ${#selected_app_ids[@]} > 0 )); } && (( TUI_STEP_TOTAL++ )) || true
  $RUN_HYPR && (( TUI_STEP_TOTAL += 2 )) || true
  $RUN_QS && (( TUI_STEP_TOTAL++ )) || true
  $RUN_ICONS && (( TUI_STEP_TOTAL++ )) || true
  $RUN_SFX && (( TUI_STEP_TOTAL++ )) || true
  $RUN_KITTY && (( TUI_STEP_TOTAL++ )) || true
  $RUN_FISH && (( TUI_STEP_TOTAL++ )) || true
  $RUN_SDDM && (( TUI_STEP_TOTAL++ )) || true
  $RUN_WLEAVE && (( TUI_STEP_TOTAL++ )) || true
  $RUN_CAVA && (( TUI_STEP_TOTAL++ )) || true
  $RUN_SCRIPTS && (( TUI_STEP_TOTAL++ )) || true
  $RUN_SCRIPTS && $RUN_THEME && (( TUI_STEP_TOTAL++ )) || true
  $RUN_PLUGINS && (( TUI_STEP_TOTAL++ )) || true
  $RESET_LAYOUT && (( TUI_STEP_TOTAL++ )) || true
}

do_install() {
  ensure_cache
  mkdir -p "$CONFIG_DIR"
  count_install_steps

  if ! $NONINTERACTIVE; then
    TUI_HEADER_MODE="$INSTALL_MODE"
    tui_init
  fi

  $RUN_BACKUP && run_step "Backing up existing configs" "snapshot_configs"
  $RUN_DEPS && run_step "Installing system packages" "install_deps"
  $RUN_GPU && run_step "GPU drivers (autodetect)" "install_gpu_drivers"
  $RUN_SCREENSHARE && run_step "Screen-sharing support" "install_screenshare"
  $RUN_FONTS && run_step "Installing fonts" "install_fonts"
  { $RUN_APPS && (( ${#selected_app_ids[@]} > 0 )); } && run_step "Optional applications" "install_apps"
  $RUN_HYPR && run_step "Hyprland configuration" "deploy_hypr_config"
  $RUN_HYPR && run_step "Qt styling env" "deploy_qt_styling_env"
  $RUN_QS && run_step "QuickShell configuration" "deploy_quickshell_config"
  $RUN_ICONS && run_step "Tabler icon set" "sync_tabler_icons"
  $RUN_SFX && run_step "Sound effects" "sync_sfx"
  $RUN_KITTY && run_step "Kitty terminal profile" "deploy_kitty_profile"
  $RUN_FISH && run_step "Fish shell config" "deploy_fish_config"
  $RUN_SDDM && run_step "SDDM greeter theme" "deploy_sddm_theme"
  $RUN_WLEAVE && run_step "wleave config" "deploy_wleave_config"
  $RUN_CAVA && run_step "cava config" "deploy_cava_config"
  $RUN_SCRIPTS && run_step "Desktop scripts" "deploy_desktop_scripts"
  $RUN_SCRIPTS && $RUN_THEME && run_step "Generate GTK/Qt themes" "generate_gtk_qt_themes"
  $RUN_PLUGINS && run_step "Plugins" "deploy_plugins_step"
  $RESET_LAYOUT && run_step "Reset plugin layout" "reset_plugin_layout"

  finish_install
}

do_uninstall() {
  clear
  # shellcheck disable=SC2059 — ANSI color variables in format strings are intentional throughout
  printf "\n  ${BOLD}${APP_DISPLAY} — Uninstall${NC}\n\n"

  if [[ ! -f "$MANIFEST" && ! -d "$CONFIG_DIR/quickshell" && ! -d "$CONFIG_DIR/hypr" ]]; then
    printf "  No ${APP_DISPLAY} installation found.\n\n"
    exit 0
  fi

  printf "  This will remove all ${APP_DISPLAY} configs and symlinks.\n"
  printf "  Continue? ${DIM}[y/N]${NC}: "
  read -r _r
  [[ "$_r" =~ ^[Yy]$ ]] || { printf "  Cancelled.\n\n"; exit 0; }

  if [[ -f "$MANIFEST" ]]; then
    while IFS= read -r path; do
      [[ -z "$path" ]] && continue
      rm -rf "$path" 2>/dev/null && _ok "Removed: $path" || true
    done < "$MANIFEST"
  fi

  local sddm="/usr/share/sddm/themes/${APP_NAME}"
  [[ -d "$sddm" || -L "$sddm" ]] && { sudo -n rm -rf "$sddm" 2>/dev/null && _ok "SDDM removed" || true; }

  [[ -d "$CONFIG_DIR/wleave" ]] && { rm -rf "$CONFIG_DIR/wleave" && _ok "wleave config removed" || true; }

  local comm="$CONFIG_DIR/quickshell/services/plugins/community"
  if [[ -d "$comm" && -n "$(ls -A "$comm" 2>/dev/null)" ]]; then
    printf "\n  Remove community plugins? ${DIM}[y/N]${NC}: "
    read -r _r
    [[ "$_r" =~ ^[Yy]$ ]] && { rm -rf "$comm"; _ok "Community plugins removed"; }
  fi

  local snap_f="$CACHE_DIR/snapshots.txt"
  if [[ -f "$snap_f" ]]; then
    local latest
    latest=$(tail -1 "$snap_f" 2>/dev/null || true)
    if [[ -n "$latest" && -d "$latest" ]]; then
      printf "\n  Snapshot found: ${DIM}%s${NC}\n" "$latest"
      printf "  Restore it? ${DIM}[y/N]${NC}: "
      read -r _r
      [[ "$_r" =~ ^[Yy]$ ]] && restore_snapshot "$latest"
    fi
  fi

  rm -f "$STATE_FILE" "$MANIFEST" 2>/dev/null || true
  rmdir "$CACHE_DIR" 2>/dev/null || true
  printf "\n  ${G}Uninstall complete.${NC}\n\n"
}

do_community() {
  local url="$1"
  [[ -z "$url" ]] && { _err "No URL provided"; exit 1; }

  ensure_cache

  local repo
  repo=$(basename "$url" .git)

  local dest="$PLUGIN_DEST/community/$repo"
  if [[ -d "$dest" ]]; then
    _info "Updating $repo"
    git -C "$dest" pull --ff-only >/dev/null 2>&1 || {
      rm -rf "$dest"
      git clone "$url" "$dest" >/dev/null 2>&1
    }
  else
    _info "Cloning $url"
    mkdir -p "$PLUGIN_DEST/community"
    git clone "$url" "$dest" >/dev/null 2>&1 || { _err "Clone failed"; exit 1; }
  fi

  local n=0
  for qml in "$dest"/*.qml; do
    [[ -f "$qml" ]] || continue
    local nm
    nm=$(basename "$qml" .qml)
    [[ "$nm" == "qmldir" ]] && continue
    record_path "$qml"
    (( n++ )) || true
  done

  (( n > 0 )) && _ok "$n plugin(s) installed from $repo" || _info "No .qml files found"
  "$REPO_DIR/dev/generate-qmldir.sh" >/dev/null 2>&1
  _ok "Plugin manifest updated — restart QuickShell to load"
}

prepare_install_mode() {
  if [[ -z "$INSTALL_MODE" ]]; then
    screen_welcome
  fi

  if [[ "$INSTALL_MODE" == "expert" && "$NONINTERACTIVE" != true ]]; then
    screen_expert
  fi

  if $RUN_PLUGINS; then
    if [[ "$INSTALL_MODE" == "express" ]]; then
      populate_express_plugins
    elif [[ "$NONINTERACTIVE" != true ]]; then
      screen_plugins
    fi
  fi

  # Optional application catalog — express installs all, expert picks.
  if [[ "$NONINTERACTIVE" != true ]]; then
    if [[ "$INSTALL_MODE" == "express" ]]; then
      RUN_APPS=true
      populate_express_apps
    elif [[ "$INSTALL_MODE" == "expert" ]]; then
      RUN_APPS=true
      screen_apps
    fi
  fi

  if [[ "$NONINTERACTIVE" != true ]]; then
    screen_confirm
  fi
}

case "$MODE" in
  welcome)
    prepare_install_mode
    do_install
    ;;
  install)
    prepare_install_mode
    do_install
    ;;
  uninstall)
    do_uninstall
    ;;
  community)
    do_community "$COMMUNITY_URL"
    ;;
  *)
    _err "Unsupported mode: $MODE"
    exit 1
    ;;
esac
