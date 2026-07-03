#!/usr/bin/env bash
# ── Kitty Theme Generator ─────────────────────────────────
# Generates kitty color theme from the accent color in ConfigStore.
# Usage: update-kitty-theme.sh '<json_blob>'
# JSON keys: accent, shellMode, transparency, animations, monochrome, blur

set -euo pipefail

# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core/bash" && pwd)/bootstrap.sh"

DEFAULT_JSON='{}'
INPUT_JSON="${1:-$DEFAULT_JSON}"

KITTY_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/kitty"
THEME_FILE="$KITTY_DIR/current-theme.conf"

# ── Read theme.json + extract params from JSON blob ─────────────────
# shellcheck disable=SC2046,SC2086 — eval of controlled Python output is intentional
eval "$(python3 -c '
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.realpath(sys.argv[1])))
from theme_lib import find_theme_json, normalize_accent, clean_font

params, raw_accent = normalize_accent(sys.argv[2])
mono = params.get("monochrome", False)
theme_data = find_theme_json()

colors = theme_data.get("colors", {})
typography = theme_data.get("typography", {})
sizes_presets = theme_data.get("sizes", {})

bg_hex = colors.get("background", "#000000")
fg = colors.get("textPrimary", "#E8E8E8")
dimmed_fg = colors.get("textSecondary", "#999999")
disabled_fg = colors.get("textDisabled", "#666666")
white = colors.get("textDisplay", "#FFFFFF")

font_mono = clean_font(typography.get("fontFamilyMono", "Space Mono"))
font_size = sizes_presets.get("md", {}).get("fontSize", 11)

if mono:
    accent_hex = fg.lstrip("#").upper()
else:
    accent_hex = raw_accent

accent_color = "#" + accent_hex

# Accent dimmed (40% opacity)
r, g, b = int(accent_hex[0:2], 16), int(accent_hex[2:4], 16), int(accent_hex[4:6], 16)
r, g, b = int(r * 0.4), int(g * 0.4), int(b * 0.4)
accent_dim = "#%02x%02x%02x" % (r, g, b)

print("BG_HEX=\"%s\"" % bg_hex)
print("FG=\"%s\"" % fg)
print("DIMMED_FG=\"%s\"" % dimmed_fg)
print("DISABLED_FG=\"%s\"" % disabled_fg)
print("WHITE=\"%s\"" % white)
print("FONT_MONO=\"%s\"" % font_mono)
print("FONT_SIZE=\"%s\"" % font_size)
print("ACCENT=\"%s\"" % accent_color)
print("ACCENT_DIM=\"%s\"" % accent_dim)
' "$0" "$INPUT_JSON")"

# ── Generate theme ──────────────────────────────────────────────────
mkdir -p "$KITTY_DIR"

cat > "$THEME_FILE" << EOF
# Terminal theme
# Generated from theme.json — do not edit manually

font_family      ${FONT_MONO}
font_size        ${FONT_SIZE}

cursor            ${FG}
cursor_text_color ${BG_HEX}

foreground            ${FG}
background            ${BG_HEX}
selection_foreground  ${BG_HEX}
selection_background  ${FG}

url_color             ${ACCENT_DIM}

# Normal — functional grays, accent for signal
color0   ${BG_HEX}
color1   ${ACCENT}
color2   ${FG}
color3   ${DIMMED_FG}
color4   ${DISABLED_FG}
color5   ${ACCENT_DIM}
color6   ${DIMMED_FG}
color7   ${FG}

color8   ${DISABLED_FG}
color9   ${ACCENT}
color10  ${WHITE}
color11  ${DIMMED_FG}
color12  ${DISABLED_FG}
color13  ${ACCENT_DIM}
color14  ${DIMMED_FG}
color15  ${WHITE}
EOF

echo "[kitty-theme] Generated theme with accent ${ACCENT}"

# ── Live reload: push colors to running Kitty instances ──────────────
if command -v kitty &>/dev/null && pgrep -x kitty &>/dev/null; then
  # Try remote control first (needs allow_remote_control yes in kitty.conf
  # and KITTY_SOCKET env var, which Kitty sets for child processes).
  if kitty @ set-colors --configured 2>/dev/null; then
    echo "[kitty-theme] Live reloaded colors via kitty @"
  else
    # Fallback: send SIGUSR1 to reload config from disk. This works
    # regardless of allow_remote_control, even from a non-TTY context.
    pkill -SIGUSR1 kitty 2>/dev/null || true
    echo "[kitty-theme] Reloaded colors via SIGUSR1 (fallback)"
  fi
fi
