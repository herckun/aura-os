#!/usr/bin/env bash

if [[ -n "${AURA_INSTALL_PLUGINS_LOADED:-}" ]]; then
  return 0
fi
AURA_INSTALL_PLUGINS_LOADED=1

PLUGIN_DEST="$CONFIG_DIR/quickshell/services/plugins"
selected_extra_defs=()
declare -g -A extra_dep_map=()

_check_plugin() {
  local file="$1" cat="$2" id="$3"
  [[ -f "$PLUGIN_DEST/$cat/${file}" ]] || { log_warn "Plugin missing: ${id:-$file}"; return 1; }
}

_split_plugin_deps() {
  local def="$1" bins_str installs_str rest
  _dep_bins=()
  _dep_installs=()
  bins_str=$(pf "$def" 4)
  installs_str=$(pf "$def" 5)
  [[ -z "$bins_str" ]] && return 0
  IFS=',' read -r -a _dep_bins <<< "$bins_str"
  rest="$installs_str"
  while [[ "$rest" == *';;'* ]]; do
    _dep_installs+=("${rest%%;;*}")
    rest="${rest#*;;}"
  done
  _dep_installs+=("$rest")
}

_plugin_needs_deps() {
  _split_plugin_deps "$1"
  local i
  for (( i = 0; i < ${#_dep_bins[@]}; i++ )); do
    [[ -n "${_dep_bins[i]}" ]] || continue
    command -v "${_dep_bins[i]}" &>/dev/null && continue
    [[ -n "${_dep_installs[i]:-}" ]] && return 0
  done
  return 1
}

install_core_plugins() {
  local n=0 IFS=$'\n'
  for def in $CORE_PLUGINS; do
    [[ -z "$def" ]] && continue
    _check_plugin "$(pf "$def" 6)" "core" "$(pf "$def" 1)" && (( n++ )) || true
  done
  log_ok "$n core plugins verified"
}

deploy_extra_plugins() {
  local n=0
  for def in "${selected_extra_defs[@]}"; do
    local name
    name=$(pf "$def" 1)
    if [[ "${extra_dep_map[$name]:-}" == "true" ]]; then
      _split_plugin_deps "$def"
      local i dep dep_install
      for (( i = 0; i < ${#_dep_bins[@]}; i++ )); do
        dep="${_dep_bins[i]}"
        dep_install="${_dep_installs[i]:-}"
        [[ -n "$dep" ]] || continue
        command -v "$dep" &>/dev/null && continue
        [[ -n "$dep_install" ]] || continue
        log_info "Installing $dep"
        eval "$dep_install" </dev/null && log_ok "$dep ready" || log_warn "Failed: $dep"
      done
    fi
    _check_plugin "$(pf "$def" 6)" "extra" "$name" && (( n++ )) || true
  done
  log_ok "$n extra plugins verified"
}

populate_express_plugins() {
  local _IFS="$IFS"
  IFS=$'\n'
  for def in $EXTRA_PLUGINS; do
    IFS="$_IFS"
    [[ -z "$def" ]] && continue
    selected_extra_defs+=("$def")
    local _name
    _name=$(pf "$def" 1)
    _plugin_needs_deps "$def" && extra_dep_map["$_name"]="true" || true
  done
  IFS="$_IFS"
}
