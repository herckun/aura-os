#!/usr/bin/env bash
# ── GTK 2 gtkrc Generator ──────────────────────────────────
# Generates ~/.config/gtk-2.0/gtkrc with pixmap engine.
# GTK 2 doesn't support CSS — uses traditional property assignments.

generate_gtk2() {
  mkdir -p "$HOME/.config/gtk-2.0"
  cat > "$HOME/.config/gtk-2.0/gtkrc" << EOF
gtk-theme-name = "${APP_THEME_KEY}"
gtk-icon-theme-name = "Papirus-Dark"
gtk-font-name = "${FONT_SANS} 10"
gtk-cursor-theme-name = "default"

style "${APP_THEME_KEY}-default" {
  bg[NORMAL]      = "${BG_HEX}"
  bg[ACTIVE]      = "${SURFACE_ALT_HEX}"
  bg[PRELIGHT]    = "${SURFACE_HOVER_HEX}"
  bg[SELECTED]    = "${ACCENT}"
  bg[INSENSITIVE] = "${SURFACE_LOW_HEX}"

  fg[NORMAL]      = "${FG}"
  fg[ACTIVE]      = "${FG}"
  fg[PRELIGHT]    = "${WHITE}"
  fg[SELECTED]    = "${WHITE}"
  fg[INSENSITIVE] = "${DIMMED_FG}"

  text[NORMAL]    = "${FG}"
  text[ACTIVE]    = "${FG}"
  text[PRELIGHT]  = "${WHITE}"
  text[SELECTED]  = "${WHITE}"
  text[INSENSITIVE]= "${DIMMED_FG}"

  base[NORMAL]    = "${SURFACE_LOW_HEX}"
  base[ACTIVE]    = "${SURFACE_ALT_HEX}"
  base[PRELIGHT]  = "${SURFACE_HOVER_HEX}"
  base[SELECTED]  = "${ACCENT}"
  base[INSENSITIVE]= "${SURFACE_LOW_HEX}"

  engine "pixmap" {}
}

style "${APP_THEME_KEY}-tooltips" = "${APP_THEME_KEY}-default" {
  bg[NORMAL] = "${SURFACE_HEX}"
  fg[NORMAL] = "${FG}"
}

style "${APP_THEME_KEY}-scrollbar" = "${APP_THEME_KEY}-default" {
  bg[NORMAL]      = "${BORDER}"
  bg[PRELIGHT]    = "#555555"
  bg[ACTIVE]      = "${ACCENT}"
}

widget_class "*"            style "${APP_THEME_KEY}-default"
widget_class "*.GtkTooltip" style "${APP_THEME_KEY}-tooltips"
widget_class "*.GtkScrollbar*" style "${APP_THEME_KEY}-scrollbar"
EOF

  mkdir -p "$THEME_DIR/gtk-2.0"
  cp "$HOME/.config/gtk-2.0/gtkrc" "$THEME_DIR/gtk-2.0/gtkrc"
  echo "[gtk-qt-theme] GTK 2: gtkrc generated"
}
