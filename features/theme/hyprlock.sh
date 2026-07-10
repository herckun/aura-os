#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core/bash" && pwd)/bootstrap.sh"

DEFAULT_JSON='{}'
INPUT_JSON="${1:-$DEFAULT_JSON}"

HYPR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
THEME_FILE="$HYPR_DIR/hyprlock-theme.conf"

# shellcheck disable=SC2046,SC2086
eval "$(python3 -c '
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.realpath(sys.argv[1])))
from theme_lib import find_theme_json, normalize_accent, clean_font

params, raw_accent = normalize_accent(sys.argv[2])
mono = params.get("monochrome", False)
theme_data = find_theme_json()

colors = theme_data.get("colors", {})
typography = theme_data.get("typography", {})

def hexval(key, default):
    return colors.get(key, default).lstrip("#").upper()

fg = hexval("textPrimary", "#E8E8E8")
accent = fg if mono else raw_accent

print("BG=\"%s\"" % hexval("background", "#000000"))
print("SURFACE=\"%s\"" % hexval("backgroundSecondary", "#111111"))
print("BORDER=\"%s\"" % hexval("border", "#222222"))
print("BORDER_VISIBLE=\"%s\"" % hexval("borderVisible", "#333333"))
print("TEXT_DISPLAY=\"%s\"" % hexval("textDisplay", "#FFFFFF"))
print("TEXT_PRIMARY=\"%s\"" % fg)
print("TEXT_SECONDARY=\"%s\"" % hexval("textSecondary", "#999999"))
print("ACCENT=\"%s\"" % accent)
print("ERROR=\"%s\"" % hexval("error", "#D44A4A"))
print("FONT_DISPLAY=\"%s\"" % clean_font(typography.get("fontFamilyDisplay", "Geist")))
print("FONT_MONO=\"%s\"" % clean_font(typography.get("fontFamilyMono", "Space Mono")))
' "$0" "$INPUT_JSON")"

mkdir -p "$HYPR_DIR"

cat > "$THEME_FILE" << EOF
# @managed: hyprlock-theme
\$background = rgb(${BG})
\$surface = rgb(${SURFACE})
\$inputBg = rgba(${SURFACE}E6)
\$border = rgb(${BORDER})
\$borderVisible = rgb(${BORDER_VISIBLE})
\$textDisplay = rgb(${TEXT_DISPLAY})
\$textPrimary = rgb(${TEXT_PRIMARY})
\$textSecondary = rgb(${TEXT_SECONDARY})
\$accent = rgb(${ACCENT})
\$error = rgb(${ERROR})
\$fontDisplay = ${FONT_DISPLAY}
\$fontMono = ${FONT_MONO}
EOF

echo "[hyprlock-theme] Generated theme with accent #${ACCENT}"
