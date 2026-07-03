#!/usr/bin/env bash

if [[ -n "${AURA_BASH_COLORS_LOADED:-}" ]]; then
  return 0
fi
AURA_BASH_COLORS_LOADED=1

_aura_color_clamp() {
  local value="$1"
  (( value < 0 )) && value=0
  (( value > 255 )) && value=255
  printf '%s\n' "$value"
}

hex_to_rgb() {
  local hex="${1#\#}"
  is_hex_color "$hex" || return 1
  printf '%d %d %d\n' "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}

rgb_to_hex() {
  local r g b
  r="$(_aura_color_clamp "$1")"
  g="$(_aura_color_clamp "$2")"
  b="$(_aura_color_clamp "$3")"
  printf '#%02X%02X%02X\n' "$r" "$g" "$b"
}

lighten() {
  local hex amount r g b
  hex="$1"
  amount="${2:-20}"
  read -r r g b <<< "$(hex_to_rgb "$hex")"
  r=$(( r + (255 - r) * amount / 100 ))
  g=$(( g + (255 - g) * amount / 100 ))
  b=$(( b + (255 - b) * amount / 100 ))
  rgb_to_hex "$r" "$g" "$b"
}

darken() {
  local hex amount r g b
  hex="$1"
  amount="${2:-20}"
  read -r r g b <<< "$(hex_to_rgb "$hex")"
  r=$(( r * (100 - amount) / 100 ))
  g=$(( g * (100 - amount) / 100 ))
  b=$(( b * (100 - amount) / 100 ))
  rgb_to_hex "$r" "$g" "$b"
}

blend() {
  local hex1 hex2 ratio r1 g1 b1 r2 g2 b2 r g b
  hex1="$1"
  hex2="$2"
  ratio="${3:-50}"
  read -r r1 g1 b1 <<< "$(hex_to_rgb "$hex1")"
  read -r r2 g2 b2 <<< "$(hex_to_rgb "$hex2")"
  r=$(( r1 + (r2 - r1) * ratio / 100 ))
  g=$(( g1 + (g2 - g1) * ratio / 100 ))
  b=$(( b1 + (b2 - b1) * ratio / 100 ))
  rgb_to_hex "$r" "$g" "$b"
}

contrast_color() {
  local hex r g b luminance
  hex="$1"
  read -r r g b <<< "$(hex_to_rgb "$hex")"
  luminance=$(( (2126 * r + 7152 * g + 722 * b) / 10000 ))
  if (( luminance > 128 )); then
    printf '#000000\n'
  else
    printf '#FFFFFF\n'
  fi
}

# Note: _aura_color_clamp must remain defined as it is used by rgb_to_hex,
# lighten, darken, blend at call time (not just source time).
