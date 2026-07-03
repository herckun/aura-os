#!/usr/bin/env bash
# ── SDDM Theme Sync ───────────────────────────────────────
# Writes accent, shellMode, wallpaper path, and theme.json parameters to the cache dir.
# Usage: update-sddm-theme.sh '<json_blob>'
# JSON keys: accent, shellMode, transparency, animations, monochrome, blur

set -euo pipefail

# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core/bash" && pwd)/bootstrap.sh"

SDDM_THEME_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/${APP_NAME}/sddm-theme.json"
SDDM_WP_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/${APP_NAME}/sddm-wallpaper.jpg"
_envCacheVar="${APP_ENV_PREFIX}_CACHE_DIR"
_cache="${!_envCacheVar:-${XDG_CACHE_HOME:-$HOME/.cache}/${APP_CACHE_KEY}}"
WP_CACHE_FILE="${_cache}/current-wallpaper"

# ── Copy current wallpaper to config dir for SDDM ───────────────────
wp_path=""
read -r wp_path < "$WP_CACHE_FILE" 2>/dev/null || true
if [[ -n "$wp_path" && -f "$wp_path" ]]; then
  cp -f "$wp_path" "$SDDM_WP_FILE" 2>/dev/null && \
    echo "[sddm-theme] Wallpaper copied to $SDDM_WP_FILE"
fi

DEFAULT_JSON='{}'
INPUT_JSON="${1:-$DEFAULT_JSON}"

# Derive full theme JSON payload using Python
python3 -c '
import json, os, sys

sys.path.insert(0, os.path.dirname(os.path.realpath(sys.argv[1])))
from theme_lib import find_theme_json, normalize_accent, style_key_for, clean_font

params, accent_clean = normalize_accent(sys.argv[2])
accent_normalized = "#" + accent_clean
shell_mode = int(params.get("shellMode", 0))
mono = str(params.get("monochrome", False)).lower() == "true"

# Read wallpaper path — prefer config dir copy (sddm can read it), fall back to original
wp_cache = sys.argv[4]
wp_config = sys.argv[5]
wallpaper = ""
if os.path.isfile(wp_config):
    wallpaper = wp_config
else:
    try:
        with open(wp_cache) as f:
            wallpaper = f.read().strip()
    except:
        pass

theme_data = find_theme_json()

colors = theme_data.get("colors", {})
typography = theme_data.get("typography", {})
styles = theme_data.get("styles", {})

style_conf = styles.get(style_key_for(shell_mode), styles.get("default", {}))
sizing = style_conf.get("sizing", {})
radius = style_conf.get("radius", {})

if mono:
    accent_final = colors.get("textPrimary", "#E8E8E8")
else:
    accent_final = accent_normalized

payload = {
    "accent": accent_final,
    "shellMode": shell_mode,
    "wallpaper": wallpaper,
    "background": colors.get("background", "#000000"),
    "backgroundSecondary": colors.get("backgroundSecondary", "#111111"),
    "border": colors.get("border", "#222222"),
    "textPrimary": colors.get("textPrimary", "#E8E8E8"),
    "textSecondary": colors.get("textSecondary", "#999999"),
    "fontFamily": clean_font(typography.get("fontFamily", "RedHatDisplay")),
    "controlHeight": sizing.get("controlHeight", 28),
    "radiusSmall": radius.get("sm", 4),
    "radiusMedium": radius.get("md", 8),
    "radiusUI": radius.get("ui", 12)
}

out = sys.argv[3]
with open(out, "w") as f:
    json.dump(payload, f)
' "$0" "$INPUT_JSON" "$SDDM_THEME_FILE" "$WP_CACHE_FILE" "$SDDM_WP_FILE"

chmod 644 "$SDDM_THEME_FILE" 2>/dev/null || true
echo "[sddm-theme] Wrote theme config to $SDDM_THEME_FILE"
