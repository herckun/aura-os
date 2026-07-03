#!/usr/bin/env bash
# ── Wallpaper Color Extractor ─────────────────────────────────
# Extracts dominant colors from a wallpaper for liquid glass theming.
# Usage: extract-palette.sh /path/to/wallpaper.jpg
# Output: JSON to stdout with hex colors

set -euo pipefail

# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core/bash" && pwd)/bootstrap.sh"

WALLPAPER="${1:-}"
_envCacheVar="${APP_ENV_PREFIX}_CACHE_DIR"
CACHE_DIR="${!_envCacheVar:-${XDG_CACHE_HOME:-$HOME/.cache}/${APP_CACHE_KEY}}"
CACHE_FILE="$CACHE_DIR/palette.json"

if [[ -z "$WALLPAPER" ]]; then
  # Use current wallpaper from cache
  WALLPAPER=$(cat "$CACHE_DIR/current-wallpaper" 2>/dev/null || echo "")
fi

if [[ -z "$WALLPAPER" ]] || [[ ! -f "$WALLPAPER" ]]; then
  echo '{"error":"no wallpaper","primary":"#ffffff","secondary":"#e8e8e8","tertiary":"#999999","accent":"#d71921","background":"#000000","surface":"#111111","error":"no wallpaper"}'
  exit 1
fi

# Uses kmeans-like color quantization to get 6 dominant colors
readarray -t colors < <(
  magick "$WALLPAPER" \
    -sample 100x100 \
    -colorspace Lab \
    -colors 6 \
    -depth 8 \
    -format '%c' \
    histogram:info: 2>/dev/null | \
    sort -rn | head -6 | \
    sed -n 's/.*#\([0-9A-Fa-f]\{6\}\).*/\1/p'
)

if [[ ${#colors[@]} -lt 3 ]]; then
  echo '{"primary":"#ffffff","secondary":"#e8e8e8","tertiary":"#999999","accent":"#d71921","background":"#000000","surface":"#111111"}'
  exit 0
fi

# Map extracted colors to roles:
# colors[0] = most dominant → primary accent
# colors[1] = secondary → accent light
# colors[2-3] = muted → surfaces
# Remaining = background tones

primary="#${colors[0]}"
secondary="#${colors[1]:-${colors[0]}}"
tertiary="#${colors[2]:-${colors[1]:-${colors[0]}}}"
accent="$primary"

# Calculate derived colors using Python for proper color manipulation
derive_colors() {
python3 -c "
import math, sys, json

def hex_to_rgb(h):
    return tuple(int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4))

def rgb_to_hex(r, g, b):
    return '#{:02x}{:02x}{:02x}'.format(
        max(0, min(255, round(r * 255))),
        max(0, min(255, round(g * 255))),
        max(0, min(255, round(b * 255)))
    )

def adjust_lightness(r, g, b, factor):
    # Convert to linear space, multiply lightness, convert back
    def to_linear(c):
        return c ** 2.2 if c > 0.04045 else c / 12.92
    def to_srgb(c):
        return 1.055 * (c ** (1/2.4)) - 0.055 if c > 0.0031308 else 12.92 * c

    rl, gl, bl = to_linear(r), to_linear(g), to_linear(b)
    rl *= factor; gl *= factor; bl *= factor
    return to_srgb(rl), to_srgb(gl), to_srgb(bl)

hex_colors = json.loads(sys.argv[1])
primary_hex = hex_colors['primary']
primary = hex_to_rgb(primary_hex[1:])

# Derive lighter/darker variants
light = adjust_lightness(*primary, 1.4)
dark = adjust_lightness(*primary, 0.6)
muted = adjust_lightness(*primary, 0.3)

# Background colors from dominant tones
bg_main = tuple(max(0, min(1, c * 0.07)) for c in primary)
bg_sec = tuple(max(0, min(1, c * 0.12)) for c in primary)

result = {
    'primary': primary_hex,
    'primaryLight': rgb_to_hex(*light),
    'primaryDark': rgb_to_hex(*dark),
    'primaryMuted': rgb_to_hex(*muted),
    'background': rgb_to_hex(*bg_main),
    'surface': rgb_to_hex(*bg_sec),
    'secondary': hex_colors['secondary'],
    'tertiary': hex_colors['tertiary'],
}

print(json.dumps(result))
" "$(printf '{"primary":"%s","secondary":"%s","tertiary":"%s"}' "$primary" "$secondary" "$tertiary")"
}

FINAL_JSON=$(derive_colors)
mkdir -p "$CACHE_DIR"
echo "$FINAL_JSON" > "$CACHE_FILE"

# Also output accent candidates (all extracted dominant colors)
# Pick the best accent: bright enough to contrast dark theme, saturated enough to pop
ACCENTS="[]"
if [[ ${#colors[@]} -ge 2 ]]; then
  ACCENTS=$(printf '%s\n' "${colors[@]}" | head -6 | python3 -c "
import sys, json, colorsys

def hex_to_rgb(h):
    return tuple(int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4))

def score_accent(hex_str):
    r, g, b = hex_to_rgb(hex_str[1:])
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    # Penalize near-black and near-white
    if l < 0.15 or l > 0.92:
        return -1
    # Prefer saturated, bright-mid colors
    # Brightness in 0.3-0.7 range with high saturation is ideal
    brightness_score = 1.0 - abs(l - 0.55) * 2
    saturation_score = s
    return brightness_score * 0.4 + saturation_score * 0.6

colors = []
for line in sys.stdin:
    c = line.strip()
    if c and len(c) == 6:
        colors.append('#' + c.upper())

if not colors:
    print(json.dumps([]))
else:
    scored = [(score_accent(c), c) for c in colors]
    scored.sort(key=lambda x: x[0], reverse=True)
    # Best accent first, then the rest
    result = [c for _, c in scored if _ > 0]
    if not result:
        result = [colors[0]]
    print(json.dumps(result))
")
fi
echo "$ACCENTS" > "$CACHE_DIR/wallpaper-accents.json"
echo "$FINAL_JSON"
