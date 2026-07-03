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
      local dep dep_install
      dep=$(pf "$def" 4)
      dep_install=$(pf "$def" 5)
      log_info "Installing $dep"
      eval "$dep_install" </dev/null && log_ok "$dep ready" || log_warn "Failed: $dep"
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
    local _name _dep _dep_install
    _name=$(pf "$def" 1)
    _dep=$(pf "$def" 4)
    _dep_install=$(pf "$def" 5)
    [[ -n "$_dep" ]] && ! command -v "$_dep" &>/dev/null && [[ -n "$_dep_install" ]] \
      && extra_dep_map["$_name"]="true" || true
  done
  IFS="$_IFS"
}
