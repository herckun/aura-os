#!/usr/bin/env bash
# ── sync-sfx.sh — Download sound effects from manifest.json ──────────
#
# Usage:
#   features/install/sync-sfx.sh --dir /path/to/sfx [--force]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/../../core/bash/bootstrap.sh" ]]; then
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/../../core/bash/bootstrap.sh"
else
  log_info()  { printf '[INFO] %s\n' "$*"; }
  log_ok()    { printf '[OK]   %s\n' "$*"; }
  log_warn()  { printf '[WARN] %s\n' "$*"; }
  log_error() { printf '[ERR]  %s\n' "$*"; }
  ensure_dir() { mkdir -p "$1"; }
fi

SFX_DIR=""
FORCE=false
MANIFEST_JSON="${AURA_REPO_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}/config/manifest.json"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir) SFX_DIR="$2"; shift 2 ;;
    --force) FORCE=true; shift ;;
    --manifest) MANIFEST_JSON="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: $0 --dir <sfx-directory> [--force] [--manifest <path>]"
      exit 0 ;;
    *) log_error "Unknown option: $1"; exit 1 ;;
  esac
done

if [[ -z "$SFX_DIR" ]]; then
  log_error "Missing required --dir argument"
  exit 1
fi

if [[ ! -f "$MANIFEST_JSON" ]]; then
  log_error "Manifest not found: $MANIFEST_JSON"
  exit 1
fi

ensure_dir "$SFX_DIR"

SFX_LIST=$(python3 "$SCRIPT_DIR/manifest_lib.py" sfx "$MANIFEST_JSON")

CDN=$(python3 "$SCRIPT_DIR/manifest_lib.py" sfxcdn "$MANIFEST_JSON")

if [[ -z "$CDN" || -z "$SFX_LIST" ]]; then
  log_warn "No sfx configured in manifest"
  exit 0
fi

log_info "Syncing sound effects from manifest"

errors=0
synced=0
skipped=0

while IFS='=' read -r local_name remote_name; do
  [[ -z "$local_name" || -z "$remote_name" ]] && continue
  dest="$SFX_DIR/${local_name}.oga"

  if [[ "$FORCE" != "true" && -f "$dest" && -s "$dest" ]]; then
    (( skipped++ )) || true
    continue
  fi

  tmp_file="$(mktemp)"
  if curl -fsSL "${CDN}/${remote_name}" -o "$tmp_file" 2>/dev/null; then
    link_target="$(head -c 128 "$tmp_file" | grep -oExm1 '[A-Za-z0-9._-]+\.(oga|ogg|wav)' || true)"
    if [[ -n "$link_target" && "$(head -c 4 "$tmp_file")" != "OggS" && "$(head -c 4 "$tmp_file")" != "RIFF" ]]; then
      if ! curl -fsSL "${CDN}/${link_target}" -o "$tmp_file" 2>/dev/null; then
        rm -f "$tmp_file"
        log_warn "Failed to download: ${remote_name} -> ${link_target} (for ${local_name})"
        (( errors++ )) || true
        continue
      fi
    fi
    mv "$tmp_file" "$dest"
    (( synced++ )) || true
  else
    rm -f "$tmp_file"
    log_warn "Failed to download: ${remote_name} (for ${local_name})"
    (( errors++ )) || true
  fi
done <<< "$SFX_LIST"

if (( errors > 0 )); then
  log_warn "Sfx sync: ${synced} downloaded, ${skipped} up-to-date, ${errors} failed"
  exit 1
else
  log_ok "Sfx synced: ${synced} downloaded, ${skipped} up-to-date"
fi
