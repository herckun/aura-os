#!/usr/bin/env bash
# ── wleave Theme Sync ──────────────────────────────────
# Generates wleave style.css from accent + theme.json.
# Usage: update-wleave-theme.sh '<json_blob>'
# JSON keys: accent, shellMode, transparency, animations, monochrome, blur

set -euo pipefail

# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core/bash" && pwd)/bootstrap.sh"

DEFAULT_JSON='{}'
INPUT_JSON="${1:-$DEFAULT_JSON}"

LIVE_CSS="${XDG_CONFIG_HOME:-$HOME/.config}/wleave/style.css"

mkdir -p "$(dirname "$LIVE_CSS")"

# ── Read theme.json + extract params from JSON blob ─────────────────
# shellcheck disable=SC2046,SC2086 — eval of controlled Python output is intentional
eval "$(python3 -c '
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.realpath(sys.argv[1])))
from theme_lib import find_theme_json, normalize_accent, style_key_for, clean_font

params, raw_accent = normalize_accent(sys.argv[2])
accent_rgb = "%d,%d,%d" % (int(raw_accent[0:2], 16), int(raw_accent[2:4], 16), int(raw_accent[4:6], 16))

mode = int(params.get("shellMode", 0))
transparency = str(params.get("transparency", True)).lower() == "true"

if transparency:
    window_bg = "rgba(0, 0, 0, 0.15)"
else:
    window_bg = "#000000"

theme_data = find_theme_json()

colors = theme_data.get("colors", {})
typography = theme_data.get("typography", {})
styles = theme_data.get("styles", {})

style_conf = styles.get(style_key_for(mode), styles.get("default", {}))
r_conf = style_conf.get("radius", {})
s_conf = style_conf.get("spacing", {})
sizing = style_conf.get("sizing", {})

# ── Colors ─────────────────────────────────────────────────────────
btn_text = colors.get("textSecondary", "#999999")
btn_text_hover = colors.get("textPrimary", "#E8E8E8")
btn_text_active = colors.get("textDisplay", "#FFFFFF")

# ── Typography ─────────────────────────────────────────────────────
font_label = clean_font(typography.get("fontFamilyMono", "Space Mono"))

# ── Sizing (from theme.json per mode) ──────────────────────────────
scale = sizing.get("controlHeight", 28) / 28.0  # normalize around default=28
btn_w = int(52 * scale)
btn_h = int(60 * scale)
icon_size = int(22 * scale)
font_size = int(8 * scale)

radius = r_conf.get("lg", 12)
margin = max(1, int(s_conf.get("sm", 8) / 2))
pad_top = int(btn_h * 0.54)
pad_side = s_conf.get("xs", 4)
pad_bot = s_conf.get("xxs", 2)

print("ACCENT=\"%s\"" % raw_accent)
print("ACCENT_RGB=\"%s\"" % accent_rgb)
print("WINDOW_BG=\"%s\"" % window_bg)
print("BTN_TEXT=\"%s\"" % btn_text)
print("BTN_TEXT_HOVER=\"%s\"" % btn_text_hover)
print("BTN_TEXT_ACTIVE=\"%s\"" % btn_text_active)
print("FONT_LABEL=\"%s\"" % font_label)
print("BTN_W=%d" % btn_w)
print("BTN_H=%d" % btn_h)
print("ICON_SIZE=%d" % icon_size)
print("FONT_SIZE=%d" % font_size)
print("RADIUS=%d" % radius)
print("MARGIN=%d" % margin)
print("PAD_TOP=%d" % pad_top)
print("PAD_SIDE=%d" % pad_side)
print("PAD_BOT=%d" % pad_bot)
print("MODE=%d" % mode)
' "$0" "$INPUT_JSON")"

# ── Generate style.css (GTK4/libadwaita CSS) ───────────────────────
cat > "$LIVE_CSS" << EOF
/* ${APP_DISPLAY} — wleave theme (auto-generated) */

window {
    background-color: ${WINDOW_BG};
}

button {
    background-color: transparent;
    border: 1px solid transparent;
    color: ${BTN_TEXT};
    border-radius: ${RADIUS}px;
    font-family: "${FONT_LABEL}", monospace;
    font-size: ${FONT_SIZE}px;
    min-width: ${BTN_W}px;
    max-width: ${BTN_W}px;
    min-height: ${BTN_H}px;
    max-height: ${BTN_H}px;
    padding: ${PAD_TOP}px ${PAD_SIDE}px ${PAD_BOT}px;
    margin: ${MARGIN}px;
}

button label.action-name {
    font-size: ${FONT_SIZE}px;
    font-weight: 400;
}

button:hover {
    background-color: rgba(${ACCENT_RGB}, 0.08);
    border-color: rgba(${ACCENT_RGB}, 0.25);
    color: ${BTN_TEXT_HOVER};
}

button:active {
    background-color: rgba(${ACCENT_RGB}, 0.14);
    border-color: rgba(${ACCENT_RGB}, 0.45);
    color: ${BTN_TEXT_ACTIVE};
}

button:focus {
    background-color: rgba(${ACCENT_RGB}, 0.08);
    border-color: rgba(${ACCENT_RGB}, 0.25);
    color: ${BTN_TEXT_HOVER};
}
EOF

echo "[wleave-theme] Generated $LIVE_CSS — accent #${ACCENT}, mode ${MODE}"
