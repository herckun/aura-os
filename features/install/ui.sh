#!/usr/bin/env bash
# shellcheck disable=SC2059 — This file heavily uses ANSI color variables in printf format strings intentionally

if [[ -n "${AURA_INSTALL_UI_LOADED:-}" ]]; then
  return 0
fi
AURA_INSTALL_UI_LOADED=1

_t() { printf '%b' "$1" >&${TUI_FD} 2>/dev/null; }
_tp() {
  local _tp_fmt="$1"; shift
  # shellcheck disable=SC2059 — format string is intentionally dynamic
  printf '%b' "$(printf "$_tp_fmt" "$@")" >&${TUI_FD} 2>/dev/null
}
_at() {
  local r=$1 c=$2
  (( r < 1 )) && r=1
  (( r > ROWS )) && r=$ROWS
  (( c < 1 )) && c=1
  (( c > COLS )) && c=$COLS
  printf '\e[%d;%dH' "$r" "$c" >&${TUI_FD}
}
_clrln() { printf '\e[2K' >&${TUI_FD}; }
_strip_ansi() { printf '%s' "$1" | sed 's/\x1b\[[0-9;]*m//g'; }
_trunc() {
  local text="$1" max="$2" clean
  clean=$(_strip_ansi "$text")
  if (( ${#clean} > max )); then
    printf '%s' "${clean:0:$max}"
  else
    printf '%s' "$clean"
  fi
}

tui_init() {
  TUI_ACTIVE=true
  TUI_STEP_NUM=0
  exec 3>/dev/tty
  printf '\033[?1049h' >&3
  printf '\033[?25l' >&3
  printf '\033[H\033[3J\033[2J' >&3
  COLS=$(tput cols 2>/dev/null || echo 80)
  ROWS=$(tput lines 2>/dev/null || echo 24)
  TUI_TOP=1
  TUI_BOTTOM=$ROWS
}

tui_teardown() {
  TUI_ACTIVE=false
  TUI_TORN_DOWN=true
  printf '\033[?25h' >&${TUI_FD} 2>/dev/null || true
  printf '\033[?1049l' >&${TUI_FD} 2>/dev/null || true
  exec 3>&- 2>/dev/null || true
}

_make_bar() {
  local width="$1" pct="$2"
  local pos=$(( pct * width * 8 / 100 ))
  local full=$(( pos / 8 ))
  local sub=$(( pos % 8 ))
  local empty=$(( width - full - (sub > 0 ? 1 : 0) ))
  (( empty < 0 )) && empty=0
  local bar="" i
  for (( i=0; i<full; i++ )); do bar+="${R}█${NC}"; done
  if (( sub > 0 )); then
    case "$sub" in
      1) bar+="${R}▏${NC}" ;;
      2) bar+="${R}▎${NC}" ;;
      3) bar+="${R}▍${NC}" ;;
      4) bar+="${R}▌${NC}" ;;
      5) bar+="${R}▋${NC}" ;;
      6) bar+="${R}▊${NC}" ;;
      7) bar+="${R}▉${NC}" ;;
    esac
  fi
  local _bar_empty
  printf -v _bar_empty '%*s' "$empty" ''
  bar+="${DIM}${_bar_empty// /░}${NC}"
  printf '%b' "$bar" >&${TUI_FD}
}

_tui_render() {
  COLS=$(tput cols 2>/dev/null || echo 80)
  ROWS=$(tput lines 2>/dev/null || echo 24)
  TUI_BOTTOM=$(( ROWS - 2 ))
  local top=$TUI_TOP left=3 inner right hline
  inner=$(( COLS - left - 1 ))
  (( inner < 40 )) && inner=40
  right=$(( left + inner - 1 ))
  _at $top $left; _clrln
  hline=$(printf '%*s' $(( inner - 2 )) '')
  hline=${hline// /─}
  _tp "${DIM}╭${hline}╮${NC}"
  _at $(( top + 1 )) $left; _clrln
  _tp "${DIM}│${NC}  ${R}${BOLD}aura${NC}${DIM}-${NC}${BOLD}os${NC}"
  [[ -n "$TUI_HEADER_MODE" ]] && _tp "  ${DIM}${TUI_HEADER_MODE}${NC}"
  _at $(( top + 1 )) $right; _tp "${DIM}│${NC}"
  _at $(( top + 2 )) $left; _clrln
  _tp "${DIM}│${NC}  ${DIM}Desktop Environment  Hyprland + QuickShell${NC}"
  _at $(( top + 2 )) $right; _tp "${DIM}│${NC}"
  _at $(( top + 3 )) $left; _clrln
  _tp "${DIM}╰${hline}╯${NC}"
  _at $(( top + 4 )) $left; _clrln
  _tp "${DIM}│${NC}"
  if [[ -n "$TUI_STEP_NAME" ]]; then
    local max_step=$(( inner - 6 ))
    _tp "  ${BOLD}%s${NC}" "$(_trunc "$TUI_STEP_NAME" "$max_step")"
  fi
  _at $(( top + 4 )) $right; _tp "${DIM}│${NC}"
  _at $(( top + 5 )) $left; _clrln
  _tp "${DIM}│${NC}  "
  if (( TUI_STEP_TOTAL > 0 )); then
    local pct=$(( TUI_STEP_NUM * 100 / TUI_STEP_TOTAL ))
    local step_str step_w bw
    printf -v step_str "  %d/%-3d " "$TUI_STEP_NUM" "$TUI_STEP_TOTAL"
    step_w=${#step_str}
    bw=$(( inner - 14 - step_w ))
    (( bw < 6 )) && bw=6
    _tp "  ${R}%d/${NC}%-3d " "$TUI_STEP_NUM" "$TUI_STEP_TOTAL"
    _make_bar "$bw" "$pct"
    _tp "  ${DIM}%3d%%${NC}" "$pct"
  fi
  _at $(( top + 5 )) $right; _tp "${DIM}│${NC}"
  _at $(( top + 6 )) $left; _clrln
  _tp "${DIM}╰${hline}╯${NC}"
  local log_start=$(( top + 7 ))
  local log_end=$(( TUI_BOTTOM - 4 ))
  local log_h=$(( log_end - log_start + 1 ))
  (( log_h < 3 )) && log_h=3
  local vis_count=${#TUI_LOGS[@]}
  (( vis_count > log_h )) && vis_count=$log_h
  local start_idx=$(( ${#TUI_LOGS[@]} - vis_count ))
  local pad=$(( log_h - vis_count ))
  local r i lvl msg entry max_msg
  for (( r=0; r<pad; r++ )); do
    _at $(( log_start + r )) $left; _clrln
    _tp "${DIM}│${NC}"
    _at $(( log_start + r )) $right; _tp "${DIM}│${NC}"
  done
  i=0
  max_msg=$(( inner - 6 ))
  (( max_msg < 10 )) && max_msg=10
  for (( r=pad; r<log_h; r++ )); do
    _at $(( log_start + r )) $left; _clrln
    _tp "${DIM}│${NC}"
    if (( i < vis_count )); then
      entry="${TUI_LOGS[$(( start_idx + i ))]}"
      lvl="${entry%%|*}"
      msg="${entry#*|}"
      msg="$(_trunc "$msg" "$max_msg")"
      case "$lvl" in
        ok) _tp "  ${R}✓${NC} %s" "$msg" ;;
        warn) _tp "  ${R}▲${NC} %s" "$msg" ;;
        err) _tp "  ${R}✕${NC} %s" "$msg" ;;
        *) _tp "  ${DIM}·${NC} %s" "$msg" ;;
      esac
      (( i++ )) || true
    fi
    _at $(( log_start + r )) $right; _tp "${DIM}│${NC}"
  done
  _at $(( log_end + 1 )) $left; _clrln
  _tp "${DIM}╰${hline}╯${NC}"
  _at $(( log_end + 2 )) $left; _clrln
  _tp "${DIM}│${NC}"
  local sl="" sr=" ${APP_NAME} " mp
  (( TUI_STEP_TOTAL > 0 )) && sl=" step ${TUI_STEP_NUM}/${TUI_STEP_TOTAL} "
  mp=$(( inner - 2 - ${#sl} - ${#sr} ))
  (( mp < 0 )) && mp=0
  _tp "${R}${BOLD}%s${NC}%s${R}${BOLD}%s${NC}" "$sl" "$(printf '%*s' "$mp" '')" "$sr"
  _at $(( log_end + 2 )) $right; _tp "${DIM}│${NC}"
  _at $(( log_end + 3 )) $left; _clrln
  _tp "${DIM}╰${hline}╯${NC}"
  local hint_row=$(( log_end + 4 ))
  if (( hint_row <= ROWS )); then
    _at $hint_row $left; _clrln
    _tp "  ${DIM}ctrl+c to abort${NC}"
  fi
}

tui_step() {
  local name="$1"
  (( TUI_STEP_NUM++ )) || true
  TUI_STEP_NAME="$name"
  _tui_render
}

tui_log() {
  local level="$1" msg="$2"
  TUI_LOGS+=("${level}|${msg}")
  (( ${#TUI_LOGS[@]} > TUI_LOG_MAX )) && TUI_LOGS=("${TUI_LOGS[@]:1}")
  _tui_render
}

tui_done() {
  TUI_STEP_NAME='Installation complete'
  _tui_render
  sleep 1
  tui_teardown
  clear
}

_show_install_summary() {
  printf "\n  ${G}✓${NC} ${BOLD}Installation complete${NC}\n"
  if [[ ${#INSTALL_ERRORS[@]} -gt 0 ]]; then
    printf "  ${R}${#INSTALL_ERRORS[@]} error(s)${NC}\n"
    for e in "${INSTALL_ERRORS[@]}"; do printf "    ${R}✗${NC} ${e}\n"; done
  fi
  if [[ ${#INSTALL_WARNINGS[@]} -gt 0 ]]; then
    printf "  ${Y}${#INSTALL_WARNINGS[@]} warning(s)${NC}\n"
    for w in "${INSTALL_WARNINGS[@]}"; do printf "    ${Y}⚠${NC} ${w}\n"; done
  fi
  printf "\n"
}

log_info() { if $TUI_ACTIVE; then tui_log "info" "$1"; else printf "  ${DIM}·${NC} %s\n" "$1"; fi; }
log_ok() { if $TUI_ACTIVE; then tui_log "ok" "$1"; else printf "  ${G}✓${NC} %s\n" "$1"; fi; }
log_warn() { INSTALL_WARNINGS+=("$1"); if $TUI_ACTIVE; then tui_log "warn" "$1"; else printf "  ${Y}⚠${NC} %s\n" "$1"; fi; }
log_err() { INSTALL_ERRORS+=("$1"); if $TUI_ACTIVE; then tui_log "err" "$1"; else printf "  ${R}✗${NC} %s\n" "$1" >&2; fi; }

run_step() {
  local name="$1" fn="$2"
  if $NONINTERACTIVE; then
    _info "$name..."
    if ! eval "$fn" >/dev/null 2>&1; then
      log_err "Failed: $name"
    fi
    return
  fi
  tui_step "$name"
  if $CONFIRM_EACH; then
    COLS=$(tput cols 2>/dev/null || echo 80)
    ROWS=$(tput lines 2>/dev/null || echo 24)
    _at $(( ROWS - 1 )) 1; _clrln
    { printf "  Run this step? ${DIM}[Y/n]${NC}: "; } >&${TUI_FD}
    read -r _ans </dev/tty
    if [[ "$_ans" =~ ^[Nn]$ ]]; then
      log_info "Skipped: $name"
      return
    fi
  fi
  if ! eval "$fn" >/dev/null 2>&1; then
    log_err "Failed: $name"
  fi
  log_ok "$name"
}

_prompt() {
  local q="$1" hint="${2:-}"
  printf "\n  %s" "$q"
  [[ -n "$hint" ]] && printf " ${DIM}%s${NC}" "$hint"
  printf ": "
  read -r REPLY
}

_yn() {
  local q="$1"
  printf "  %s ${DIM}[Y/n]${NC}: " "$q"
  read -r _r
  [[ ! "$_r" =~ ^[Nn]$ ]]
}

# Interactive checkbox multi-select rendered on the normal terminal (pre-TUI).
# Caller populates these globals before calling:
#   MENU_LABELS=()  item labels
#   MENU_DESCS=()   per-item dim description (optional, "")
#   MENU_GROUPS=()  per-item group header, printed when it changes ("" = none)
#   MENU_CHECKED=() initial 0/1 state per item
# Controls: ↑/↓ or j/k move, space toggles, 'a' toggles all, Enter/q confirm.
# On return, MENU_CHECKED holds the final 0/1 state. Falls back to defaults with no tty.
_checkbox_menu() {
  local n=${#MENU_LABELS[@]}
  (( n == 0 )) && return 0
  [[ -r /dev/tty && -w /dev/tty ]] || return 0

  # Count rendered lines (items + group headers) so we can redraw in place.
  local dlines=0 _i _last=""
  for (( _i = 0; _i < n; _i++ )); do
    if [[ -n "${MENU_GROUPS[_i]:-}" && "${MENU_GROUPS[_i]}" != "$_last" ]]; then
      _last="${MENU_GROUPS[_i]}"; dlines=$(( dlines + 1 ))
    fi
    dlines=$(( dlines + 1 ))
  done

  local cur=0 first=1 key rest box
  printf '\033[?25l'
  while true; do
    if (( first )); then first=0; else printf '\033[%dA' "$dlines"; fi
    _last=""
    for (( _i = 0; _i < n; _i++ )); do
      if [[ -n "${MENU_GROUPS[_i]:-}" && "${MENU_GROUPS[_i]}" != "$_last" ]]; then
        _last="${MENU_GROUPS[_i]}"
        printf '\033[2K  %s%s%s\n' "$BOLD$C" "$_last" "$NC"
      fi
      box=" "; [[ "${MENU_CHECKED[_i]}" == "1" ]] && box="x"
      if (( _i == cur )); then
        printf '\033[2K  %s>%s %s[%s]%s %-18s %s%s%s\n' \
          "$R" "$NC" "$W" "$box" "$NC" "${MENU_LABELS[_i]}" "$DIM" "${MENU_DESCS[_i]:-}" "$NC"
      else
        printf '\033[2K    %s[%s]%s %-18s %s%s%s\n' \
          "$DIM" "$box" "$NC" "${MENU_LABELS[_i]}" "$DIM" "${MENU_DESCS[_i]:-}" "$NC"
      fi
    done

    IFS= read -rsN1 key </dev/tty || true
    if [[ "$key" == $'\033' ]]; then
      read -rsN2 -t 0.05 rest </dev/tty || true
      key+="$rest"
    fi
    case "$key" in
      $'\033[A' | k | K) cur=$(( (cur - 1 + n) % n )) ;;
      $'\033[B' | j | J) cur=$(( (cur + 1) % n )) ;;
      ' ')
        if [[ "${MENU_CHECKED[cur]}" == "1" ]]; then MENU_CHECKED[cur]=0; else MENU_CHECKED[cur]=1; fi
        ;;
      a | A)
        local _all=1 _j
        for (( _j = 0; _j < n; _j++ )); do [[ "${MENU_CHECKED[_j]}" == "1" ]] || { _all=0; break; }; done
        local _nv=1; [[ "$_all" == "1" ]] && _nv=0
        for (( _j = 0; _j < n; _j++ )); do MENU_CHECKED[_j]=$_nv; done
        ;;
      $'\n' | $'\r' | q | Q) break ;;
    esac
  done
  printf '\033[?25h'
  return 0
}

screen_welcome() {
  clear
  COLS=$(tput cols 2>/dev/null || echo 80)
  printf "\n\n"
  printf "  ${BOLD}${R}"
  printf -- 'aura'
  printf "${W}"
  printf -- '-os'
  printf "${NC}\n"
  printf "  ${DIM}Desktop Environment  ·  Hyprland + QuickShell${NC}\n\n"
  _hr
  printf "\n  A curated, opinionated desktop environment for Hyprland,\n"
  printf "  built on QuickShell with a modular plugin system.\n\n"
  printf "  ${BOLD}This installer will:${NC}\n"
  printf "  ${DIM}·${NC} Snapshot your existing configs (backup)\n"
  printf "  ${DIM}·${NC} Install required system packages via pacman / AUR\n"
  printf "  ${DIM}·${NC} Autodetect and install GPU drivers (NVIDIA / AMD / Intel)\n"
  printf "  ${DIM}·${NC} Set up Wayland screen sharing (incl. Discord)\n"
  printf "  ${DIM}·${NC} Deploy Hyprland, QuickShell, Kitty, and Fish configs\n"
  printf "  ${DIM}·${NC} Sync the Tabler icon set\n"
  printf "  ${DIM}·${NC} Set up SDDM greeter theme\n"
  printf "  ${DIM}·${NC} Install and verify plugins${W} (Expert: optional apps too)${NC}\n\n"
  _hr
  printf "\n  ${BOLD}Choose installation mode:${NC}\n\n"
  printf "    ${R}1${NC}  Express  ${DIM}— everything installed, best defaults ${BOLD}(recommended)${NC}\n"
  printf "    ${W}2${NC}  Expert   ${DIM}— choose which steps and plugins to run${NC}\n"
  printf "    ${DIM}3  Quit${NC}\n\n"
  printf "  ${DIM}[1]${NC}: "
  read -r _choice
  [[ -z "$_choice" ]] && _choice="1"
  case "$_choice" in
    1) INSTALL_MODE="express" ;;
    2) INSTALL_MODE="expert" ;;
    3|q|Q) printf "\n  Goodbye.\n\n"; exit 0 ;;
    *) printf "\n  ${R}Invalid choice.${NC}\n\n"; screen_welcome; return ;;
  esac
}

screen_expert() {
  clear
  printf "\n  ${BOLD}Expert Setup${NC}\n"
  printf "  ${DIM}↑/↓ move · space toggle · a all · Enter confirm${NC}\n\n"
  _hr
  printf "\n  ${BOLD}Steps${NC}\n\n"

  local step_labels=(
    "Backup configs" "System packages" "GPU drivers" "Screen sharing"
    "Fonts" "Hyprland config" "QuickShell config" "Tabler icons"
    "Kitty profile" "Fish config" "SDDM theme"
    "Desktop scripts" "GTK/Qt themes" "Extra plugins"
  )
  local step_vars=(
    RUN_BACKUP RUN_DEPS RUN_GPU RUN_SCREENSHARE
    RUN_FONTS RUN_HYPR RUN_QS RUN_ICONS
    RUN_KITTY RUN_FISH RUN_SDDM
    RUN_SCRIPTS RUN_THEME RUN_PLUGINS
  )
  MENU_LABELS=("${step_labels[@]}"); MENU_DESCS=(); MENU_GROUPS=(); MENU_CHECKED=()
  local i
  for (( i = 0; i < ${#step_vars[@]}; i++ )); do
    MENU_DESCS+=(""); MENU_GROUPS+=("")
    # Default-checked = current value of the RUN_* var (all true by default).
    if [[ "${!step_vars[i]}" == "true" ]]; then MENU_CHECKED+=(1); else MENU_CHECKED+=(0); fi
  done
  _checkbox_menu
  for (( i = 0; i < ${#step_vars[@]}; i++ )); do
    if [[ "${MENU_CHECKED[i]}" == "1" ]]; then eval "${step_vars[i]}=true"; else eval "${step_vars[i]}=false"; fi
  done

  printf "\n"
  _hr
  printf "\n  Confirm before each step? ${DIM}[y/N]${NC}: "
  read -r _r
  [[ "$_r" =~ ^[Yy]$ ]] && CONFIRM_EACH=true
  $RUN_BACKUP || NO_BACKUP=true
  $RUN_DEPS || NO_DEPS=true
  return 0
}

screen_plugins() {
  local extra_arr=() _oldifs="$IFS"
  IFS=$'\n'; for def in ${EXTRA_PLUGINS:-}; do [[ -z "$def" ]] || extra_arr+=("$def"); done
  IFS="$_oldifs"
  local total=${#extra_arr[@]}
  (( total == 0 )) && return 0
  clear
  printf "\n  ${BOLD}Extra Plugins${NC}\n"
  printf "  ${DIM}Need extra CLI tools · ↑/↓ move · space toggle · a all · Enter confirm${NC}\n\n"
  _hr
  printf "\n"

  MENU_LABELS=(); MENU_DESCS=(); MENU_GROUPS=(); MENU_CHECKED=()
  local def
  for def in "${extra_arr[@]}"; do
    MENU_LABELS+=("$(pf "$def" 2)")
    MENU_DESCS+=("$(pf "$def" 3)")
    MENU_GROUPS+=("")
    MENU_CHECKED+=(1)
  done
  _checkbox_menu

  local i name
  for (( i = 0; i < total; i++ )); do
    [[ "${MENU_CHECKED[i]}" == "1" ]] || continue
    def="${extra_arr[i]}"
    selected_extra_defs+=("$def")
    name=$(pf "$def" 1)
    # Auto-install missing tool deps for the plugins the user checked.
    _plugin_needs_deps "$def" && extra_dep_map["$name"]="true" || true
  done
  return 0
}

screen_apps() {
  local apps_arr=() _oldifs="$IFS"
  IFS=$'\n'; for def in ${APPS:-}; do [[ -z "$def" ]] || apps_arr+=("$def"); done
  IFS="$_oldifs"
  local total=${#apps_arr[@]}
  (( total == 0 )) && return 0
  clear
  printf "\n  ${BOLD}Optional Applications${NC}\n"
  printf "  ${DIM}Pre-install apps · ↑/↓ move · space toggle · a all · Enter (none = skip)${NC}\n\n"
  _hr
  printf "\n"

  MENU_LABELS=(); MENU_DESCS=(); MENU_GROUPS=(); MENU_CHECKED=()
  local def
  for def in "${apps_arr[@]}"; do
    MENU_LABELS+=("$(pf "$def" 2)")
    MENU_DESCS+=("$(pf "$def" 6)")
    MENU_GROUPS+=("$(pf "$def" 3 | tr '[:lower:]' '[:upper:]')")
    MENU_CHECKED+=(0)
  done
  _checkbox_menu

  local i
  for (( i = 0; i < total; i++ )); do
    [[ "${MENU_CHECKED[i]}" == "1" ]] && selected_app_ids+=("$(pf "${apps_arr[i]}" 1)")
  done
  return 0
}

screen_confirm() {
  printf "\n"
  _hr
  printf "\n  ${BOLD}Ready to install.${NC}\n\n"
  local mode_label="Express (all recommended defaults)"
  [[ "$INSTALL_MODE" == "expert" ]] && mode_label="Expert (custom)"
  printf "  Mode     ${C}%s${NC}\n" "$mode_label"
  printf "  Backup   ${DIM}%s${NC}\n" "$($RUN_BACKUP && echo yes || echo no)"
  printf "  Packages ${DIM}%s${NC}\n" "$($RUN_DEPS && echo yes || echo no)"
  printf "  Fonts    ${DIM}%s${NC}\n" "$( $RUN_FONTS && echo yes || echo no)"
  printf "  Apps     ${DIM}%s${NC}\n" "$( (( ${#selected_app_ids[@]} > 0 )) && echo "${#selected_app_ids[@]} selected" || echo none)"
  printf "  Confirm  ${DIM}%s${NC}\n" "$( $CONFIRM_EACH && echo each step || echo no)"
  printf "\n  Press ${BOLD}Enter${NC} to begin, or ${DIM}Ctrl+C${NC} to abort: "
  read -r _
}
