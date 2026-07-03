#!/usr/bin/env bash

if [[ -n "${AURA_BASH_JSON_LOADED:-}" ]]; then
  return 0
fi
AURA_BASH_JSON_LOADED=1

require_jq() {
  require_cmd jq
}

json_get() {
  local file filter default_value output
  file="$1"
  filter="$2"
  default_value="${3:-}"
  require_jq || return 1

  if [[ ! -f "$file" ]]; then
    printf '%s\n' "$default_value"
    return 0
  fi

  output="$(jq -er "$filter" "$file" 2>/dev/null)" || true
  if [[ -n "$output" && "$output" != "null" ]]; then
    printf '%s\n' "$output"
  else
    printf '%s\n' "$default_value"
  fi
}

json_get_raw() {
  local file filter default_value output
  file="$1"
  filter="$2"
  default_value="${3:-null}"
  require_jq || return 1

  if [[ ! -f "$file" ]]; then
    printf '%s\n' "$default_value"
    return 0
  fi

  output="$(jq -ec "$filter" "$file" 2>/dev/null)" || true
  if [[ -n "$output" ]]; then
    printf '%s\n' "$output"
  else
    printf '%s\n' "$default_value"
  fi
}

json_set_string() {
  local file filter value tmp source
  file="$1"
  filter="$2"
  value="$3"
  require_jq || return 1

  ensure_dir "$(dirname "$file")"
  tmp="$(mktemp "$(dirname "$file")/.json.XXXXXX")"
  source='{}'
  [[ -f "$file" ]] && source="$(cat "$file")"
  printf '%s' "$source" | jq --arg value "$value" "$filter = \$value" > "$tmp"
  mv -f "$tmp" "$file"
}

json_set_json() {
  local file filter value tmp source
  file="$1"
  filter="$2"
  value="$3"
  require_jq || return 1

  ensure_dir "$(dirname "$file")"
  tmp="$(mktemp "$(dirname "$file")/.json.XXXXXX")"
  source='{}'
  [[ -f "$file" ]] && source="$(cat "$file")"
  printf '%s' "$source" | jq --argjson value "$value" "$filter = \$value" > "$tmp"
  mv -f "$tmp" "$file"
}
