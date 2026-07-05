#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../core/bash" && pwd)/bootstrap.sh"

readonly QS_DIR="${QS_DIR:-$AURA_REPO_DIR/config/quickshell}"
readonly PLUGIN_DIR="$QS_DIR/services/plugins"
readonly PLUGIN_QMLDIR="$PLUGIN_DIR/qmldir"
readonly DOMAIN_DIRS=(hyprland appearance system media apps ui infra plugins)

generate_dir_qmldir() {
  local dir="$1"
  local module_name="$2"
  local dir_path="$QS_DIR/$dir"
  local qmldir_path="$dir_path/qmldir"
  local file filename

  [[ -d "$dir_path" ]] || return 0

  printf 'module %s\n' "$module_name" > "$qmldir_path"

  for file in "$dir_path"/*.qml; do
    [[ -e "$file" ]] || continue
    filename="$(basename "$file" .qml)"
    [[ "$filename" == _* ]] && continue
    if head -5 "$file" | grep -q 'pragma Singleton'; then
      printf 'singleton %s 1.0 %s.qml\n' "$filename" "$filename" >> "$qmldir_path"
    else
      printf '%s 1.0 %s.qml\n' "$filename" "$filename" >> "$qmldir_path"
    fi
  done

  log_info "Generated: $qmldir_path"
}

generate_plugin_qmldir() {
  local subdir file filename rel plugindir ui uifile uiname
  ensure_dir "$PLUGIN_DIR"
  printf 'module plugins\n' > "$PLUGIN_QMLDIR"

  # Plugin entries: every *Plugin.qml under core/extra/community, searched
  # recursively so per-plugin subdirectories work. A plugin's co-located
  # private UI files don't end in *Plugin.qml, so they're excluded here and
  # resolve via QML's same-directory lookup instead.
  for subdir in core extra community; do
    [[ -d "$PLUGIN_DIR/$subdir" ]] || continue
    while IFS= read -r file; do
      filename="$(basename "$file" .qml)"
      [[ "$filename" == "ExamplePlugin" ]] && continue
      [[ "$filename" == _* ]] && continue
      rel="${file#"$PLUGIN_DIR"/}"
      printf '%s 1.0 %s\n' "$filename" "$rel" >> "$PLUGIN_QMLDIR"
    done < <(find "$PLUGIN_DIR/$subdir" -name '*Plugin.qml' | sort)
  done

  for file in "$PLUGIN_DIR"/*.qml; do
    [[ -e "$file" ]] || continue
    [[ -L "$file" ]] && continue
    filename="$(basename "$file" .qml)"
    [[ "$filename" == "ExamplePlugin" ]] && continue
    # _BasePlugin.qml is the base type all plugins extend; expose it as the
    # QML type `BasePlugin` (underscore-prefixed names aren't valid QML types).
    if [[ "$filename" == "_BasePlugin" ]]; then
      printf 'BasePlugin 1.0 _BasePlugin.qml\n' >> "$PLUGIN_QMLDIR"
      continue
    fi
    [[ "$filename" == _* ]] && continue
    printf '%s 1.0 %s.qml\n' "$filename" "$filename" >> "$PLUGIN_QMLDIR"
  done

  # Per-plugin component qmldirs: a plugin folder that holds private UI files
  # (non-*Plugin.qml) gets its own qmldir listing them, so the plugin can use
  # them by type name. Same-directory resolution is disabled inside the
  # plugins module, so this local registry is what makes co-located UI work.
  for subdir in core extra community; do
    [[ -d "$PLUGIN_DIR/$subdir" ]] || continue
    for plugindir in "$PLUGIN_DIR/$subdir"/*/; do
      [[ -d "$plugindir" ]] || continue
      ui=""
      for uifile in "$plugindir"*.qml; do
        [[ -e "$uifile" ]] || continue
        uiname="$(basename "$uifile" .qml)"
        [[ "$uiname" == *Plugin ]] && continue
        [[ "$uiname" == _* ]] && continue
        if head -5 "$uifile" | grep -q 'pragma Singleton'; then
          ui+="singleton $uiname 1.0 $uiname.qml"$'\n'
        else
          ui+="$uiname 1.0 $uiname.qml"$'\n'
        fi
      done
      if [[ -n "$ui" ]]; then
        printf '%s' "$ui" > "$plugindir/qmldir"
        log_info "Generated: ${plugindir}qmldir"
      else
        rm -f "$plugindir/qmldir"
      fi
    done
  done

  log_info "Generated: $PLUGIN_QMLDIR"
}

generate_domain_qmldirs() {
  local domain
  for domain in "${DOMAIN_DIRS[@]}"; do
    # plugins has its own dedicated generator
    [[ "$domain" == "plugins" ]] && continue
    generate_dir_qmldir "services/$domain" "$domain"
  done
}

generate_services_reexport() {
  local services_dir="$QS_DIR/services"
  local qmldir_path="$services_dir/qmldir"
  local domain domain_dir file filename

  printf 'module services\n' > "$qmldir_path"

  for domain in "${DOMAIN_DIRS[@]}"; do
    domain_dir="$services_dir/$domain"
    [[ -d "$domain_dir" ]] || continue
    for file in "$domain_dir"/*.qml; do
      [[ -e "$file" ]] || continue
      filename="$(basename "$file" .qml)"
      [[ "$filename" == "ExamplePlugin" ]] && continue
      # Re-export the plugin base type under its QML name (see plugin generator).
      if [[ "$filename" == "_BasePlugin" ]]; then
        printf 'BasePlugin 1.0 %s/_BasePlugin.qml\n' "$domain" >> "$qmldir_path"
        continue
      fi
      [[ "$filename" == _* ]] && continue
      if head -5 "$file" | grep -q 'pragma Singleton'; then
        printf 'singleton %s 1.0 %s/%s.qml\n' "$filename" "$domain" "$filename" >> "$qmldir_path"
      else
        printf '%s 1.0 %s/%s.qml\n' "$filename" "$domain" "$filename" >> "$qmldir_path"
      fi
    done
  done

  log_info "Generated: $qmldir_path (re-export)"
}

has_domain_dirs() {
  local domain
  for domain in "${DOMAIN_DIRS[@]}"; do
    # plugins/ pre-exists in the flat layout; skip it for detection
    [[ "$domain" == "plugins" ]] && continue
    [[ -d "$QS_DIR/services/$domain" ]] && return 0
  done
  return 1
}

main() {
  log_info "Generating qmldir files in $QS_DIR"
  generate_dir_qmldir core core

  if has_domain_dirs; then
    generate_domain_qmldirs
    generate_services_reexport
  else
    generate_dir_qmldir services services
  fi

  generate_dir_qmldir styles styles
  generate_dir_qmldir components components
  generate_dir_qmldir lib lib
  generate_dir_qmldir settings/pages/layout layout
  generate_plugin_qmldir
  log_ok "qmldir generation complete"
}

main "$@"
