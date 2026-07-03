#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../core/bash" && pwd)/bootstrap.sh"

readonly REPO_DIR="$AURA_REPO_DIR"
readonly INSTALL="$REPO_DIR/install.sh"
readonly LOCKFILE="/tmp/${APP_NAME}-dev-watch.lock"
ONCE=false

[[ "${1:-}" == "--once" ]] && ONCE=true

reload_quickshell() {
  pkill -9 -x qs 2>/dev/null || true
  pkill -9 -x quickshell 2>/dev/null || true
  pkill -9 -f quickshell 2>/dev/null || true

  local i=0
  while pgrep -x qs >/dev/null 2>&1 || pgrep -x quickshell >/dev/null 2>&1; do
    sleep 0.2
    i=$((i + 1))
    (( i >= 10 )) && break
  done

  sleep 0.5
  nohup qs >/dev/null 2>&1 &
}

reload_hyprland() {
  hyprctl reload >/dev/null 2>&1 || true
}

do_install() {
  if [[ -f "$LOCKFILE" ]]; then
    local lock_pid
    lock_pid="$(cat "$LOCKFILE" 2>/dev/null || true)"
    if [[ -n "$lock_pid" ]] && kill -0 "$lock_pid" 2>/dev/null; then
      log_warn "Install already running (pid $lock_pid), skipping"
      return 0
    fi
  fi

  printf '%s\n' "$$" > "$LOCKFILE"
  trap 'rm -f "$LOCKFILE"' EXIT

  log_info "Running install"
  "$INSTALL" --quick 2>&1 | tail -10
  log_info "Reloading QuickShell and Hyprland"
  reload_quickshell
  sleep 1
  reload_hyprland
  log_ok "Dev deploy complete"

  rm -f "$LOCKFILE"
}

main() {
  if ! have_cmd inotifywait; then
    log_warn "inotifywait not found; attempting to install inotify-tools"
    sudo pacman -S --needed --noconfirm inotify-tools >/dev/null 2>&1 || {
      log_error "inotify-tools required. Install manually: sudo pacman -S inotify-tools"
      exit 2
    }
  fi

  if "$ONCE"; then
    do_install
    exit 0
  fi

  log_info "Watching $REPO_DIR for changes (Ctrl+C to stop)"
  while true; do
    inotifywait -r -q \
      --exclude '(\.git|\.qmlc|__pycache__|node_modules)' \
      -e modify,create,delete,move \
      "$REPO_DIR/config" \
      "$REPO_DIR/features" \
      "$REPO_DIR/dev" \
      "$REPO_DIR/core" \
      "$REPO_DIR/scripts" \
      >/dev/null 2>&1

    do_install
  done
}

main "$@"
