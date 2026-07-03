#!/usr/bin/env bash

if [[ -n "${AURA_INSTALL_CORE_LOADED:-}" ]]; then
  return 0
fi
AURA_INSTALL_CORE_LOADED=1

keep_sudo_alive() {
  while true; do
    sudo -v &>/dev/null; sleep 25
    kill -0 "$$" 2>/dev/null || exit
  done
}

_parse_dep() {
  local entry="$1"
  local cmd="${entry%%=*}"
  local rest="${entry#*=}"
  _dep_pkg="${rest%%:*}"
  local suffix="${rest#"${_dep_pkg}"}"
  _dep_type="aur"
  _dep_version=""
  if [[ "$suffix" == :* ]]; then
    suffix="${suffix#:}"
    _dep_type="${suffix%%@*}"
    if [[ "$suffix" == *@* ]]; then
      _dep_version="${suffix#*@}"
    fi
  elif [[ "$suffix" == *@* ]]; then
    _dep_version="${suffix#*@}"
  fi
  _dep_cmd="$cmd"
}

_check_installed() {
  local pkg="$1" ver="${2:-}"
  if ! pacman -Q "$pkg" &>/dev/null 2>&1; then
    return 1
  fi
  if [[ -z "$ver" ]]; then
    return 0
  fi
  local installed_ver
  installed_ver=$(pacman -Q "$pkg" 2>/dev/null | awk '{print $2}')
  [[ "$installed_ver" == "$ver" ]]
}

validate_sudo() {
  if sudo -n true 2>/dev/null; then
    [[ -z "${SUDO_REFRESH_PID:-}" ]] && { keep_sudo_alive & SUDO_REFRESH_PID=$!; }
    return 0
  fi
  # shellcheck disable=SC2059 — ANSI color variables in format strings are intentional
  printf "\n  ${Y}Sudo required.${NC} Enter your password:\n\n" >/dev/tty
  sudo -v || { _err "Sudo failed. Use --no-deps to skip."; exit 1; }
  [[ -z "${SUDO_REFRESH_PID:-}" ]] && { keep_sudo_alive & SUDO_REFRESH_PID=$!; }
}

install_deps() {
  command -v pacman &>/dev/null || { log_warn "Not Arch — skipping package install"; return; }

  local miss_pac=() miss_aur=() miss_pacman_repo=() AUR_HELPER="" IFS=$'\n'
  for line in $SYSTEM_DEPS; do
    [[ -z "$line" ]] && continue
    local cmd pkg
    cmd="${line%%=*}"
    pkg="${line#*=}"
    if [[ "$cmd" == file:* ]]; then
      test -e "${cmd#file:}" || miss_pac+=("$pkg")
    else
      local pkg_name="${pkg%%@*}"
      local pkg_ver="${pkg#*@}"
      [[ "$pkg_ver" == "$pkg_name" ]] && pkg_ver=""
      if command -v "$cmd" &>/dev/null; then
        if [[ -n "$pkg_ver" ]]; then
          local installed_ver
          installed_ver=$(pacman -Q "$pkg_name" 2>/dev/null | awk '{print $2}' || echo "")
          [[ "$installed_ver" == "$pkg_ver" ]] || miss_pac+=("$pkg")
        fi
      else
        miss_pac+=("$pkg")
      fi
    fi
  done

  for line in $AUR_DEPS; do
    [[ -z "$line" ]] && continue
    _parse_dep "$line"
    command -v "$_dep_cmd" &>/dev/null && continue
    if [[ -n "$_dep_version" ]] && command -v "$_dep_cmd" &>/dev/null; then
      local installed_ver
      installed_ver=$("$_dep_cmd" --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' || echo "")
      [[ "$installed_ver" == "$_dep_version" ]] && continue
    fi
    case "$_dep_type" in
      pacman) miss_pacman_repo+=("$_dep_pkg") ;;
      aur)
        if [[ "$INSTALL_MODE" == "expert" && "$NONINTERACTIVE" != true ]]; then
          # shellcheck disable=SC2059 — ANSI color variables in format strings
          printf "\n  ${Y}?${NC} Install ${W}%s${NC} via AUR (builds from source)? [Y/n] " "$_dep_pkg" >/dev/tty
          read -r _answer </dev/tty
          if [[ "$_answer" =~ ^[Nn] ]]; then
            _info "Skipping $_dep_pkg"
            continue
          fi
        fi
        miss_aur+=("$_dep_pkg")
        ;;
      *) miss_aur+=("$_dep_pkg") ;;
    esac
  done

  for h in yay paru pacman; do command -v "$h" &>/dev/null && { AUR_HELPER="$h"; break; } || true; done
  (( ${#miss_pac[@]} + ${#miss_aur[@]} + ${#miss_pacman_repo[@]} > 0 )) && validate_sudo

  if (( ${#miss_pac[@]} > 0 )); then
    (IFS=' '; log_info "pacman: ${miss_pac[*]}")
    local pac_flags=(-S --needed --noconfirm)
    if [[ "$AUR_HELPER" != "pacman" ]]; then
      case "$AUR_HELPER" in
        yay) pac_flags+=(--answerdiff None --answerclean None) ;;
        paru) pac_flags+=(--skipreview) ;;
      esac
    fi

    _pkgname_from_full() {
      local _full="$1"
      local _try="$1"
      while true; do
        if pacman -Q "$_try" &>/dev/null 2>&1; then
          echo "$_try"; return 0
        fi
        [[ "$_try" != *-* ]] && break
        _try="${_try%-*}"
      done
      echo ""; return 1
    }

    _resolve_conflicts() {
      local _log="$1" _pkg="$2"
      while IFS= read -r _line; do
        [[ "$_line" != ":: "*" are in conflict"* ]] && continue
        local _rest="${_line#:: }"
        local _left="${_rest%% and *}"
        local _right="${_rest#* and }"
        _right="${_right%% are in conflict*}"
        local _other=""
        if [[ "$_left" != "$_pkg-"* ]]; then
          _other="$(_pkgname_from_full "$_left")"
        else
          _other="$(_pkgname_from_full "$_right")"
        fi
        [[ -z "$_other" ]] && continue

        if [[ "$INSTALL_MODE" == "express" ]]; then
          sudo pacman -Rns --noconfirm "$_other" 2>/dev/null || true
          log_info "Removed conflicting $_other"
        else
          log_warn "${_left%%-*} conflicts with $_other"
          # shellcheck disable=SC2059 — ANSI color variables in format strings
          printf "  Remove %s to proceed? ${DIM}[Y/n]${NC}: " "$_other" >/dev/tty </dev/tty
          read -r _r </dev/tty
          if [[ ! "$_r" =~ ^[Nn]$ ]]; then
            sudo pacman -Rns --noconfirm "$_other" 2>/dev/null || true
            log_ok "Removed $_other"
          else
            log_warn "Skipping conflicting package"
            return 1
          fi
        fi
      done <<< "$_log"
      return 0
    }

    local _pkg _errs=0
    for _pkg in "${miss_pac[@]}"; do
      local _pkg_name="${_pkg%%@*}"
      local _pkg_ver="${_pkg#*@}"
      [[ "$_pkg_ver" == "$_pkg_name" ]] && _pkg_ver=""
      local _install_target="$_pkg_name"
      [[ -n "$_pkg_ver" ]] && _install_target="$_pkg_name=$_pkg_ver"
      local _rc=0 _out
      if [[ "$AUR_HELPER" == "pacman" ]]; then
        _out=$(sudo pacman -S --needed --noconfirm "$_install_target" 2>&1) || _rc=$?
      else
        _out=$("$AUR_HELPER" "${pac_flags[@]}" "$_install_target" 2>&1) || _rc=$?
      fi
      if (( _rc != 0 )); then
        if _resolve_conflicts "$_out" "$_pkg_name"; then
          if [[ "$AUR_HELPER" == "pacman" ]]; then
            sudo pacman -S --needed --noconfirm "$_install_target" >/dev/null 2>&1 || { log_err "Package failed: $_pkg"; (( _errs++ )) || true; }
          else
            "$AUR_HELPER" "${pac_flags[@]}" "$_install_target" >/dev/null 2>&1 || { log_err "Package failed: $_pkg"; (( _errs++ )) || true; }
          fi
        else
          log_err "Package failed: $_pkg"
          (( _errs++ )) || true
        fi
      fi
    done
    (( _errs == 0 )) && log_ok "Pacman packages ready" || log_warn "$_errs package(s) failed to install"
  else
    log_ok "System packages up to date"
  fi

  if (( ${#miss_pacman_repo[@]} > 0 )); then
    (IFS=' '; log_info "pacman (official): ${miss_pacman_repo[*]}")
    local pac_flags=(-S --needed --noconfirm)
    local _pkg _errs=0
    for _pkg in "${miss_pacman_repo[@]}"; do
      sudo pacman "${pac_flags[@]}" "$_pkg" >/dev/null 2>&1 || { log_err "Package failed: $_pkg"; (( _errs++ )) || true; }
    done
    (( _errs == 0 )) && log_ok "Official repo packages ready" || log_warn "$_errs package(s) failed to install"
  fi

  if (( ${#miss_aur[@]} > 0 )); then
    if [[ "$AUR_HELPER" == "pacman" ]]; then
      (IFS=' '; log_warn "No AUR helper — install manually: ${miss_aur[*]}")
    else
      (IFS=' '; log_info "AUR: ${miss_aur[*]}")
      local aur_flags=(-S --needed --noconfirm)
      case "$AUR_HELPER" in
        yay) aur_flags+=(--answerdiff None --answerclean None) ;;
        paru) aur_flags+=(--skipreview) ;;
      esac
      local _pkg _errs=0
      for _pkg in "${miss_aur[@]}"; do
        local _pinned_ver=""
        for line in $AUR_DEPS; do
          [[ -z "$line" ]] && continue
          _parse_dep "$line"
          if [[ "$_dep_pkg" == "$_pkg" ]]; then
            _pinned_ver="$_dep_version"
            break
          fi
        done
        if [[ -n "$_pinned_ver" ]]; then
          "$AUR_HELPER" "${aur_flags[@]}" "$_pkg=$_pinned_ver" >/dev/null 2>&1 || { log_err "AUR package failed: $_pkg@$_pinned_ver"; (( _errs++ )) || true; }
        else
          "$AUR_HELPER" "${aur_flags[@]}" "$_pkg" >/dev/null 2>&1 || { log_err "AUR package failed: $_pkg"; (( _errs++ )) || true; }
        fi
      done
      (( _errs == 0 )) && log_ok "AUR packages ready" || log_warn "$_errs AUR package(s) failed to install"
    fi
  else
    log_ok "AUR packages up to date"
  fi
}

install_fonts() {
  if command -v pacman &>/dev/null; then
    local miss_fonts=() AUR_HELPER="" IFS=$'\n'
    for line in ${FONT_DEPS:-}; do
      [[ -z "$line" ]] && continue
      local fname pkg
      fname="${line%%=*}"
      pkg="${line#*=}"
      if command -v fc-list &>/dev/null; then
        fc-list | grep -qi "$fname" || miss_fonts+=("$pkg")
      else
        miss_fonts+=("$pkg")
      fi
    done

    if (( ${#miss_fonts[@]} > 0 )); then
      for h in yay paru; do command -v "$h" &>/dev/null && { AUR_HELPER="$h"; break; } || true; done
      if [[ -n "$AUR_HELPER" ]]; then
        local dedup=()
        for p in "${miss_fonts[@]}"; do
          local seen=false
          for d in "${dedup[@]}"; do [[ "$d" == "$p" ]] && { seen=true; break; } || true; done
          $seen || dedup+=("$p")
        done
        miss_fonts=("${dedup[@]}")
        validate_sudo
        (IFS=' '; log_info "Installing fonts: ${miss_fonts[*]}")
        local aur_flags=(-S --needed --noconfirm)
        case "$AUR_HELPER" in
          yay) aur_flags+=(--answerdiff None --answerclean None) ;;
          paru) aur_flags+=(--skipreview) ;;
        esac
        "$AUR_HELPER" "${aur_flags[@]}" "${miss_fonts[@]}" >/dev/null 2>&1 || { (IFS=' '; log_warn "Font install failed — install manually: ${miss_fonts[*]}"); }
        log_ok "Fonts installed"
      else
        (IFS=' '; log_warn "No AUR helper — install fonts manually: ${miss_fonts[*]}")
      fi
    else
      log_ok "All AUR fonts present"
    fi
  fi

  local sync_script="$REPO_DIR/features/install/sync-fonts.sh"
  if [[ -x "$sync_script" ]]; then
    "$sync_script" >/dev/null 2>&1 || log_warn "sync-fonts.sh had issues"
  fi
  fc-cache -f &>/dev/null || true
  log_ok "Font cache refreshed"
}

# ── Shared package helpers ───────────────────────────────────────────
_find_aur_helper() {
  local h
  for h in yay paru; do command -v "$h" &>/dev/null && { echo "$h"; return 0; }; done
  echo ""; return 1
}

# Install official-repo packages idempotently (--needed skips present ones).
_pacman_install() {
  (( $# > 0 )) || return 0
  sudo pacman -S --needed --noconfirm "$@" >/dev/null 2>&1
}

# Install a mixed repo/aur package list. $1 = "repo"|"aur" tag array via nameref-free args:
# usage: _install_split "context label" repo_pkg1 repo_pkg2 -- aur_pkg1 aur_pkg2
_install_split() {
  local label="$1"; shift
  local repo_pkgs=() aur_pkgs=() cur="repo"
  local a
  for a in "$@"; do
    if [[ "$a" == "--" ]]; then cur="aur"; continue; fi
    if [[ "$cur" == "repo" ]]; then repo_pkgs+=("$a"); else aur_pkgs+=("$a"); fi
  done
  (( ${#repo_pkgs[@]} + ${#aur_pkgs[@]} > 0 )) || { log_info "$label: nothing to install"; return 0; }
  validate_sudo
  if (( ${#repo_pkgs[@]} > 0 )); then
    (IFS=' '; log_info "$label (repo): ${repo_pkgs[*]}")
    local p
    for p in "${repo_pkgs[@]}"; do _pacman_install "$p" || log_warn "Failed: $p"; done
  fi
  if (( ${#aur_pkgs[@]} > 0 )); then
    local helper; helper="$(_find_aur_helper)"
    if [[ -n "$helper" ]]; then
      (IFS=' '; log_info "$label (AUR): ${aur_pkgs[*]}")
      local p
      for p in "${aur_pkgs[@]}"; do "$helper" -S --needed --noconfirm "$p" >/dev/null 2>&1 || log_warn "Failed: $p"; done
    else
      (IFS=' '; log_warn "No AUR helper — install manually: ${aur_pkgs[*]}")
    fi
  fi
  return 0
}

# Wayland screen-sharing stack (portals, qt6-wayland, xwaylandvideobridge for Discord).
install_screenshare() {
  command -v pacman &>/dev/null || { log_warn "Not Arch — skipping screen-share setup"; return 0; }
  local repo_pkgs=() aur_pkgs=() IFS=$'\n'
  local line pkg src
  for line in ${SCREENSHARE_DEPS:-}; do
    [[ -z "$line" ]] && continue
    pkg="${line%%|*}"; src="${line#*|}"
    if [[ "$src" == "aur" ]]; then aur_pkgs+=("$pkg"); else repo_pkgs+=("$pkg"); fi
  done
  _install_split "Screen sharing" "${repo_pkgs[@]}" -- "${aur_pkgs[@]}"
  log_ok "Screen sharing ready (portals + xwaylandvideobridge)"
}

# Autodetect GPU vendor(s) via lspci and install matching driver packages.
install_gpu_drivers() {
  command -v pacman &>/dev/null || { log_warn "Not Arch — skipping GPU drivers"; return 0; }
  command -v lspci &>/dev/null || { log_info "lspci unavailable — skipping GPU autodetect"; return 0; }
  local info; info="$(lspci -nn 2>/dev/null | grep -Ei 'vga|3d|display' || true)"
  local pkgs=() extra
  if grep -qi 'nvidia' <<<"$info"; then
    log_info "NVIDIA GPU detected"
    read -r -a extra <<<"${GPU_NVIDIA:-}"; pkgs+=("${extra[@]}")
  fi
  if grep -qiE 'amd|ati|radeon|advanced micro devices' <<<"$info"; then
    log_info "AMD GPU detected"
    read -r -a extra <<<"${GPU_AMD:-}"; pkgs+=("${extra[@]}")
  fi
  if grep -qi 'intel' <<<"$info"; then
    log_info "Intel GPU detected"
    read -r -a extra <<<"${GPU_INTEL:-}"; pkgs+=("${extra[@]}")
  fi
  (( ${#pkgs[@]} > 0 )) || { log_info "No supported GPU detected — skipping drivers"; return 0; }
  local -A seen=(); local uniq=() p
  for p in "${pkgs[@]}"; do
    [[ -n "${seen[$p]:-}" ]] && continue
    seen[$p]=1; uniq+=("$p")
  done
  _install_split "GPU drivers" "${uniq[@]}" --
  log_ok "GPU drivers ready"
}

# Install user-selected optional applications (expert-mode catalog picks).
install_apps() {
  command -v pacman &>/dev/null || { log_warn "Not Arch — skipping optional apps"; return 0; }
  (( ${#selected_app_ids[@]} > 0 )) || { log_info "No apps selected"; return 0; }
  local repo_pkgs=() aur_pkgs=()
  local want line id pkg src
  for want in "${selected_app_ids[@]}"; do
    local IFS=$'\n'
    for line in ${APPS:-}; do
      [[ -z "$line" ]] && continue
      id="$(pf "$line" 1)"
      [[ "$id" == "$want" ]] || continue
      pkg="$(pf "$line" 4)"; src="$(pf "$line" 5)"
      if pacman -Q "$pkg" &>/dev/null || command -v "$pkg" &>/dev/null; then
        log_info "$pkg already installed"
      elif [[ "$src" == "aur" ]]; then
        aur_pkgs+=("$pkg")
      else
        repo_pkgs+=("$pkg")
      fi
      break
    done
  done
  _install_split "Apps" "${repo_pkgs[@]}" -- "${aur_pkgs[@]}"
  log_ok "Optional applications processed"
}
