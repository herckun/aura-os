#!/usr/bin/env bash
# ── sync-icons.sh — Download Tabler SVG icons from manifest.json ──────
# Reads icons.map from config/manifest.json. Plugin icon fields are
# resolved through core/Icons.qml's logical map so that any plugin icon
# not already covered by the main list is merged into the download set.
#
# Usage:
#   features/install/sync-icons.sh --dir /path/to/icons [--force]

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

ICON_DIR=""
FORCE=false
MANIFEST_JSON="${AURA_REPO_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}/config/manifest.json"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir) ICON_DIR="$2"; shift 2 ;;
    --force) FORCE=true; shift ;;
    --manifest) MANIFEST_JSON="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: $0 --dir <icon-directory> [--force] [--manifest <path>]"
      exit 0 ;;
    *) log_error "Unknown option: $1"; exit 1 ;;
  esac
done

if [[ -z "$ICON_DIR" ]]; then
  log_error "Missing required --dir argument"
  exit 1
fi

if [[ ! -f "$MANIFEST_JSON" ]]; then
  log_error "Manifest not found: $MANIFEST_JSON"
  exit 1
fi

ensure_dir "$ICON_DIR"

# Extract icon map and plugin icons, merge them, output "local=tabler" lines
ICON_LIST=$(python3 "$SCRIPT_DIR/manifest_lib.py" icons "$MANIFEST_JSON")

CDN=$(python3 "$SCRIPT_DIR/manifest_lib.py" cdn "$MANIFEST_JSON")

log_info "Syncing Tabler icons from manifest"

errors=0
synced=0
skipped=0

while IFS='=' read -r local_name tabler_name; do
  [[ -z "$local_name" || -z "$tabler_name" ]] && continue
  dest="$ICON_DIR/${local_name}.svg"

  if [[ "$FORCE" != "true" && -f "$dest" && -s "$dest" ]]; then
    (( skipped++ )) || true
    continue
  fi

  tmp_file="$(mktemp)"
  if curl -fsSL "${CDN}/${tabler_name}.svg" -o "$tmp_file" 2>/dev/null; then
    mv "$tmp_file" "$dest"
    (( synced++ )) || true
  else
    rm -f "$tmp_file"
    log_warn "Failed to download: ${tabler_name} (for ${local_name})"
    (( errors++ )) || true
  fi
done <<< "$ICON_LIST"

if (( errors > 0 )); then
  log_warn "Icon sync: ${synced} downloaded, ${skipped} up-to-date, ${errors} failed"
  exit 1
else
  log_ok "Icons synced: ${synced} downloaded, ${skipped} up-to-date"
fi
