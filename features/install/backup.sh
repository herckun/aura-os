#!/usr/bin/env bash

if [[ -n "${AURA_INSTALL_BACKUP_LOADED:-}" ]]; then
  return 0
fi
AURA_INSTALL_BACKUP_LOADED=1

timestamp() { date +%Y%m%d-%H%M%S; }

ensure_cache() {
  mkdir -p "$CACHE_DIR" "$BACKUP_DIR"
  chmod 755 "$CACHE_DIR"
  chmod 644 "$CACHE_DIR/config.json" 2>/dev/null || true
}

record_path() {
  grep -Fxq "$1" "$MANIFEST" 2>/dev/null || echo "$1" >> "$MANIFEST"
}

copy_config() {
  local src="$1" dest="$2"
  [[ -e "$dest" && ! -L "$dest" ]] && cmp -s "$src" "$dest" 2>/dev/null && return 0
  [[ -L "$dest" ]] && rm "$dest"
  [[ -e "$dest" ]] && rm -rf "$dest"
  mkdir -p "$(dirname "$dest")"
  if [[ -d "$src" ]]; then
    local tmpdir
    tmpdir="$(mktemp -d "$(dirname "$dest")/.aura_tmp_XXXXXX")"
    cp -a "$src/." "$tmpdir/"
    mv "$tmpdir" "$dest"
  else
    local tmpfile
    tmpfile="$(mktemp "$(dirname "$dest")/.aura_tmp_XXXXXX")"
    cp -a "$src" "$tmpfile"
    mv "$tmpfile" "$dest"
  fi
  record_path "$dest"
}

link_config() {
  local src="$1" dest="$2"
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    record_path "$dest"
    return 0
  fi
  [[ -L "$dest" || -e "$dest" ]] && rm -rf "$dest"
  mkdir -p "$(dirname "$dest")"
  ln -sf "$src" "$dest"
  record_path "$dest"
}

snapshot_configs() {
  $NO_BACKUP && { log_info "Backup skipped"; return; }
  local snap count=0
  snap="${BACKUP_DIR}/pre-$(timestamp)"
  for dir in "${MANAGED_DIRS[@]}"; do
    local src="$CONFIG_DIR/$dir"
    [[ -e "$src" && ! -L "$src" ]] || continue
    mkdir -p "$snap/config"
    cp -r "$src" "$snap/config/"
    log_info "Snapshot: ~/.config/$dir"
    (( count++ )) || true
  done
  local sddm_src="/usr/share/sddm/themes/${APP_NAME}"
  if [[ -d "$sddm_src" ]]; then
    sudo -n mkdir -p "$snap/system" 2>/dev/null || true
    sudo -n cp -r "$sddm_src" "$snap/system/sddm-theme" 2>/dev/null || true
    [[ -d "$snap/system/sddm-theme" ]] && { log_info "Snapshot: sddm theme"; (( count++ )) || true; }
  fi
  if (( count > 0 )); then
    echo "$snap" >> "$CACHE_DIR/snapshots.txt"
    BACKUP_SNAPSHOT="$snap"
    log_ok "Snapshot saved ($count dirs)"
  else
    log_info "Nothing to snapshot"
  fi
}

restore_snapshot() {
  local snap="$1"
  local conf="$snap/config"
  [[ -d "$conf" ]] && for d in "$conf"/*/; do
    [[ -d "$d" ]] || continue
    local n
    n="$(basename "$d")"
    rm -rf "$CONFIG_DIR/$n" 2>/dev/null || true
    cp -r "$d" "$CONFIG_DIR/$n"
    _ok "Restored ~/.config/$n"
  done
  local sddm_snap="$snap/system/sddm-theme"
  if [[ -d "$sddm_snap" ]]; then
    local t="/usr/share/sddm/themes/${APP_NAME}"
    sudo -n rm -rf "$t" 2>/dev/null && sudo -n cp -r "$sddm_snap" "$t" 2>/dev/null \
      && _ok "SDDM restored" || printf "  %sSDDM restore skipped (sudo unavailable)%s\n" "${DIM}" "${NC}"
  fi
}
