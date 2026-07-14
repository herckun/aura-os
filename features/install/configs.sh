#!/usr/bin/env bash

if [[ -n "${AURA_INSTALL_CONFIGS_LOADED:-}" ]]; then
  return 0
fi
AURA_INSTALL_CONFIGS_LOADED=1

deploy_hypr_config() {
  local _mon="$CONFIG_DIR/hypr/monitors.lua" _mon_bak=""
  if [[ -f "$_mon" ]] && head -1 "$_mon" | grep -q '@managed: display-settings'; then
    _mon_bak="$(mktemp "/tmp/${APP_NAME}-monitors-XXXXXX")"
    cp -f "$_mon" "$_mon_bak"
  fi
  local _lock="$CONFIG_DIR/hypr/hyprlock-theme.conf" _lock_bak=""
  if [[ -f "$_lock" ]] && head -1 "$_lock" | grep -q '@managed: hyprlock-theme'; then
    _lock_bak="$(mktemp "/tmp/${APP_NAME}-hyprlock-XXXXXX")"
    cp -f "$_lock" "$_lock_bak"
  fi
  local _idle="$CONFIG_DIR/hypr/hypridle.conf" _idle_bak=""
  if [[ -f "$_idle" ]] && head -1 "$_idle" | grep -q '@managed: power-settings'; then
    _idle_bak="$(mktemp "/tmp/${APP_NAME}-hypridle-XXXXXX")"
    cp -f "$_idle" "$_idle_bak"
  fi
  copy_config "$REPO_DIR/config/hypr" "$CONFIG_DIR/hypr"
  sed -i "s|@APP_NAME@|${APP_NAME}|g" "$CONFIG_DIR/hypr/hyprland.lua"
  [[ -n "$_lock_bak" ]] && mv -f "$_lock_bak" "$_lock"
  [[ -n "$_idle_bak" ]] && mv -f "$_idle_bak" "$_idle"
  if [[ -n "$_mon_bak" ]]; then
    mv -f "$_mon_bak" "$_mon"
    log_ok "Hyprland configs deployed (kept user display config)"
  else
    log_ok "Hyprland configs deployed"
  fi
}

deploy_qt_styling_env() {
  mkdir -p "$HOME/.config/environment.d"
  {
    echo "GTK_THEME=${APP_NAME}:dark"
    echo "${APP_ENV_PREFIX}_MANIFEST=${CONFIG_DIR}/${APP_NAME}/manifest.json"
    echo "QT_QPA_PLATFORMTHEME=kde"
    echo "QT_STYLE_OVERRIDE=kvantum"
  } > "$HOME/.config/environment.d/qt-styling.conf"
  systemctl --user set-environment "GTK_THEME=${APP_NAME}:dark" 2>/dev/null || true
  systemctl --user set-environment "${APP_ENV_PREFIX}_MANIFEST=${CONFIG_DIR}/${APP_NAME}/manifest.json" 2>/dev/null || true
  systemctl --user set-environment "QT_QPA_PLATFORMTHEME=kde" 2>/dev/null || true
  systemctl --user set-environment "QT_STYLE_OVERRIDE=kvantum" 2>/dev/null || true
  log_ok "Theme env vars: GTK_THEME, KDE platform theme + Fusion"
}

deploy_quickshell_config() {
  local _keep_bak="" _d
  for _d in icons sfx; do
    if [[ -d "$CONFIG_DIR/quickshell/$_d" ]]; then
      [[ -n "$_keep_bak" ]] || _keep_bak="$(mktemp -d "/tmp/${APP_NAME}-keep-XXXXXX")"
      mv "$CONFIG_DIR/quickshell/$_d" "$_keep_bak/$_d"
    fi
  done
  local _theme_bak=""
  if [[ -f "$CONFIG_DIR/quickshell/styles/theme.json" ]]; then
    _theme_bak="$(mktemp "/tmp/${APP_NAME}-theme-XXXXXX")"
    cp -f "$CONFIG_DIR/quickshell/styles/theme.json" "$_theme_bak"
  fi
  local _themes_bak=""
  if [[ -d "$CONFIG_DIR/quickshell/styles/themes" ]]; then
    _themes_bak="$(mktemp -d "/tmp/${APP_NAME}-themes-XXXXXX")"
    cp -a "$CONFIG_DIR/quickshell/styles/themes/." "$_themes_bak/" 2>/dev/null || true
  fi
  copy_config "$REPO_DIR/config/quickshell" "$CONFIG_DIR/quickshell"
  mkdir -p "$CONFIG_DIR/$APP_NAME"
  cp "$REPO_DIR/config/manifest.json" "$CONFIG_DIR/$APP_NAME/manifest.json"
  ln -sf "$CONFIG_DIR/$APP_NAME/manifest.json" "$CONFIG_DIR/quickshell/manifest.json"
  if [[ -d "$REPO_DIR/assets" ]]; then
    mkdir -p "$CONFIG_DIR/quickshell/assets"
    cp -a "$REPO_DIR/assets/"* "$CONFIG_DIR/quickshell/assets/" 2>/dev/null || true
  fi
  if [[ -n "$_keep_bak" ]]; then
    for _d in icons sfx; do
      [[ -d "$_keep_bak/$_d" ]] && mv "$_keep_bak/$_d" "$CONFIG_DIR/quickshell/$_d"
    done
    rm -rf "$_keep_bak"
  fi
  if [[ -n "$_theme_bak" ]]; then
    _merge_theme_json "$CONFIG_DIR/quickshell/styles/theme.json" "$_theme_bak" \
      || log_warn "theme.json merge failed — shipped defaults kept"
    rm -f "$_theme_bak"
  fi
  if [[ -n "$_themes_bak" ]]; then
    local _f _name
    for _f in "$_themes_bak"/*.json; do
      [[ -f "$_f" ]] || continue
      _name="$(basename "$_f")"
      [[ -e "$CONFIG_DIR/quickshell/styles/themes/$_name" ]] || cp -f "$_f" "$CONFIG_DIR/quickshell/styles/themes/$_name"
    done
    rm -rf "$_themes_bak"
  fi
  log_ok "QuickShell deployed"
}

_merge_theme_json() {
  local shipped="$1" user="$2"
  python3 - "$shipped" "$user" <<'PY'
import json, sys
shipped_path, user_path = sys.argv[1], sys.argv[2]

def merge(base, over):
    if isinstance(base, dict) and isinstance(over, dict):
        out = dict(base)
        for k, v in over.items():
            out[k] = merge(base[k], v) if k in base else v
        return out
    return over

with open(shipped_path) as fh:
    shipped = json.load(fh)
with open(user_path) as fh:
    user = json.load(fh)
with open(shipped_path, "w") as fh:
    json.dump(merge(shipped, user), fh, indent=2)
PY
}

sync_tabler_icons() {
  "$REPO_DIR/features/install/sync-icons.sh" --dir "$CONFIG_DIR/quickshell/icons"
  log_ok "Icons synced"
}

sync_sfx() {
  "$REPO_DIR/features/install/sync-sfx.sh" --dir "$CONFIG_DIR/quickshell/sfx"
  log_ok "Sound effects synced"
}

deploy_kitty_profile() {
  mkdir -p "$CONFIG_DIR/kitty"
  copy_config "$REPO_DIR/config/kitty/kitty.conf" "$CONFIG_DIR/kitty/kitty.conf"
  copy_config "$REPO_DIR/config/kitty/current-theme.conf" "$CONFIG_DIR/kitty/current-theme.conf"
  [[ -x "$REPO_DIR/features/theme/kitty.sh" ]] && "$REPO_DIR/features/theme/kitty.sh" || true
  log_ok "Kitty profile deployed"
}

deploy_fish_config() {
  mkdir -p "$CONFIG_DIR/fish/functions"
  copy_config "$REPO_DIR/config/fish/config.fish" "$CONFIG_DIR/fish/config.fish"
  [[ -x "$REPO_DIR/features/theme/fish.sh" ]] && "$REPO_DIR/features/theme/fish.sh" || true
  log_ok "Fish config deployed"
}

deploy_sddm_theme() {
  local sddm_target="/usr/share/sddm/themes/${APP_NAME}"
  if [[ -d "/usr/share/sddm/themes" ]]; then
    if sudo -n mkdir -p "$sddm_target" 2>/dev/null; then
      sudo -n rm -rf "$sddm_target" 2>/dev/null || true
      sudo -n mkdir -p "$sddm_target" 2>/dev/null || true
      sudo -n cp -r "$REPO_DIR/config/sddm/theme/"* "$sddm_target/" 2>/dev/null || true
      sudo -n sed -i "s|@APP_NAME@|${APP_NAME}|g;s|@APP_DISPLAY@|${APP_DISPLAY}|g" "$sddm_target/metadata.desktop" 2>/dev/null || true
      sudo -n sed -i "s|@HOME@|${HOME}|g;s|@APP_NAME@|${APP_NAME}|g" "$sddm_target/configs/theme.conf" 2>/dev/null || true
      sudo -n chown "$USER:$USER" "$sddm_target/backgrounds" 2>/dev/null || true
      local _evc="${APP_ENV_PREFIX}_CACHE_DIR"
      local wp_cache="${!_evc:-${XDG_CACHE_HOME:-$HOME/.cache}/${APP_NAME}}/current-wallpaper"
      if [[ -f "$wp_cache" ]] && read -r wp_path < "$wp_cache" 2>/dev/null && [[ -f "$wp_path" ]]; then
        cp -f "$wp_path" "$sddm_target/backgrounds/current.jpg" 2>/dev/null || true
      fi
      if [[ -d "$sddm_target/fonts" ]]; then
        sudo -n cp -r "$sddm_target/fonts/"* /usr/share/fonts/ 2>/dev/null || true
        sudo -n fc-cache -f 2>/dev/null || true
      fi
      local sddm_conf="/etc/sddm.conf"
      if [[ -f "$sddm_conf" ]]; then
        sudo -n cp -f "$sddm_conf" "$sddm_conf.bkp" 2>/dev/null || true
      fi
      if [[ ! -f "$sddm_conf" ]] || ! sudo -n grep -q "Current=${APP_NAME}" "$sddm_conf" 2>/dev/null; then
        if sudo -n grep -Pzq "\[Theme\]\nCurrent=" "$sddm_conf" 2>/dev/null; then
          sudo -n sed -i "/^\[Theme\]$/{N;s/\(Current=\).*/\1${APP_NAME}/;}" "$sddm_conf" 2>/dev/null || true
        else
          printf "\n[Theme]\nCurrent=${APP_NAME}\n" | sudo -n tee -a "$sddm_conf" >/dev/null 2>&1 || true
        fi
      fi
      local greeter_env="GreeterEnvironment=QML2_IMPORT_PATH=$sddm_target/components/,QML_XHR_ALLOW_FILE_READ=1"
      if ! sudo -n grep -q "GreeterEnvironment=QML2_IMPORT_PATH" "$sddm_conf" 2>/dev/null; then
        printf "%s\n" "$greeter_env" | sudo -n tee -a "$sddm_conf" >/dev/null 2>&1 || true
      else
        sudo -n sed -i "s|GreeterEnvironment=.*|${greeter_env}|" "$sddm_conf" 2>/dev/null || true
      fi
      # Disable virtual keyboard (SDDM 0.20+ defaults to qtvirtualkeyboard)
      if sudo -n grep -q "^\[General\]" "$sddm_conf" 2>/dev/null; then
        if ! sudo -n grep -q "^InputMethod=" "$sddm_conf" 2>/dev/null; then
          sudo -n sed -i "/^\[General\]/a InputMethod=" "$sddm_conf" 2>/dev/null || true
        else
          sudo -n sed -i "s|^InputMethod=.*|InputMethod=|" "$sddm_conf" 2>/dev/null || true
        fi
      else
        printf "\n[General]\nInputMethod=\n" | sudo -n tee -a "$sddm_conf" >/dev/null 2>&1 || true
      fi
      record_path "$sddm_target"
      log_ok "SDDM theme deployed"
    else
      log_warn "SDDM skipped (sudo unavailable)"
    fi
  else
    log_info "SDDM not found — skipped"
  fi

  # Grant sddm user read access to config dir for theme JSON
  local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/${APP_NAME}"
  local config_parent="${XDG_CONFIG_HOME:-$HOME/.config}"
  mkdir -p "$config_dir"
  if command -v setfacl &>/dev/null; then
    sudo -n setfacl -m u:sddm:rx "$HOME" 2>/dev/null || true
    sudo -n setfacl -m u:sddm:rx "$config_parent" 2>/dev/null || true
    sudo -n setfacl -m u:sddm:rX "$config_dir" 2>/dev/null || true
    sudo -n setfacl -d -m u:sddm:r "$config_dir" 2>/dev/null || true
  else
    chmod o+rX "$HOME" "$config_parent" "$config_dir" 2>/dev/null || true
  fi
}

reset_plugin_layout() {
  local f="$CONFIG_DIR/$APP_NAME/settings.json"
  if [[ ! -f "$f" ]]; then
    log_info "No settings.json — default layout applies on first shell start"
    return 0
  fi
  python3 - "$f" <<'PY'
import json, sys
path = sys.argv[1]
with open(path) as fh:
    s = json.load(fh)
plugins = s.get("plugins")
if not isinstance(plugins, dict):
    plugins = {}
    s["plugins"] = plugins
plugins["resetPending"] = True
with open(path, "w") as fh:
    json.dump(s, fh, indent=2)
PY
  log_ok "Plugin layout reset scheduled — defaults apply on next shell start"
}

deploy_wleave_config() {
  copy_config "$REPO_DIR/config/wleave" "$CONFIG_DIR/wleave"
  log_ok "wleave config deployed"
}

deploy_cava_config() {
  copy_config "$REPO_DIR/config/cava" "$CONFIG_DIR/cava"
  log_ok "cava config deployed"
}

deploy_desktop_scripts() {
  mkdir -p "$CONFIG_DIR/core" "$CONFIG_DIR/features" "$CONFIG_DIR/dev"

  rm -rf \
    "$CONFIG_DIR/scripts" \
    "$CONFIG_DIR/features" \
    "$CONFIG_DIR/dev" \
    "$CONFIG_DIR/core/bash" \
    2>/dev/null || true

  [[ -d "$REPO_DIR/core/bash" ]] && copy_config "$REPO_DIR/core/bash" "$CONFIG_DIR/core/bash"
  [[ -d "$REPO_DIR/features" ]] && copy_config "$REPO_DIR/features" "$CONFIG_DIR/features"
  [[ -d "$REPO_DIR/dev" ]] && copy_config "$REPO_DIR/dev" "$CONFIG_DIR/dev"

  while IFS= read -r f; do
    chmod +x "$f"
  done < <(find "$CONFIG_DIR/features" "$CONFIG_DIR/dev" -type f \( -name "*.sh" -o -name "*.py" \) -print 2>/dev/null)

  log_ok "Features, dev tools, and shared core deployed"
}

generate_gtk_qt_themes() {
  if command -v xsettingsd &>/dev/null && ! pgrep -x xsettingsd &>/dev/null; then
    nohup xsettingsd &>/dev/null &
    sleep 0.2
  fi
  if [[ -x "$CONFIG_DIR/features/theme/gtk-qt.sh" ]]; then
    "$CONFIG_DIR/features/theme/gtk-qt.sh" 2>&1 || log_warn "Theme generation had minor issues"
  fi
}

deploy_plugins_step() {
  local pd="$CONFIG_DIR/quickshell/services/plugins"
  [[ -d "$pd" ]] && find "$pd" -maxdepth 1 -name "*.qml" -type l -delete 2>/dev/null || true
  install_core_plugins
  deploy_extra_plugins
  "$REPO_DIR/dev/generate-qmldir.sh" >/dev/null 2>&1 || true
}

finish_install() {
  echo "installed:$(timestamp)" > "$STATE_FILE"
  echo "mode:copy" >> "$STATE_FILE"
  sync

  if $TUI_ACTIVE; then
    tui_done
  else
    clear
  fi

  _show_install_summary
  [[ -n "$BACKUP_SNAPSHOT" ]] && printf "  ${DIM}Backup: %s${NC}\n\n" "$BACKUP_SNAPSHOT"
  printf "  ${BOLD}Quick reference:${NC}\n"
  printf "  ${DIM}SUPER + RETURN${NC}     Terminal\n"
  printf "  ${DIM}SUPER + SPACE${NC}      Launcher\n"
  printf "  ${DIM}SUPER + W${NC}          Close window\n"
  printf "  ${DIM}SUPER + SPACE${NC}      Workspace overview\n\n"

  hyprctl reload >/dev/null 2>&1 || true
  _ok "Hyprland reloaded"

  pkill -9 -x qs >/dev/null 2>&1 || true
  pkill -9 -x quickshell >/dev/null 2>&1 || true
  local i=0
  while pgrep -x qs &>/dev/null || pgrep -x quickshell &>/dev/null; do
    sleep 0.2; (( ++i > 15 )) && break
  done
  sleep 0.5
  nohup qs &>/dev/null &
  _ok "QuickShell restarted"

  # shellcheck disable=SC2059
  printf "\n  ${DIM}To uninstall: ./install.sh --uninstall${NC}\n"
  printf "\n  Press ${BOLD}Enter${NC} to exit: "
  read -r _
  TUI_TORN_DOWN=true
}
