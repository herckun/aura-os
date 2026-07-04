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
  WALLPAPER=$(cat "$CACHE_DIR/current-wallpaper" 2>/dev/null || echo "")
fi

if [[ -z "$WALLPAPER" ]] || [[ ! -f "$WALLPAPER" ]]; then
  echo '{"error":"no wallpaper","primary":"#ffffff","secondary":"#e8e8e8","tertiary":"#999999","accent":"#d71921","background":"#000000","surface":"#111111"}'
  exit 1
fi

readarray -t colors < <(
  magick "$WALLPAPER" \
    -sample 100x100 \
    -colorspace Lab \
    -colors 10 \
    -colorspace sRGB \
    -depth 8 \
    -format '%c' \
    histogram:info: 2>/dev/null | \
    sort -rn | head -10 | \
    sed -n 's/^ *\([0-9]\+\).*#\([0-9A-Fa-f]\{6\}\).*/\1 \2/p'
)

if [[ ${#colors[@]} -lt 3 ]]; then
  echo '{"primary":"#ffffff","secondary":"#e8e8e8","tertiary":"#999999","accent":"#d71921","background":"#000000","surface":"#111111"}'
  exit 0
fi

mkdir -p "$CACHE_DIR"

FINAL_JSON=$(printf '%s\n' "${colors[@]}" | PALETTE_CACHE_DIR="$CACHE_DIR" python3 -c "
import sys, json, colorsys, os

DARK_BG = (0x0a / 255.0, 0x0a / 255.0, 0x0a / 255.0)
MIN_CONTRAST = 4.0
L_BAND = (0.55, 0.70)

def hex_to_rgb(h):
    return tuple(int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4))

def rgb_to_hex(r, g, b):
    return '#{:02x}{:02x}{:02x}'.format(
        *(max(0, min(255, round(c * 255))) for c in (r, g, b)))

def rel_luminance(rgb):
    def lin(c):
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (lin(c) for c in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b

def contrast(a, b):
    la, lb = rel_luminance(a), rel_luminance(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)

def chroma(rgb):
    return max(rgb) - min(rgb)

def normalize_for_dark(rgb):
    h, l, s = colorsys.rgb_to_hls(*rgb)
    if s > 0.05:
        s = max(s, min(0.85, s * 1.4 + 0.15))
    l = max(L_BAND[0], min(L_BAND[1], l))
    out = colorsys.hls_to_rgb(h, l, s)
    while contrast(out, DARK_BG) < MIN_CONTRAST and l < 0.9:
        l += 0.03
        out = colorsys.hls_to_rgb(h, l, s)
    return out

def hue_dist(a, b):
    ha = colorsys.rgb_to_hls(*a)[0] * 360.0
    hb = colorsys.rgb_to_hls(*b)[0] * 360.0
    d = abs(ha - hb)
    return min(d, 360.0 - d)

entries = []
for line in sys.stdin:
    parts = line.split()
    if len(parts) != 2:
        continue
    entries.append((int(parts[0]), hex_to_rgb(parts[1])))

if not entries:
    sys.exit(1)

total = sum(c for c, _ in entries) or 1

def score(count, rgb):
    _, l, _ = colorsys.rgb_to_hls(*rgb)
    if l < 0.08 or l > 0.95:
        return -1.0
    c = chroma(rgb)
    if c < 0.08:
        return -0.5
    dominance = count / total
    mid = max(0.0, 1.0 - abs(l - 0.5) * 1.5)
    return c * 0.55 + dominance * 0.25 + mid * 0.20

scored = sorted(((score(c, rgb), c, rgb) for c, rgb in entries), key=lambda e: e[0], reverse=True)

dominant = entries[0][1]
best = scored[0][2] if scored[0][0] > 0 else dominant
accent = normalize_for_dark(best)

accents = []
for s, _, rgb in scored:
    if s <= 0:
        continue
    cand = normalize_for_dark(rgb)
    if any(hue_dist(cand, a) < 20 for a in accents):
        continue
    accents.append(cand)
    if len(accents) >= 6:
        break
if not accents:
    accents = [accent]
while len(accents) < 3:
    h, l, s = colorsys.rgb_to_hls(*accents[0])
    n = len(accents)
    variant = colorsys.hls_to_rgb(h, min(0.85, l + 0.11 * n), max(0.15, s - 0.25 * (n - 1)))
    if any(rgb_to_hex(*variant) == rgb_to_hex(*a) for a in accents):
        break
    accents.append(variant)

def scale_linear(rgb, factor):
    def lin(c):
        return c ** 2.2 if c > 0.04045 else c / 12.92
    def srgb(c):
        return 1.055 * (c ** (1 / 2.4)) - 0.055 if c > 0.0031308 else 12.92 * c
    return tuple(srgb(max(0.0, min(1.0, lin(c) * factor))) for c in rgb)

raw = [rgb for _, rgb in entries]
result = {
    'primary': rgb_to_hex(*accent),
    'primaryLight': rgb_to_hex(*scale_linear(accent, 1.4)),
    'primaryDark': rgb_to_hex(*scale_linear(accent, 0.6)),
    'primaryMuted': rgb_to_hex(*scale_linear(accent, 0.3)),
    'background': rgb_to_hex(*(c * 0.07 for c in dominant)),
    'surface': rgb_to_hex(*(c * 0.12 for c in dominant)),
    'secondary': rgb_to_hex(*raw[1]) if len(raw) > 1 else rgb_to_hex(*dominant),
    'tertiary': rgb_to_hex(*raw[2]) if len(raw) > 2 else rgb_to_hex(*dominant),
}

with open(os.path.join(os.environ['PALETTE_CACHE_DIR'], 'wallpaper-accents.json'), 'w') as f:
    json.dump([rgb_to_hex(*a).upper() for a in accents], f)

print(json.dumps(result))
" 2>/dev/null) || {
  echo '{"primary":"#ffffff","secondary":"#e8e8e8","tertiary":"#999999","accent":"#d71921","background":"#000000","surface":"#111111"}'
  exit 0
}

echo "$FINAL_JSON" > "$CACHE_FILE"
echo "$FINAL_JSON"
