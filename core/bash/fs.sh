#!/usr/bin/env bash

if [[ -n "${AURA_BASH_FS_LOADED:-}" ]]; then
  return 0
fi
AURA_BASH_FS_LOADED=1

ensure_dir() {
  mkdir -p "$1"
}

atomic_write() {
  local target content dir tmp
  target="$1"
  content="$2"
  dir="$(dirname "$target")"
  ensure_dir "$dir"
  tmp="$(mktemp "$dir/.tmp.XXXXXX")"
  printf '%s' "$content" > "$tmp"
  mv -f "$tmp" "$target"
}

write_if_changed() {
  local target content
  target="$1"
  content="$2"

  if [[ -f "$target" ]] && printf '%s' "$content" | cmp -s - "$target"; then
    return 0
  fi

  atomic_write "$target" "$content"
}

backup_file() {
  local file backup
  file="$1"
  [[ -f "$file" ]] || return 0
  backup="${file}.bak.$(date +%s)"
  cp -p "$file" "$backup"
  printf '%s\n' "$backup"
}
