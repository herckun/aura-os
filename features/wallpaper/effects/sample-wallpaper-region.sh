#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../core/bash" && pwd)/bootstrap.sh"

# ── Wallpaper Region Sampler (fast) ──────────────────────────
# Single magick: crop → resize to grid (averages) → parse hex pixels.
#
# Usage: sample-wallpaper-region.sh WALLPAPER SCREEN_W SCREEN_H X Y W H [ROWS COLS]
# Output: JSON matrix of hex colors

WALLPAPER="${1:?missing wallpaper path}"
SCREEN_W="${2:?missing screen width}"
SCREEN_H="${3:?missing screen height}"
X="${4:?missing x}"
Y="${5:?missing y}"
W="${6:?missing widget width}"
H="${7:?missing widget height}"
ROWS="${8:-1}"
COLS="${9:-1}"

[[ -f "$WALLPAPER" ]] || { echo '[["#000000"]]'; exit 0; }

DIMENSIONS=$(identify -format "%w %h" "$WALLPAPER" 2>/dev/null || echo "")
[[ -z "$DIMENSIONS" ]] && { echo '[["#000000"]]'; exit 0; }

IMG_W="${DIMENSIONS%% *}"
IMG_H="${DIMENSIONS##* }"

if (( SCREEN_W * IMG_H >= SCREEN_H * IMG_W )); then
  SCALED_W=$SCREEN_W; SCALED_H=$(( IMG_H * SCREEN_W / IMG_W ))
else
  SCALED_H=$SCREEN_H; SCALED_W=$(( IMG_W * SCREEN_H / IMG_H ))
fi

OFFSET_X=$(( (SCALED_W - SCREEN_W) / 2 ))
OFFSET_Y=$(( (SCALED_H - SCREEN_H) / 2 ))

IMG_X=$(( (X + OFFSET_X) * IMG_W / SCALED_W ))
IMG_Y=$(( (Y + OFFSET_Y) * IMG_H / SCALED_H ))
IMG_W_REGION=$(( W * IMG_W / SCALED_W ))
IMG_H_REGION=$(( H * IMG_H / SCALED_H ))

(( IMG_X < 0 )) && IMG_X=0; (( IMG_Y < 0 )) && IMG_Y=0
(( IMG_X + IMG_W_REGION > IMG_W )) && IMG_W_REGION=$((IMG_W - IMG_X))
(( IMG_Y + IMG_H_REGION > IMG_H )) && IMG_H_REGION=$((IMG_H - IMG_Y))
(( IMG_W_REGION <= 0 )) && IMG_W_REGION=1; (( IMG_H_REGION <= 0 )) && IMG_H_REGION=1

# One magick call: crop → resize to grid → dump pixel text
RAW=$(magick "$WALLPAPER" \
  -crop "${IMG_W_REGION}x${IMG_H_REGION}+${IMG_X}+${IMG_Y}" +repage \
  -resize "${COLS}x${ROWS}!" \
  txt:- 2>/dev/null | tail -n +2 || echo "")

[[ -z "$RAW" ]] && { echo '[["#000000"]]'; exit 0; }

# Extract #RRGGBB from each "X,Y: (R,G,B)  #RRGGBB" line
echo -n "["
ROW=0; COL=0
while IFS= read -r line; do
  HEX=$(echo "$line" | sed -n 's/.*\(#[0-9A-Fa-f]\{6\}\).*/\1/p' || echo "")
  [[ -z "$HEX" ]] && continue

  if (( COL == 0 )); then
    (( ROW > 0 )) && echo -n ","
    echo -n "["
  else
    echo -n ","
  fi
  echo -n "\"$HEX\""
  COL=$(( COL + 1 ))

  if (( COL >= COLS )); then
    echo -n "]"; COL=0; ROW=$(( ROW + 1 ))
  fi
done <<< "$RAW"

(( COL > 0 )) && echo -n "]"
echo "]"
