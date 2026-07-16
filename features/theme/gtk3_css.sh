#!/usr/bin/env bash
# ── GTK 3 CSS Generator ────────────────────────────────────
# Generates ~/.config/gtk-3.0/gtk.css + settings.ini
# Uses solid hex colors + dual selectors (CSS + Gtk* class names).
# GTK 3 doesn't support @define-color as well as GTK 4, so we use
# both patterns for maximum compatibility (Lutris, Firefox, etc).

generate_gtk3() {
  mkdir -p "$HOME/.config/gtk-3.0"
  cat > "$HOME/.config/gtk-3.0/gtk.css" << EOF
/* ═══════════════════════════════════════════════════════════════
   Color Tokens
   ═══════════════════════════════════════════════════════════════ */
@define-color theme_bg_color ${BG_HEX};
@define-color theme_fg_color ${FG};
@define-color theme_base_color ${BG_HEX};
@define-color theme_text_color ${FG};
@define-color theme_selected_bg_color ${ACCENT};
@define-color theme_selected_fg_color ${WHITE};
@define-color theme_unfocused_base_color ${BG_HEX};
@define-color theme_unfocused_text_color ${MUTED_FG};
@define-color theme_unfocused_selected_bg_color ${ACCENT_BG};
@define-color theme_unfocused_selected_fg_color ${WHITE};

@define-color borders ${BORDER};
@define-color unfocused_borders ${BORDER};
@define-color border_color ${BORDER};

@define-color warning_color #cd9309;
@define-color error_color #c01c28;
@define-color success_color #26a269;

@define-color window_bg_color ${BG_HEX};
@define-color window_fg_color ${FG};
@define-color view_bg_color ${BG_HEX};
@define-color view_fg_color ${FG};
@define-color content_view_bg ${BG_HEX};
@define-color content_view_fg ${FG};

@define-color headerbar_bg_color ${BG_HEX};
@define-color headerbar_fg_color ${FG};
@define-color headerbar_backdrop_color ${BG_HEX};
@define-color headerbar_border_color ${BORDER};
@define-color headerbar_shade_color rgba(0,0,0,0.36);

@define-color sidebar_bg_color ${BG_HEX};
@define-color sidebar_fg_color ${FG};
@define-color sidebar_backdrop_color ${BG_HEX};
@define-color sidebar_border_color ${BORDER};

@define-color card_bg_color ${SURFACE_HEX};
@define-color card_fg_color ${FG};
@define-color card_shade_color rgba(0,0,0,0.25);

@define-color popover_bg_color ${SURFACE_HEX};
@define-color popover_fg_color ${FG};
@define-color menu_bg_color ${SURFACE_HEX};
@define-color menu_fg_color ${FG};

@define-color dialog_bg_color ${BG_HEX};
@define-color dialog_fg_color ${FG};

@define-color accent_bg_color ${ACCENT};
@define-color accent_color ${ACCENT};
@define-color accent_fg_color ${WHITE};

@define-color destructive_bg_color #c01c28;
@define-color destructive_color #c01c28;
@define-color destructive_fg_color ${WHITE};

@define-color success_bg_color #26a269;
@define-color success_color #26a269;
@define-color success_fg_color ${WHITE};

@define-color warning_bg_color #cd9309;
@define-color warning_color #cd9309;
@define-color warning_fg_color rgba(0,0,0,0.8);

@define-color error_bg_color #c01c28;
@define-color error_color #c01c28;
@define-color error_fg_color ${WHITE};

@define-color osd_bg_color ${SURFACE_HEX};
@define-color osd_fg_color ${FG};
@define-color osd_border_color ${BORDER_SUBTLE};

@define-color scrollbar_bg_color ${BORDER};
@define-color scrollbar_slider_color #444444;
@define-color trough_bg_color ${BORDER};
@define-color shade_color rgba(0,0,0,0.25);

@define-color dim_label_color ${DIMMED_FG};

@define-color button_bg_color ${SURFACE_ALT_HEX};
@define-color button_fg_color ${FG};
@define-color button_border_color ${BORDER};

@define-color entry_bg_color ${SURFACE_LOW_HEX};
@define-color entry_fg_color ${FG};
@define-color entry_border_color ${BORDER};

@define-color toolbar_bg_color ${BG_HEX};
@define-color toolbar_fg_color ${FG};

/* ═══════════════════════════════════════════════════════════════
   Global selection
   ═══════════════════════════════════════════════════════════════ */
:selected { background-color: ${ACCENT}; color: ${WHITE}; }
:selected:backdrop { background-color: ${ACCENT_BG}; color: ${WHITE}; }

/* ═══════════════════════════════════════════════════════════════
   Window & background
   ═══════════════════════════════════════════════════════════════ */
GtkWindow {
  background-color: ${BG_HEX};
}
.background {
  background-color: ${BG_HEX};
}

/* ═══════════════════════════════════════════════════════════════
   Headerbar — solid hex, proportional sizing
   ═══════════════════════════════════════════════════════════════ */
.headerbar,
GtkHeaderBar {
  background-color: ${BG_HEX};
  color: ${FG};
  border-bottom: 1px solid ${BORDER};
  background-image: none;
  box-shadow: none;
  min-height: 46px;
  padding: 0 6px;
}
.headerbar:backdrop,
GtkHeaderBar:backdrop {
  background-color: ${BG_HEX};
  color: ${MUTED_FG};
}
.headerbar button,
GtkHeaderBar GtkButton {
  background-color: transparent;
  background-image: none;
  border: none;
  border-radius: ${RADIUS_SM}px;
  color: ${FG};
  padding: 4px 8px;
  min-height: 24px;
  box-shadow: none;
  text-shadow: none;
  icon-shadow: none;
}
.headerbar button:hover,
GtkHeaderBar GtkButton:hover {
  background-color: ${SURFACE_HOVER_HEX};
}
.headerbar button:active,
GtkHeaderBar GtkButton:active {
  background-color: ${SURFACE_ALT_HEX};
}
.headerbar button:checked,
GtkHeaderBar GtkButton:checked {
  background-color: ${ACCENT_BG};
  color: ${WHITE};
}
.headerbar GtkEntry,
GtkHeaderBar entry {
  background-color: ${SURFACE_LOW_HEX};
  color: ${FG};
  border: 1px solid ${BORDER};
  border-radius: ${RADIUS_SM}px;
  background-image: none;
  box-shadow: none;
}
.headerbar GtkEntry:focus,
GtkHeaderBar entry:focus {
  border-color: ${ACCENT};
}

/* ═══════════════════════════════════════════════════════════════
   Sidebar — Lutris left panel
   ═══════════════════════════════════════════════════════════════ */
.sidebar,
GtkSidebar {
  background-color: ${BG_HEX};
  color: ${FG};
  border-right: 1px solid ${BORDER};
}
.sidebar .list-row,
GtkSidebar .list-row {
  background-color: transparent;
  color: ${FG};
  padding: 6px 10px;
}
.sidebar .list-row:hover,
GtkSidebar .list-row:hover {
  background-color: ${SURFACE_HOVER_HEX};
}
.sidebar .list-row:selected,
GtkSidebar .list-row:selected {
  background-color: ${ACCENT_BG};
  color: ${WHITE};
}
.sidebar .list-row:selected:hover,
GtkSidebar .list-row:selected:hover {
  background-color: ${ACCENT};
}

/* ═══════════════════════════════════════════════════════════════
   Buttons — proportional sizing matching adw-gtk3 proportions
   ═══════════════════════════════════════════════════════════════ */
button,
GtkButton {
  background-color: ${SURFACE_ALT_HEX};
  background-image: none;
  color: ${FG};
  border: 1px solid ${BORDER};
  border-radius: ${RADIUS_SM}px;
  padding: 4px 10px;
  min-height: 24px;
  min-width: 16px;
  box-shadow: none;
  text-shadow: none;
  icon-shadow: none;
}

/* Linked button groups — buttons stuck together in a row */
.linked > button,
.linked > entry,
.linked > spinbutton {
  border-left-color: alpha(currentColor,0.15);
  border-right-color: alpha(currentColor,0.15);
  border-right-style: none;
  border-radius: 0;
}
.linked > button:first-child,
.linked > entry:first-child {
  border-left-color: transparent;
  border-top-left-radius: ${RADIUS_SM}px;
  border-bottom-left-radius: ${RADIUS_SM}px;
}
.linked > button:last-child,
.linked > entry:last-child {
  border-right-color: transparent;
  border-right-style: solid;
  border-top-right-radius: ${RADIUS_SM}px;
  border-bottom-right-radius: ${RADIUS_SM}px;
}
.linked > button:only-child {
  border-style: solid;
  border-radius: ${RADIUS_SM}px;
}
button:hover,
GtkButton:hover {
  background-color: ${SURFACE_HOVER_HEX};
  border-color: ${BORDER_SUBTLE};
}
button:active,
GtkButton:active {
  background-color: ${SURFACE_HEX};
  border-color: ${BORDER};
}
button:checked,
GtkButton:checked {
  background-color: ${ACCENT_BG};
  color: ${WHITE};
  border-color: ${ACCENT_BG};
}
button:checked:hover,
GtkButton:checked:hover {
  background-color: ${ACCENT};
}
button:disabled,
GtkButton:disabled {
  background-color: ${SURFACE_LOW_HEX};
  color: ${DIMMED_FG};
  border-color: ${BORDER};
}
button.flat,
GtkButton.flat {
  background-color: transparent;
  background-image: none;
  border-color: transparent;
  box-shadow: none;
}
button.flat:hover,
GtkButton.flat:hover {
  background-color: ${SURFACE_HOVER_HEX};
}
button.flat:active,
GtkButton.flat:active {
  background-color: ${SURFACE_ALT_HEX};
}
button.flat:checked,
GtkButton.flat:checked {
  background-color: ${ACCENT_BG};
  color: ${WHITE};
}
button.suggested-action,
GtkButton.suggested-action {
  background-color: ${ACCENT};
  color: ${WHITE};
  border-color: ${ACCENT};
  background-image: none;
}
button.suggested-action:hover,
GtkButton.suggested-action:hover {
  background-color: ${ACCENT_HOVER};
}
button.destructive-action,
GtkButton.destructive-action {
  background-color: #c01c28;
  color: ${WHITE};
  border-color: #c01c28;
  background-image: none;
}

/* ═══════════════════════════════════════════════════════════════
   Entries — proportional sizing
   ═══════════════════════════════════════════════════════════════ */
entry,
GtkEntry {
  background-color: ${SURFACE_LOW_HEX};
  color: ${FG};
  border: 1px solid ${BORDER};
  border-radius: ${RADIUS_SM}px;
  padding: 4px 10px;
  min-height: 24px;
  background-image: none;
  box-shadow: none;
}
entry:focus,
GtkEntry:focus {
  border-color: ${ACCENT};
  box-shadow: inset 0 0 0 1px ${ACCENT};
}
entry:disabled,
GtkEntry:disabled {
  background-color: ${SURFACE_LOW_HEX};
  color: ${DIMMED_FG};
}
entry selection,
GtkEntry selection {
  background-color: ${ACCENT};
  color: ${WHITE};
}
GtkTextView, textview {
  background-color: ${SURFACE_LOW_HEX};
  color: ${FG};
}
GtkTextView text,
textview text {
  background-color: ${SURFACE_LOW_HEX};
  color: ${FG};
}

/* ═══════════════════════════════════════════════════════════════
   Lists — Lutris game list view, proportional spacing
   ═══════════════════════════════════════════════════════════════ */
.list, GtkListBox {
  background-color: ${BG_HEX};
}
.list-row, GtkListBoxRow {
  background-color: ${BG_HEX};
  color: ${FG};
  padding: 6px 10px;
  min-height: 24px;
  border: none;
  box-shadow: none;
}
.list-row:hover, GtkListBoxRow:hover {
  background-color: ${SURFACE_HOVER_HEX};
}
.list-row:selected, GtkListBoxRow:selected {
  background-color: ${ACCENT_BG};
  color: ${WHITE};
}
.list-row:selected:hover, GtkListBoxRow:selected:hover {
  background-color: ${ACCENT};
}

/* ═══════════════════════════════════════════════════════════════
   Icon view — Lutris game grid view
   ═══════════════════════════════════════════════════════════════ */
GtkIconView {
  background-color: ${BG_HEX};
  color: ${FG};
}
GtkIconView.view.cell {
  background-color: ${SURFACE_HEX};
  border: 1px solid ${BORDER};
  border-radius: ${RADIUS_MD}px;
  padding: 4px;
}
GtkIconView.view.cell:hover {
  background-color: ${SURFACE_HOVER_HEX};
  border-color: ${BORDER_SUBTLE};
}
GtkIconView.view.cell:selected {
  background-color: ${ACCENT_BG};
  border-color: ${ACCENT};
  color: ${WHITE};
}
GtkIconView.view.cell:selected:hover {
  background-color: ${ACCENT};
}

/* ═══════════════════════════════════════════════════════════════
   Tree view
   ═══════════════════════════════════════════════════════════════ */
GtkTreeView {
  background-color: ${BG_HEX};
  color: ${FG};
  border: 1px solid ${BORDER};
}
GtkTreeView.view {
  background-color: ${BG_HEX};
  color: ${FG};
}
GtkTreeView row {
  background-color: ${BG_HEX};
  color: ${FG};
  padding: 2px 4px;
  border: none;
}
GtkTreeView row:hover {
  background-color: ${SURFACE_HOVER_HEX};
}
GtkTreeView row:selected {
  background-color: ${ACCENT_BG};
  color: ${WHITE};
}
GtkTreeView row:selected:hover {
  background-color: ${ACCENT};
}
GtkTreeView row:nth-child(even) {
  background-color: ${SURFACE_LOW_HEX};
}
GtkTreeView row:nth-child(even):hover {
  background-color: ${SURFACE_HOVER_HEX};
}
GtkTreeView header button {
  background-color: ${SURFACE_ALT_HEX};
  background-image: none;
  border: none;
  border-bottom: 1px solid ${BORDER};
  border-radius: 0;
  color: ${DIMMED_FG};
  padding: 4px 8px;
}
GtkTreeView header button:hover {
  background-color: ${SURFACE_HOVER_HEX};
  color: ${FG};
}

/* ═══════════════════════════════════════════════════════════════
   Toolbar
   ═══════════════════════════════════════════════════════════════ */
GtkToolbar, .toolbar {
  background-color: ${BG_HEX};
  border-bottom: 1px solid ${BORDER};
  background-image: none;
  padding: 4px;
}
GtkToolbar button, .toolbar button {
  background-color: transparent;
  background-image: none;
  border: none;
  border-radius: ${RADIUS_SM}px;
  padding: 4px 8px;
  color: ${FG};
  box-shadow: none;
  text-shadow: none;
}
GtkToolbar button:hover, .toolbar button:hover {
  background-color: ${SURFACE_HOVER_HEX};
}
GtkToolbar button:active, .toolbar button:active {
  background-color: ${SURFACE_ALT_HEX};
}
GtkToolbar button:checked, .toolbar button:checked {
  background-color: ${ACCENT_BG};
  color: ${WHITE};
}

/* ═══════════════════════════════════════════════════════════════
   Notebook / tabs
   ═══════════════════════════════════════════════════════════════ */
GtkNotebook {
  background-color: ${BG_HEX};
}
GtkNotebook tab {
  background-color: transparent;
  color: ${DIMMED_FG};
  border: none;
  border-bottom: 2px solid transparent;
  border-radius: 0;
  padding: 8px 16px;
}
GtkNotebook tab:hover {
  background-color: ${SURFACE_HOVER_HEX};
  color: ${FG};
}
GtkNotebook tab:checked {
  background-color: transparent;
  color: ${FG};
  border-bottom-color: ${ACCENT};
}

/* ═══════════════════════════════════════════════════════════════
   Switch
   ═══════════════════════════════════════════════════════════════ */
switch, GtkSwitch {
  background-color: ${BORDER_SUBTLE};
  border: 1px solid ${BORDER};
  border-radius: 12px;
}
switch:hover, GtkSwitch:hover {
  background-color: ${SURFACE_HOVER_HEX};
}
switch:checked, GtkSwitch:checked {
  background-color: ${ACCENT};
  border-color: ${ACCENT};
}
switch slider, GtkSwitch GtkImage {
  background-color: ${FG};
  border: none;
  box-shadow: 0 1px 3px rgba(0,0,0,0.3);
}
switch:checked slider, GtkSwitch:checked GtkImage {
  background-color: ${WHITE};
}

/* ═══════════════════════════════════════════════════════════════
   Scale / slider
   ═══════════════════════════════════════════════════════════════ */
scale trough, GtkScale trough {
  background-color: ${BORDER};
  border-radius: 4px;
  min-height: 4px;
}
scale trough highlight, GtkScale trough highlight {
  background-color: ${ACCENT};
  border-radius: 4px;
}
scale slider, GtkScale slider {
  background-color: ${FG};
  border: none;
  border-radius: 10px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.3);
  min-width: 18px;
  min-height: 18px;
}
scale slider:hover, GtkScale slider:hover {
  background-color: ${WHITE};
}

/* ═══════════════════════════════════════════════════════════════
   Scrollbar
   ═══════════════════════════════════════════════════════════════ */
scrollbar, GtkScrollbar {
  background-color: transparent;
}
scrollbar trough, GtkScrollbar trough {
  background-color: transparent;
}
scrollbar slider, GtkScrollbar slider {
  background-color: #444444;
  border-radius: ${RADIUS_SM}px;
  min-width: 6px;
  min-height: 6px;
  margin: 3px;
  border: none;
}
scrollbar:hover trough, GtkScrollbar:hover trough {
  background-color: ${BORDER};
}
scrollbar:hover slider, GtkScrollbar:hover slider {
  background-color: #555555;
}
scrollbar slider:active, GtkScrollbar slider:active {
  background-color: ${ACCENT};
}

/* ═══════════════════════════════════════════════════════════════
   Progress bar
   ═══════════════════════════════════════════════════════════════ */
GtkProgressBar trough {
  background-color: ${BORDER};
  border-radius: ${RADIUS_SM}px;
  min-height: 4px;
}
GtkProgressBar trough progress {
  background-color: ${ACCENT};
  border-radius: ${RADIUS_SM}px;
}

/* ═══════════════════════════════════════════════════════════════
   Popover & menu
   ═══════════════════════════════════════════════════════════════ */
GtkPopover, .popover {
  background-color: ${SURFACE_HEX};
  color: ${FG};
  border: 1px solid ${BORDER};
  border-radius: ${RADIUS_MD}px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.3);
}
GtkMenu, menu {
  background-color: ${SURFACE_HEX};
  color: ${FG};
  border: 1px solid ${BORDER};
  border-radius: ${RADIUS_MD}px;
  padding: 4px;
}
GtkMenu menuitem, menu menuitem {
  border-radius: ${RADIUS_SM}px;
  padding: 4px 24px 4px 8px;
  margin: 1px 2px;
}
GtkMenu menuitem:hover, menu menuitem:hover {
  background-color: ${SURFACE_HOVER_HEX};
}
GtkMenu menuitem:selected, menu menuitem:selected {
  background-color: ${ACCENT_BG};
  color: ${WHITE};
}

/* ═══════════════════════════════════════════════════════════════
   Tooltip
   ═══════════════════════════════════════════════════════════════ */
GtkTooltip, .tooltip {
  background-color: ${SURFACE_HEX};
  color: ${FG};
  border: 1px solid ${BORDER_SUBTLE};
  border-radius: ${RADIUS_SM}px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.3);
  padding: 4px 8px;
}

/* ═══════════════════════════════════════════════════════════════
   CSD window frames — strip decorations for tiling WM
   CRITICAL: adw-gtk3-dark sets window.csd > .titlebar:not(headerbar)
   to transparent. Firefox/Lutris use .titlebar WITHOUT headerbar
   inside, so they get the transparent override. We MUST override
   this or the titlebar stays invisible.
   ═══════════════════════════════════════════════════════════════ */
.window-frame, .window-frame:backdrop {
  box-shadow: 0 0 0 black;
  border-style: none;
  margin: 0;
  border-radius: 0;
}
.titlebar {
  border-radius: 0;
}

/* Override adw-gtk3-dark's transparent titlebar for CSD windows.
   This is what Firefox, Lutris, and other GTK3 CSD apps need. */
window.csd > .titlebar:not(headerbar),
window.csd > .titlebar:not(headerbar):backdrop {
  background-color: ${BG_HEX};
  background-image: none;
  border-style: none;
  border-color: transparent;
  box-shadow: none;
}

/* Also ensure headerbar itself stays solid */
headerbar,
headerbar:backdrop {
  background-color: ${BG_HEX};
  background-image: none;
}

/* Fallback: ensure window content is solid */
.background {
  background-color: ${BG_HEX};
}
EOF

  cp "$HOME/.config/gtk-3.0/gtk.css" "$THEME_DIR/gtk-3.0/gtk.css"
  echo "[gtk-qt-theme] GTK 3: CSS generated"

  cat > "$HOME/.config/gtk-3.0/settings.ini" << EOF
[Settings]
gtk-theme-name=${APP_THEME_KEY}
gtk-icon-theme-name=Papirus-Dark
gtk-application-prefer-dark-theme=1
gtk-font-name=${FONT_SANS} 10
gtk-cursor-theme-name=default
EOF

  mkdir -p "$HOME/.config/gtk-4.0"
  cp "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"
}
