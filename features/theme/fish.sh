#!/usr/bin/env bash
# ── Fish Theme Generator ──────────────────────────────────
# Generates fish color theme from theme.json and ConfigStore.
# Usage: update-fish-theme.sh '<json_blob>'
# JSON keys: accent, shellMode, transparency, animations, monochrome, blur

set -euo pipefail

# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core/bash" && pwd)/bootstrap.sh"

DEFAULT_JSON='{}'
INPUT_JSON="${1:-$DEFAULT_JSON}"

FISH_CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/fish/conf.d"
THEME_FILE="$FISH_CONF_DIR/${APP_NAME}-theme.fish"

# ── Read theme.json + extract params from JSON blob ─────────────────
# shellcheck disable=SC2046,SC2086 — eval of controlled Python output is intentional
eval "$(python3 -c '
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.realpath(sys.argv[1])))
from theme_lib import find_theme_json, normalize_accent

params, raw_accent = normalize_accent(sys.argv[2])
mono = params.get("monochrome", False)
theme_data = find_theme_json()

colors = theme_data.get("colors", {})

bg_hex = colors.get("background", "#000000")
surface_hex = colors.get("backgroundSecondary", "#111111")
border = colors.get("border", "#222222")
fg = colors.get("textPrimary", "#E8E8E8")
dimmed_fg = colors.get("textSecondary", "#999999")
disabled_fg = colors.get("textDisabled", "#666666")

if mono:
    accent_hex = fg.lstrip("#").upper()
else:
    accent_hex = raw_accent

accent_color = "#" + accent_hex

print("BG_HEX=\"%s\"" % bg_hex)
print("SURFACE_HEX=\"%s\"" % surface_hex)
print("BORDER=\"%s\"" % border)
print("FG=\"%s\"" % fg)
print("DIMMED_FG=\"%s\"" % dimmed_fg)
print("DISABLED_FG=\"%s\"" % disabled_fg)
print("ACCENT=\"%s\"" % accent_color)
print("MONOCHROME=\"%s\"" % ("true" if mono else "false"))
' "$0" "$INPUT_JSON")"

# Strip # for fish colors if needed (fish handles hex colors as plain RRGGBB)
ACCENT_FISH="${ACCENT#\#}"
BG_FISH="${BG_HEX#\#}"
SURFACE_FISH="${SURFACE_HEX#\#}"
FG_FISH="${FG#\#}"
DIMMED_FG_FISH="${DIMMED_FG#\#}"
DISABLED_FG_FISH="${DISABLED_FG#\#}"
BORDER_FISH="${BORDER#\#}"

# ── Generate theme ──────────────────────────────────────────────────
mkdir -p "$FISH_CONF_DIR"

cat > "$THEME_FILE" << EOF
# ${APP_DISPLAY} — Fish Theme
# Generated from theme.json — do not edit manually

set -gx ${APP_ENV_PREFIX}_ACCENT '${ACCENT_FISH}'
set -gx ${APP_ENV_PREFIX}_MONO '${MONOCHROME}'
set -gx AURA_THEME_ACCENT '${ACCENT_FISH}'
set -gx AURA_THEME_MONO '${MONOCHROME}'
set -gx ${APP_ENV_PREFIX}_BG '${BG_FISH}'
set -gx ${APP_ENV_PREFIX}_BG_SEC '${SURFACE_FISH}'
set -gx ${APP_ENV_PREFIX}_TEXT_PRI '${FG_FISH}'
set -gx ${APP_ENV_PREFIX}_TEXT_SEC '${DIMMED_FG_FISH}'
set -gx ${APP_ENV_PREFIX}_TEXT_MUTED '${DISABLED_FG_FISH}'
set -gx ${APP_ENV_PREFIX}_BORDER '${BORDER_FISH}'

set -g fish_color_normal '${FG_FISH}'
set -g fish_color_command '${FG_FISH}'
set -g fish_color_keyword '${ACCENT_FISH}'
set -g fish_color_quote '${DISABLED_FG_FISH}'
set -g fish_color_redirection '${DIMMED_FG_FISH}'
set -g fish_color_end '${DISABLED_FG_FISH}'
set -g fish_color_error '${ACCENT_FISH}'
set -g fish_color_param '${DIMMED_FG_FISH}'
set -g fish_color_comment '${DISABLED_FG_FISH}'
set -g fish_color_match '${BORDER_FISH}'
set -g fish_color_selection '${BG_FISH}' '${FG_FISH}'

set -g fish_pager_color_progress '${DISABLED_FG_FISH}'
set -g fish_pager_color_background '${BG_FISH}'
set -g fish_pager_color_prefix '${DISABLED_FG_FISH}'
set -g fish_pager_color_completion '${DIMMED_FG_FISH}'
set -g fish_pager_color_description '${DISABLED_FG_FISH}'
EOF

echo "[fish-theme] Generated theme config at $THEME_FILE"
