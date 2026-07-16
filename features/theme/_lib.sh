#!/usr/bin/env bash
# ── Shared color computation for GTK/Qt theme generators ─────
# Sources bootstrap, parses theme JSON, exports all color/style variables.
# Usage: source this file from gtk-qt.sh or any sub-generator.

set -euo pipefail

# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core/bash" && pwd)/bootstrap.sh"

# ── Normalize accent from JSON blob ──────────────────────────────────
# shellcheck disable=SC2046,SC2086 — eval of controlled Python output is intentional
eval "$(python3 -c '
import json, os, sys

# Resolve theme_lib from the calling script location
caller = os.environ.get("_GTKQT_CALLER", sys.argv[1])
sys.path.insert(0, os.path.dirname(os.path.realpath(caller)))
from theme_lib import find_theme_json, normalize_accent, style_key_for, clean_font

params, raw_accent = normalize_accent(sys.argv[2])
print("ACCENT_HEX=\"%s\"" % raw_accent)
print("ACCENT=\"#%s\"" % raw_accent)

style_mode = int(params.get("shellMode", 0))
trans = str(params.get("transparency", True)).lower() == "true"
blur_state = str(params.get("blur", True)).lower() == "true"

theme_data = find_theme_json()

colors = theme_data.get("colors", {})
typography = theme_data.get("typography", {})
styles = theme_data.get("styles", {})

style_conf = styles.get(style_key_for(style_mode), styles.get("default", {}))
radius = style_conf.get("radius", {})

bg = colors.get("background", "#000000").lstrip("#")
surface = colors.get("backgroundSecondary", "#111111").lstrip("#")
surface_alt = colors.get("backgroundTertiary", "#1A1A1A").lstrip("#")

def hex_to_rgb(h):
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)

bg_r, bg_g, bg_b = hex_to_rgb(bg)
sf_r, sf_g, sf_b = hex_to_rgb(surface)
sfa_r, sfa_g, sfa_b = hex_to_rgb(surface_alt)

sfl_r = (bg_r + sf_r) // 2
sfl_g = (bg_g + sf_g) // 2
sfl_b = (bg_b + sf_b) // 2
surface_low = f"{sfl_r:02x}{sfl_g:02x}{sfl_b:02x}"

# Surface hover — subtle lightening (1/8 blend toward FG)
fg_hex = colors.get("textPrimary", "#E8E8E8").lstrip("#")
fg_r, fg_g, fg_b = hex_to_rgb(fg_hex)
sh_r = min(255, sfa_r + (fg_r - sfa_r) // 8)
sh_g = min(255, sfa_g + (fg_g - sfa_g) // 8)
sh_b = min(255, sfa_b + (fg_b - sfa_b) // 8)
surface_hover = f"{sh_r:02x}{sh_g:02x}{sh_b:02x}"

# Muted foreground — midpoint between FG and DIMMED_FG
dim_hex = colors.get("textSecondary", "#999999").lstrip("#")
dim_r, dim_g, dim_b = hex_to_rgb(dim_hex)
mf_r = (fg_r + dim_r) // 2
mf_g = (fg_g + dim_g) // 2
mf_b = (fg_b + dim_b) // 2
muted_fg = f"#{mf_r:02x}{mf_g:02x}{mf_b:02x}"

print("BG_HEX=\"#%s\"" % bg)
print("BG_R=%d; BG_G=%d; BG_B=%d" % (bg_r, bg_g, bg_b))
print("SURFACE_HEX=\"#%s\"" % surface)
print("SURFACE_R=%d; SURFACE_G=%d; SURFACE_B=%d" % (sf_r, sf_g, sf_b))
print("SURFACE_ALT_HEX=\"#%s\"" % surface_alt)
print("SURFACE_ALT_R=%d; SURFACE_ALT_G=%d; SURFACE_ALT_B=%d" % (sfa_r, sfa_g, sfa_b))
print("SURFACE_LOW_HEX=\"#%s\"" % surface_low)
print("SURFACE_LOW_R=%d; SURFACE_LOW_G=%d; SURFACE_LOW_B=%d" % (sfl_r, sfl_g, sfl_b))
print("SURFACE_HOVER_HEX=\"#%s\"" % surface_hover)
print("SURFACE_HOVER_R=%d; SURFACE_HOVER_G=%d; SURFACE_HOVER_B=%d" % (sh_r, sh_g, sh_b))

print("FG=\"%s\"" % colors.get("textPrimary", "#E8E8E8"))
print("FG_HEX_NOHASH=\"%s\"" % fg_hex)
print("DIMMED_FG=\"%s\"" % colors.get("textSecondary", "#999999"))
print("DIMMED_FG_R=%d; DIMMED_FG_G=%d; DIMMED_FG_B=%d" % (dim_r, dim_g, dim_b))
print("MUTED_FG=\"%s\"" % muted_fg)
print("BORDER=\"%s\"" % colors.get("border", "#222222"))
print("BORDER_SUBTLE=\"%s\"" % colors.get("borderVisible", "#333333"))
print("WHITE=\"%s\"" % colors.get("textDisplay", "#FFFFFF"))

print("FONT_SANS=\"%s\"" % clean_font(typography.get("fontFamily", "Space Grotesk")))
print("FONT_MONO=\"%s\"" % clean_font(typography.get("fontFamilyMono", "Space Mono")))

print("RADIUS_SM=%d" % radius.get("sm", 4))
print("RADIUS_MD=%d" % radius.get("md", 8))
print("RADIUS_UI=%d" % radius.get("ui", 12))
print("RADIUS_XS=%d" % radius.get("xs", 2))

sizing = style_conf.get("sizing", {})
spacing = style_conf.get("spacing", {})

print("CTRL_HEIGHT=%d" % sizing.get("controlHeight", 28))
print("CTRL_HEIGHT_SM=%d" % sizing.get("controlHeightSmall", 24))
print("CTRL_PADDING=%d" % sizing.get("controlPadding", 8))
print("CTRL_SPACING=%d" % sizing.get("controlSpacing", 6))
print("BAR_HEIGHT=%d" % sizing.get("barHeight", 36))
print("CARD_PADDING=%d" % sizing.get("cardPadding", 16))

print("SPACING_XS=%d" % spacing.get("xs", 4))
print("SPACING_SM=%d" % spacing.get("sm", 8))
print("SPACING_MD=%d" % spacing.get("md", 16))

print("TRANSPARENCY=\"%s\"" % ("true" if trans else "false"))
print("BLUR=\"%s\"" % ("true" if blur_state else "false"))
' "${_GTKQT_CALLER:-$0}" "$INPUT_JSON")"

ADW_GTK4_DIR="/usr/share/themes/adw-gtk3-dark/gtk-4.0"

# ── Resolve to CSS values ─────────────────────────────────────────────
# Transparency model (layered with Hyprland active_opacity=0.95):
#   Headerbar: SOLID hex → only Hyprland's 0.95 affects → ~95% effective (nearly solid)
#   Content:   rgba(0.92) × 0.95 → ~87% effective (subtle blur)
#   Surface:   rgba(0.92) × 0.95 → ~87% effective (cards, elevated)
#
# Key insight from Colloid/adw-gtk3: headerbars use SOLID colors.
# Translucency comes from the compositor, NOT from CSS alpha.
# Double-alpha (CSS + compositor) makes things look washed out.
if [[ "$TRANSPARENCY" == "true" ]]; then
  # Content area — moderate alpha for blur effect through compositor
  BG="rgba($BG_R,$BG_G,$BG_B,0.92)"
  SURFACE="rgba($SURFACE_R,$SURFACE_G,$SURFACE_B,0.92)"
  SURFACE_ALT="rgba($SURFACE_ALT_R,$SURFACE_ALT_G,$SURFACE_ALT_B,0.92)"
  SURFACE_LOW="rgba($SURFACE_LOW_R,$SURFACE_LOW_G,$SURFACE_LOW_B,0.92)"
  SURFACE_HOVER="rgba($SURFACE_HOVER_R,$SURFACE_HOVER_G,$SURFACE_HOVER_B,0.92)"
  # Headerbar: SOLID hex — no CSS alpha. Compositor's 0.95 gives subtle translucency.
  # This matches how adw-gtk3-dark and Colloid define headerbar_bg_color.
  BG_HEADERBAR="${BG_HEX}"
else
  BG="${BG_HEX}"
  SURFACE="${SURFACE_HEX}"
  SURFACE_ALT="${SURFACE_ALT_HEX}"
  SURFACE_LOW="${SURFACE_LOW_HEX}"
  SURFACE_HOVER="${SURFACE_HOVER_HEX}"
  BG_HEADERBAR="${BG_HEX}"
fi

# ── Accent variants ─────────────────────────────────────────────
ACCENT_BG=$(python3 -c "
h = '$ACCENT_HEX'; r = int(h[0:2],16)//3; g = int(h[2:4],16)//3; b = int(h[4:6],16)//3
print(f'#{r:02x}{g:02x}{b:02x}')
")
ACCENT_HOVER=$(python3 -c "
h = '$ACCENT_HEX'; r = min(255,int(h[0:2],16)*5//4); g = min(255,int(h[2:4],16)*5//4); b = min(255,int(h[4:6],16)*5//4)
print(f'#{r:02x}{g:02x}{b:02x}')
")

FG_HEX_NO_HASH="${FG#\#}"
FG_R=$((16#${FG_HEX_NO_HASH:0:2}))
FG_G=$((16#${FG_HEX_NO_HASH:2:2}))
FG_B=$((16#${FG_HEX_NO_HASH:4:2}))

# FG with various opacities for Kvantum text states
FG_OPAQUE="rgba(${FG_R},${FG_G},${FG_B},1.0)"
FG_92="rgba(${FG_R},${FG_G},${FG_B},0.92)"
FG_78="rgba(${FG_R},${FG_G},${FG_B},0.78)"
FG_71="rgba(${FG_R},${FG_G},${FG_B},0.71)"
FG_55="rgba(${FG_R},${FG_G},${FG_B},0.55)"
FG_49="rgba(${FG_R},${FG_G},${FG_B},0.49)"
FG_43="rgba(${FG_R},${FG_G},${FG_B},0.43)"

ACCENT_R=$((16#${ACCENT_HEX:0:2}))
ACCENT_G=$((16#${ACCENT_HEX:2:2}))
ACCENT_B=$((16#${ACCENT_HEX:4:2}))
ACCENT_BG_R=$(( ACCENT_R / 3 ))
ACCENT_BG_G=$(( ACCENT_G / 3 ))
ACCENT_BG_B=$(( ACCENT_B / 3 ))

# Parse ACCENT_HOVER for KDE visited link color
AH_HEX="${ACCENT_HOVER#\#}"
AH_R=$((16#${AH_HEX:0:2}))
AH_G=$((16#${AH_HEX:2:2}))
AH_B=$((16#${AH_HEX:4:2}))

echo "[gtk-qt-theme] BG=${BG} FG=${FG} ACCENT=${ACCENT}"

THEME_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/themes/${APP_THEME_KEY}"
