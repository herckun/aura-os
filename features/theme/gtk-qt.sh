#!/usr/bin/env bash
# ── GTK(2/3/4) + Qt Theme Generator ──────────────────────
# Main orchestrator — sources shared vars, calls each generator.
#
# Architecture:
#   _lib.sh        — Shared color computation (sourced)
#   gtk4_css.sh    — GTK 4 CSS (headerbar solid, content translucent)
#   gtk3_css.sh    — GTK 3 CSS + settings.ini (solid hex, dual selectors)
#   gtk2_gtkrc.sh  — GTK 2 gtkrc (pixmap engine)
#   kvantum_theme.sh — Kvantum SVG + kvconfig (Qt theme)
#   kde_scheme.sh  — KDE color scheme + kdeglobals
#
# Usage: gtk-qt.sh '<json_blob>'
# JSON keys: accent, shellMode, transparency, animations, monochrome, blur

set -euo pipefail

# Default to empty JSON object if no argument provided
DEFAULT_JSON='{}'
INPUT_JSON="${1:-$DEFAULT_JSON}"

# Export for _lib.sh to resolve theme_lib.py
export _GTKQT_CALLER="${BASH_SOURCE[0]}"

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

# ── Source shared color computation ─────────────────────────
# shellcheck source=/dev/null
source "$SCRIPT_DIR/_lib.sh"

# ── Source all generators ───────────────────────────────────
# shellcheck source=/dev/null
source "$SCRIPT_DIR/gtk4_css.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/gtk3_css.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/gtk2_gtkrc.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/kvantum_theme.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/kde_scheme.sh"

# ═══════════════════════════════════════════════════════════════
# Theme directory — registers as a proper GTK theme
# ═══════════════════════════════════════════════════════════════
mkdir -p "$THEME_DIR/gtk-3.0" "$THEME_DIR/gtk-4.0"

cat > "$THEME_DIR/index.theme" << THMEOF
[GTK Theme]
Name=${APP_THEME_KEY}
Comment=${APP_DISPLAY} — dark monochrome theme
Encoding=UTF-8
Inherits=adw-gtk3-dark,Adwaita
THMEOF

# ═══════════════════════════════════════════════════════════════
# Generate all themes
# ═══════════════════════════════════════════════════════════════
generate_gtk4
generate_gtk3
generate_gtk2
generate_kvantum
generate_kde

# ═══════════════════════════════════════════════════════════════
# GSettings + xsettingsd + GTK4 CSS reload
# ═══════════════════════════════════════════════════════════════
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null || true

# Force GTK4 to reload CSS by toggling the theme away and back.
# GTK4 caches CSS at startup — the toggle invalidates the cache.
_current_gtk_theme="$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo "")"
if [[ "$_current_gtk_theme" == "'${APP_THEME_KEY}'" ]]; then
  gsettings set org.gnome.desktop.interface gtk-theme "Adwaita" 2>/dev/null || true
  sleep 1
fi
gsettings set org.gnome.desktop.interface gtk-theme "${APP_THEME_KEY}" 2>/dev/null || true
sleep 0.5

# Touch the CSS files to update mtime — some GTK4 builds watch for changes
touch "$HOME/.config/gtk-4.0/gtk.css" 2>/dev/null || true

gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark" 2>/dev/null || true
gsettings set org.gnome.desktop.interface font-name "${FONT_SANS} 10" 2>/dev/null || true
gsettings set org.gnome.desktop.interface monospace-font-name "${FONT_MONO} 10" 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-theme "default" 2>/dev/null || true

mkdir -p "$HOME/.config/xsettingsd"
cat > "$HOME/.config/xsettingsd/xsettingsd.conf" << XSHEOF
Net/ThemeName "${APP_THEME_KEY}"
Net/IconThemeName "Papirus-Dark"
Gtk/ColorScheme "prefer-dark"
XSHEOF

if pgrep -x xsettingsd &>/dev/null; then
  pkill -SIGHUP -x xsettingsd 2>/dev/null || true
fi

# ═══════════════════════════════════════════════════════════════
# qt6ct — rebrand color scheme if old name exists
# ═══════════════════════════════════════════════════════════════
QT6CT_CONF="$HOME/.config/qt6ct/qt6ct.conf"
QT6CT_COLORS="$HOME/.config/qt6ct/colors"
if [[ -d "$QT6CT_COLORS" ]]; then
  for f in "$QT6CT_COLORS"/*aura*.conf; do
    [[ -f "$f" ]] || continue
    base="$(basename "$f")"
    [[ "$base" == "${APP_THEME_KEY}.conf" ]] && continue
    mv "$f" "$QT6CT_COLORS/${APP_THEME_KEY}.conf"
  done
fi
if [[ -f "$QT6CT_CONF" ]]; then
  sed -i "s|color_scheme_path = .*|color_scheme_path = ${QT6CT_COLORS}/${APP_THEME_KEY}.conf|" "$QT6CT_CONF" 2>/dev/null || true
  sed -i "s|palette = .*|palette = ${APP_THEME_KEY}|" "$QT6CT_CONF" 2>/dev/null || true
fi

# ═══════════════════════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════════════════════
echo "[gtk-qt-theme] Done — all themes generated from ${ACCENT}"
echo "[gtk-qt-theme] GTK 2/3/4: headerbar solid, content translucent for blur"
echo "[gtk-qt-theme] Qt: Kvantum ${APP_DISPLAY} theme (colors match GTK)"
echo "[gtk-qt-theme] Icons: Papirus-Dark"

# ── Live reload ─────────────────────────────────────────────
if command -v kvantummanager &>/dev/null && pgrep -x kvantummanager &>/dev/null; then
  kvantummanager --set "${APP_DISPLAY}" 2>/dev/null && \
    echo "[gtk-qt-theme] Kvantum: reloaded" || true
fi

if pgrep -x xsettingsd &>/dev/null; then
  pkill -SIGHUP -x xsettingsd 2>/dev/null && \
    echo "[gtk-qt-theme] xsettingsd: reloaded" || true
fi

echo "[gtk-qt-theme]"
echo "[gtk-qt-theme] Some apps may need restart. Flatpak: run"
echo "[gtk-qt-theme]   flatpak override --user --filesystem=xdg-config/gtk-3.0:ro"
echo "[gtk-qt-theme]   flatpak override --user --filesystem=xdg-config/gtk-4.0:ro"
