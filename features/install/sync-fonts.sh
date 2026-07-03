#!/usr/bin/env bash
# ── sync-fonts.sh — Download fonts from manifest.json ─────────────────
# Reads `deps.syncFonts` entries from `config/manifest.json` and downloads
# missing font files from the Google Fonts mirror into the local font dir.
#
# Usage:
#   ./features/install/sync-fonts.sh [--force] [--manifest /path/to/manifest.json]

set -euo pipefail
# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core/bash" && pwd)/bootstrap.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GOOGLE_FONTS_BASE="https://github.com/google/fonts/raw/main/ofl"
FONT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
CACHE_DIR="$AURA_CACHE_DIR"
FORCE=false
MANIFEST_JSON="$AURA_REPO_DIR/config/manifest.json"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      FORCE=true
      shift
      ;;
    --manifest)
      MANIFEST_JSON="$2"
      shift 2
      ;;
    --help|-h)
      cat <<EOF
Usage: $0 [--force] [--manifest /path/to/manifest.json]
  --force       Re-download even if font files already exist
  --manifest    Path to manifest.json (default: $AURA_REPO_DIR/config/manifest.json)
EOF
      exit 0
      ;;
    *)
      log_error "Unknown option: $1"
      exit 1
      ;;
  esac
done

MANIFEST_JSON="$(cd "$(dirname "$MANIFEST_JSON")" && pwd)/$(basename "$MANIFEST_JSON")"
require_file "$MANIFEST_JSON"

url_encode() {
  local value="$1"
  value="${value//\[/%5B}"
  value="${value//\]/%5D}"
  printf '%s' "$value"
}

list_sync_fonts() {
  python3 "$SCRIPT_DIR/manifest_lib.py" fonts "$MANIFEST_JSON"
}

download_font() {
  local ofl_dir="$1"
  local filename="$2"
  local fc_name="$3"
  local url_encoded url dest hash_stamp old_hash cur_hash tmp_file new_hash

  url_encoded="$(url_encode "$filename")"
  url="${GOOGLE_FONTS_BASE}/${ofl_dir}/${url_encoded}"
  dest="${FONT_DIR}/${filename}"
  hash_stamp="${CACHE_DIR}/font-hashes/${filename}.sha256"

  ensure_dir "$(dirname "$hash_stamp")"
  ensure_dir "$FONT_DIR"

  if [[ "$FORCE" != "true" && -n "$fc_name" ]] && have_cmd fc-list; then
    if fc-list | grep -Fqi "$fc_name"; then
      log_info "Font already present: ${filename} (${fc_name})"
      return 0
    fi
  fi

  if [[ -f "$dest" && -f "$hash_stamp" && "$FORCE" != "true" ]]; then
    old_hash="$(cat "$hash_stamp" 2>/dev/null || true)"
    cur_hash="$(sha256sum "$dest" 2>/dev/null | cut -d' ' -f1 || true)"
    if [[ "$old_hash" == "$cur_hash" ]]; then
      log_info "Font unchanged: ${filename}"
      return 0
    fi
  fi

  log_info "Downloading font: ${filename}"
  tmp_file="$(mktemp)"
  if curl -fsSL "$url" -o "$tmp_file"; then
    new_hash="$(sha256sum "$tmp_file" | cut -d' ' -f1)"
    mv "$tmp_file" "$dest"
    printf '%s\n' "$new_hash" > "$hash_stamp"
    log_ok "Installed font: ${filename}"
  else
    rm -f "$tmp_file"
    log_error "Failed to download font: ${filename}"
    return 1
  fi
}

log_info "Syncing fonts from $MANIFEST_JSON"
entries="$(list_sync_fonts)"
if [[ -z "$entries" ]]; then
  log_error "No deps.syncFonts entries found in manifest"
  exit 1
fi

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  ofl_dir="${line%%|*}"
  rest="${line#*|}"
  filename="${rest%%|*}"
  fc_name="${rest#*|}"
  [[ "$fc_name" == "$filename" ]] && fc_name=""
  download_font "$ofl_dir" "$filename" "$fc_name"
done < <(printf '%s\n' "$entries")

if have_cmd fc-cache; then
  log_info "Refreshing font cache"
  fc-cache -f "$FONT_DIR" >/dev/null 2>&1
  log_ok "Font cache refreshed"
fi
