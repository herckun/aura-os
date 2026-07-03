#!/usr/bin/env bash
# ── Wallpaper Switcher ───────────────────────────────────────
# Usage: wallpaper.sh [--monochrome] [path|name]
#   wallpaper.sh                        # cycle to next wallpaper
#   wallpaper.sh --monochrome           # cycle with monochrome filter
#   wallpaper.sh /path/to/image.jpg     # set specific wallpaper
#   wallpaper.sh --monochrome /path/to/image.jpg  # set with monochrome filter

set -euo pipefail

# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core/bash" && pwd)/bootstrap.sh"

WALLPAPER_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/wallpapers"
_envCacheVar="${APP_ENV_PREFIX}_CACHE_DIR"
_cache="${!_envCacheVar:-${XDG_CACHE_HOME:-$HOME/.cache}/${APP_CACHE_KEY}}"
CACHE_FILE="${_cache}/current-wallpaper"
MONO_CACHE_DIR="${_cache}/mono-wallpapers"
ENGINE="${WALLPAPER_ENGINE:-awww}"  # awww | hyprpaper | swww | swaybg
MONOCHROME=false

# ── Parse flags ──────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --monochrome)
      MONOCHROME=true
      shift
      ;;
    *)
      break
      ;;
  esac
done

# ── Resolve wallpaper path ───────────────────────────────────────────
resolve_wallpaper() {
  local input="$1"

  # If it's a file that exists, use it directly
  if [[ -f "$input" ]]; then
    echo "$input"
    return
  fi

  # If it's a name, look in wallpapers dir
  if [[ -d "$WALLPAPER_DIR" ]]; then
    local found
    found=$(find "$WALLPAPER_DIR" -maxdepth 1 -iname "${input}*" -type f | head -1)
    if [[ -n "$found" ]]; then
      echo "$found"
      return
    fi
  fi

  # Fallback to first wallpaper in dir
  find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' \) | head -1
}

# ── Convert to monochrome ────────────────────────────────────────────
to_monochrome() {
  local src="$1"
  mkdir -p "$MONO_CACHE_DIR"

  local basename
  basename=$(basename "$src")
  local dst="${MONO_CACHE_DIR}/${basename}"

  if [[ -f "$dst" ]]; then
    echo "$dst"
    return
  fi

  # Check if already grayscale (MAE < 10)
  local mae
  mae=$(magick "$src" -colorspace Gray -compose difference -composite \
    -fx 'abs(128-p[0])*255' -format '%[fx:mean*255]' info: 2>/dev/null || echo "255")

  if (( $(echo "$mae < 10" | bc -l 2>/dev/null || echo 0) )); then
    cp "$src" "$dst"
  else
    # Convert: desaturate, slight contrast boost
    magick "$src" -colorspace Gray -modulate 100,0 -level 5%,95% -quality 92 "$dst"
  fi

  echo "$dst"
}

# ── Set wallpaper ────────────────────────────────────────────────────
set_wallpaper() {
  local display_path="$1"
  local original_path="${2:-$1}"

  mkdir -p "$(dirname "$CACHE_FILE")"

  # Set wallpaper visually first (fast path — user sees the change immediately)
  case "$ENGINE" in
    awww)
      if ! pgrep -x awww-daemon >/dev/null; then
        awww-daemon &
        sleep 0.5
      fi
      awww img "$display_path" --transition-fps 60 --transition-type grow --transition-step 90
      ;;
    hyprpaper)
      if ! pgrep -x hyprpaper >/dev/null; then
        hyprpaper &
        sleep 0.5
      fi
      hyprctl hyprpaper wallpaper ",$display_path"
      ;;
    swww)
      swww img "$display_path" --transition-fps 60 --transition-type grow --transition-duration 0.5
      ;;
    swaybg)
      pkill swaybg || true
      swaybg -i "$display_path" -m fill &
      ;;
    *)
      echo "Unknown wallpaper engine: $ENGINE" >&2
      exit 1
      ;;
  esac

  # Extract palette synchronously — must complete before we write current-wallpaper.
  # QML's _pollWallpaper() uses current-wallpaper as a "palette is ready" signal:
  # it reads both files in one shot, so they must be consistent.
  # shellcheck disable=SC2155 — single assignment in non-critical context
  local extract_script="$(cd "$(dirname "${BASH_SOURCE[0]}")/../theme" && pwd)/palette.sh"
  if [[ -x "$extract_script" ]]; then
    "$extract_script" "$original_path" &>/dev/null || true
  fi

  # Write current-wallpaper LAST — after palette is ready.
  # This guarantees that when QML reads this file, palette.json already
  # corresponds to the new wallpaper (not the previous one).
  echo "$original_path" > "$CACHE_FILE"
}

# ── Main ─────────────────────────────────────────────────────────────
ORIGINAL=""
if [[ $# -eq 0 ]]; then
  mapfile -t wallpapers < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' \) | sort)
  if [[ ${#wallpapers[@]} -eq 0 ]]; then
    echo "No wallpapers found in $WALLPAPER_DIR" >&2
    exit 1
  fi

  current=$(cat "$CACHE_FILE" 2>/dev/null || echo "")
  next="${wallpapers[0]}"
  for i in "${!wallpapers[@]}"; do
    if [[ "${wallpapers[$i]}" == "$current" ]] && [[ $i -lt $((${#wallpapers[@]} - 1)) ]]; then
      next="${wallpapers[$((i + 1))]}"
      break
    fi
  done

  ORIGINAL="$next"
  if $MONOCHROME; then
    next=$(to_monochrome "$next")
  fi
  set_wallpaper "$next" "$ORIGINAL"
else
  path=$(resolve_wallpaper "$1")
  if [[ -z "$path" ]]; then
    echo "Wallpaper not found: $1" >&2
    exit 1
  fi

  ORIGINAL="$path"
  if $MONOCHROME; then
    path=$(to_monochrome "$path")
  fi
  set_wallpaper "$path" "$ORIGINAL"
fi
