#!/usr/bin/env bash
# ── GTK 4 CSS Generator ────────────────────────────────────
# Generates ~/.config/gtk-4.0/gtk.css
# Imports adw-gtk3-dark base then overrides with our color tokens.
#
# Key: headerbar uses SOLID hex (BG_HEX), not rgba.
# Content area uses rgba for blur effect.
# This matches how Colloid/adw-gtk3 handle headerbar transparency.

generate_gtk4() {
  mkdir -p "$HOME/.config/gtk-4.0"
  cat > "$HOME/.config/gtk-4.0/gtk.css" << EOF
@import url('${ADW_GTK4_DIR}/gtk.css');

/* ═══════════════════════════════════════════════════════════════
   Color Tokens — override every libadwaita semantic color
   ═══════════════════════════════════════════════════════════════ */

/* Core palette */
@define-color theme_bg_color ${BG};
@define-color theme_fg_color ${FG};
@define-color theme_base_color ${BG};
@define-color theme_text_color ${FG};
@define-color theme_selected_bg_color ${ACCENT};
@define-color theme_selected_fg_color ${WHITE};
@define-color theme_unfocused_base_color ${BG};
@define-color theme_unfocused_text_color ${MUTED_FG};
@define-color theme_unfocused_selected_bg_color ${ACCENT_BG};
@define-color theme_unfocused_selected_fg_color ${WHITE};

/* Borders */
@define-color borders ${BORDER};
@define-color unfocused_borders ${BORDER};
@define-color border_color ${BORDER};

/* Semantic colors */
@define-color warning_color #cd9309;
@define-color error_color #c01c28;
@define-color success_color #26a269;
@define-color destructive_color #c01c28;

/* Window chrome */
@define-color window_bg_color ${BG};
@define-color window_fg_color ${FG};
@define-color window_border_color ${BORDER};

/* View / content area — uses rgba for blur */
@define-color view_bg_color ${BG};
@define-color view_fg_color ${FG};
@define-color content_view_bg ${BG};
@define-color content_view_fg ${FG};

/* Headerbar — SOLID hex for crisp decoration (no CSS alpha) */
@define-color headerbar_bg_color ${BG_HEADERBAR};
@define-color headerbar_fg_color ${FG};
@define-color headerbar_backdrop_color ${BG_HEADERBAR};
@define-color headerbar_border_color ${BORDER};
@define-color headerbar_shade_color rgba(0,0,0,0.36);

/* Sidebar */
@define-color sidebar_bg_color ${BG};
@define-color sidebar_fg_color ${FG};
@define-color sidebar_backdrop_color ${BG};
@define-color sidebar_border_color ${BORDER};
@define-color sidebar_shade_color rgba(0,0,0,0.25);

/* Secondary sidebar */
@define-color secondary_sidebar_bg_color ${BG};
@define-color secondary_sidebar_fg_color ${FG};
@define-color secondary_sidebar_backdrop_color ${BG};
@define-color secondary_sidebar_border_color ${BORDER};

/* Cards & elevated surfaces */
@define-color card_bg_color ${SURFACE};
@define-color card_fg_color ${FG};
@define-color card_shade_color rgba(0,0,0,0.25);

/* Popovers & menus — should be nearly solid */
@define-color popover_bg_color ${SURFACE};
@define-color popover_fg_color ${FG};
@define-color popover_shade_color rgba(0,0,0,0.25);
@define-color menu_bg_color ${SURFACE};
@define-color menu_fg_color ${FG};

/* Dialogs */
@define-color dialog_bg_color ${BG};
@define-color dialog_fg_color ${FG};
@define-color dialog_border_color ${BORDER};

/* Accent */
@define-color accent_bg_color ${ACCENT};
@define-color accent_color ${ACCENT};
@define-color accent_fg_color ${WHITE};

/* Destructive */
@define-color destructive_bg_color #c01c28;
@define-color destructive_fg_color ${WHITE};

/* Success */
@define-color success_bg_color #26a269;
@define-color success_color #26a269;
@define-color success_fg_color ${WHITE};

/* Warning */
@define-color warning_bg_color #cd9309;
@define-color warning_color #cd9309;
@define-color warning_fg_color rgba(0,0,0,0.8);

/* Error */
@define-color error_bg_color #c01c28;
@define-color error_color #c01c28;
@define-color error_fg_color ${WHITE};

/* OSD */
@define-color osd_bg_color ${SURFACE};
@define-color osd_fg_color ${FG};
@define-color osd_border_color ${BORDER_SUBTLE};
@define-color osd_shade_color rgba(0,0,0,0.4);

/* Scrollbar */
@define-color scrollbar_bg_color ${BORDER};
@define-color scrollbar_slider_color #444444;
@define-color scrollbar_slider_hover_color #555555;
@define-color scrollbar_slider_active_color ${ACCENT};
@define-color trough_bg_color ${BORDER};

@define-color shade_color rgba(0,0,0,0.25);
@define-color dim_label_color ${DIMMED_FG};

@define-color button_bg_color ${SURFACE_ALT};
@define-color button_fg_color ${FG};
@define-color button_border_color ${BORDER};

@define-color entry_bg_color ${SURFACE_LOW};
@define-color entry_fg_color ${FG};
@define-color entry_border_color ${BORDER};

@define-color toolbar_bg_color ${BG};
@define-color toolbar_fg_color ${FG};

/* ═══════════════════════════════════════════════════════════════
   :root custom properties (libadwaita 1.4+ reads these)
   ═══════════════════════════════════════════════════════════════ */
:root {
  --window-bg-color: ${BG};
  --window-fg-color: ${FG};
  --view-bg-color: ${BG};
  --view-fg-color: ${FG};
  --headerbar-bg-color: ${BG_HEADERBAR};
  --headerbar-fg-color: ${FG};
  --headerbar-backdrop-color: ${BG_HEADERBAR};
  --headerbar-border-color: ${BORDER};
  --sidebar-bg-color: ${BG};
  --sidebar-fg-color: ${FG};
  --sidebar-backdrop-color: ${BG};
  --sidebar-border-color: ${BORDER};
  --secondary-sidebar-bg-color: ${BG};
  --secondary-sidebar-fg-color: ${FG};
  --card-bg-color: ${SURFACE};
  --card-fg-color: ${FG};
  --card-shade-color: rgba(0,0,0,0.25);
  --popover-bg-color: ${SURFACE};
  --popover-fg-color: ${FG};
  --dialog-bg-color: ${BG};
  --dialog-fg-color: ${FG};
  --accent-bg-color: ${ACCENT};
  --accent-color: ${ACCENT};
  --accent-fg-color: ${WHITE};
  --destructive-bg-color: #c01c28;
  --destructive-fg-color: ${WHITE};
  --success-bg-color: #26a269;
  --success-fg-color: ${WHITE};
  --warning-bg-color: #cd9309;
  --warning-fg-color: rgba(0,0,0,0.8);
  --error-bg-color: #c01c28;
  --error-fg-color: ${WHITE};
  --border-color: ${BORDER};
  --dim-label-color: ${DIMMED_FG};
  --scrollbar-bg-color: ${BORDER};
  --scrollbar-slider-color: #444444;
  --osd-bg-color: ${SURFACE};
  --osd-fg-color: ${FG};
  --menu-bg-color: ${SURFACE};
  --menu-fg-color: ${FG};
  --toolbar-bg-color: ${BG};
  --toolbar-fg-color: ${FG};
}

/* ═══════════════════════════════════════════════════════════════
   Window & background
   ═══════════════════════════════════════════════════════════════ */
window.background {
  background-color: ${BG};
}

/* ═══════════════════════════════════════════════════════════════
   Headerbar — SOLID hex, proportional sizing
   ═══════════════════════════════════════════════════════════════ */
headerbar {
  background-color: ${BG_HEADERBAR};
  color: ${FG};
  border-bottom: 1px solid ${BORDER};
  min-height: 47px;
  padding: 0 ${SPACING_SM}px;
}
headerbar:backdrop {
  background-color: ${BG_HEADERBAR};
  color: ${MUTED_FG};
}
headerbar button {
  background-color: transparent;
  background-image: none;
  border: none;
  border-radius: ${RADIUS_SM}px;
  color: ${FG};
  padding: 4px 10px;
  min-height: 24px;
  min-width: 16px;
  margin: 2px;
}
headerbar button:hover {
  background-color: ${SURFACE_HOVER};
}
headerbar button:active {
  background-color: ${SURFACE_ALT};
}
headerbar button:checked {
  background-color: ${ACCENT_BG};
  color: ${WHITE};
}
headerbar entry {
  background-color: ${SURFACE_LOW};
  color: ${FG};
  border: 1px solid ${BORDER};
  border-radius: ${RADIUS_SM}px;
  padding: 4px 10px;
  min-height: 24px;
}
headerbar entry:focus {
  border-color: ${ACCENT};
  box-shadow: inset 0 0 0 1px ${ACCENT};
}

/* ═══════════════════════════════════════════════════════════════
   Sidebar
   ═══════════════════════════════════════════════════════════════ */
.sidebar,
.navigation-sidebar {
  background-color: ${BG};
  color: ${FG};
  border-right: 1px solid ${BORDER};
}
.sidebar:backdrop,
.navigation-sidebar:backdrop {
  background-color: ${BG};
}
.sidebar .list-row:hover,
.navigation-sidebar .list-row:hover {
  background-color: ${SURFACE_HOVER};
}
.sidebar .list-row:selected,
.navigation-sidebar .list-row:selected {
  background-color: ${ACCENT_BG};
  color: ${WHITE};
}

/* ═══════════════════════════════════════════════════════════════
   Cards
   ═══════════════════════════════════════════════════════════════ */
.card {
  background-color: ${SURFACE};
  color: ${FG};
  border: 1px solid ${BORDER};
  border-radius: ${RADIUS_MD}px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.15);
}

/* ═══════════════════════════════════════════════════════════════
   Buttons — proportional sizing matching adw-gtk3 proportions
   ═══════════════════════════════════════════════════════════════ */
button {
  background-color: ${SURFACE_ALT};
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

/* Linked button groups */
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
button:hover {
  background-color: ${SURFACE_HOVER};
  border-color: ${BORDER_SUBTLE};
}
button:active {
  background-color: ${SURFACE};
  border-color: ${BORDER};
}
button:checked {
  background-color: ${ACCENT_BG};
  color: ${WHITE};
  border-color: ${ACCENT_BG};
}
button:checked:hover {
  background-color: ${ACCENT};
  color: ${WHITE};
}
button:disabled {
  background-color: ${SURFACE_LOW};
  color: ${DIMMED_FG};
  border-color: ${BORDER};
}
button.flat {
  background-color: transparent;
  background-image: none;
  border-color: transparent;
  box-shadow: none;
}
button.flat:hover {
  background-color: ${SURFACE_HOVER};
  border-color: transparent;
}
button.flat:active {
  background-color: ${SURFACE_ALT};
}
button.flat:checked {
  background-color: ${ACCENT_BG};
  color: ${WHITE};
}
button.suggested-action {
  background-color: ${ACCENT};
  color: ${WHITE};
  border-color: ${ACCENT};
  background-image: none;
}
button.suggested-action:hover {
  background-color: ${ACCENT_HOVER};
  border-color: ${ACCENT_HOVER};
}
button.suggested-action:active {
  background-color: ${ACCENT};
}
button.destructive-action {
  background-color: #c01c28;
  color: ${WHITE};
  border-color: #c01c28;
  background-image: none;
}
button.destructive-action:hover {
  background-color: #e01c28;
  border-color: #e01c28;
}

/* ═══════════════════════════════════════════════════════════════
   Entries — proportional sizing
   ═══════════════════════════════════════════════════════════════ */
entry, textview text {
  background-color: ${SURFACE_LOW};
  color: ${FG};
  border: 1px solid ${BORDER};
  border-radius: ${RADIUS_SM}px;
  padding: 4px 10px;
  min-height: 24px;
  outline: none;
}
entry:focus, textview:focus-within {
  border-color: ${ACCENT};
  box-shadow: inset 0 0 0 1px ${ACCENT};
}
entry:disabled {
  background-color: ${SURFACE_LOW};
  color: ${DIMMED_FG};
}
entry selection, textview selection {
  background-color: ${ACCENT};
  color: ${WHITE};
}

/* ═══════════════════════════════════════════════════════════════
   Lists, grids, trees — CRITICAL for Lutris game views
   ═══════════════════════════════════════════════════════════════ */
listview, .list, columnview, treeview {
  background-color: ${BG};
  color: ${FG};
}
.list-row, columnview row, treeview row {
  background-color: ${BG};
  color: ${FG};
  padding: 6px 10px;
  min-height: 24px;
  border-radius: 0;
}
.list-row:hover, columnview row:hover, treeview row:hover {
  background-color: ${SURFACE_HOVER};
}
.list-row:selected, columnview row:selected, treeview row:selected {
  background-color: ${ACCENT_BG};
  color: ${WHITE};
}
.list-row:selected:hover, columnview row:selected:hover, treeview row:selected:hover {
  background-color: ${ACCENT};
}
columnview row:nth-child(even), treeview row:nth-child(even) {
  background-color: ${SURFACE_LOW};
}
columnview row:nth-child(even):hover, treeview row:nth-child(even):hover {
  background-color: ${SURFACE_HOVER};
}

/* Grid view — game grid layouts */
gridview {
  background-color: ${BG};
}
gridview > child {
  background-color: ${SURFACE};
  border: 1px solid ${BORDER};
  border-radius: ${RADIUS_MD}px;
  padding: 4px;
  margin: 2px;
}
gridview > child:hover {
  background-color: ${SURFACE_HOVER};
  border-color: ${BORDER_SUBTLE};
}
gridview > child:selected {
  background-color: ${ACCENT_BG};
  border-color: ${ACCENT};
  color: ${WHITE};
}
gridview > child:selected:hover {
  background-color: ${ACCENT};
}

/* ═══════════════════════════════════════════════════════════════
   Toolbar
   ═══════════════════════════════════════════════════════════════ */
toolbar, .toolbar {
  background-color: ${BG};
  border-bottom: 1px solid ${BORDER};
  padding: 4px;
}
toolbar button, .toolbar button {
  background-color: transparent;
  background-image: none;
  border: none;
  border-radius: ${RADIUS_SM}px;
  padding: 4px 8px;
  color: ${FG};
}
toolbar button:hover, .toolbar button:hover {
  background-color: ${SURFACE_HOVER};
}
toolbar button:active, .toolbar button:active {
  background-color: ${SURFACE_ALT};
}
toolbar button:checked, .toolbar button:checked {
  background-color: ${ACCENT_BG};
  color: ${WHITE};
}

/* ═══════════════════════════════════════════════════════════════
   Notebook / tabs
   ═══════════════════════════════════════════════════════════════ */
notebook {
  background-color: ${BG};
}
notebook > header {
  background-color: ${BG};
  border-bottom: 1px solid ${BORDER};
}
notebook > header > tabs > tab {
  background-color: transparent;
  color: ${DIMMED_FG};
  border: none;
  border-bottom: 2px solid transparent;
  border-radius: 0;
  padding: 8px 16px;
}
notebook > header > tabs > tab:hover {
  background-color: ${SURFACE_HOVER};
  color: ${FG};
}
notebook > header > tabs > tab:active {
  background-color: ${SURFACE_ALT};
}
notebook > header > tabs > tab:checked {
  background-color: transparent;
  color: ${FG};
  border-bottom-color: ${ACCENT};
}
tabbar > tab {
  background-color: transparent;
  color: ${DIMMED_FG};
  border: none;
  border-bottom: 2px solid transparent;
  padding: 8px 16px;
}
tabbar > tab:hover {
  background-color: ${SURFACE_HOVER};
  color: ${FG};
}
tabbar > tab:active {
  background-color: ${SURFACE_ALT};
}
tabbar > tab:checked {
  color: ${FG};
  border-bottom-color: ${ACCENT};
}

/* ═══════════════════════════════════════════════════════════════
   Switch — adw-gtk3 proportions
   ═══════════════════════════════════════════════════════════════ */
switch {
  outline-offset: -4px;
  padding: 3px;
  border-radius: 14px;
  background-color: alpha(currentColor,0.15);
}
switch:hover:not(:checked) {
  background-color: alpha(currentColor,0.2);
}
switch:checked {
  background-color: ${ACCENT};
}
switch:checked:hover {
  background-image: image(alpha(currentColor,0.1));
}
switch:disabled {
  color: alpha(${FG},0.5);
  border-color: transparent;
  background-color: mix(mix(currentColor,${BG},0.73),${BG},0.3);
}
switch slider {
  margin: 0;
  min-width: 20px;
  min-height: 20px;
  background-color: mix(white,${BG},0.2);
  border: 1px solid transparent;
  border-radius: 50%;
  box-shadow: 0 2px 4px rgba(0,0,0,0.2);
}
switch image {
  color: transparent;
}
switch:hover slider {
  background-color: white;
}
switch:checked > slider {
  background-color: white;
}
switch:disabled slider {
  background-color: mix(${BG},mix(white,${BG},0.2),0.5);
  box-shadow: none;
}

/* ═══════════════════════════════════════════════════════════════
   Scale / slider — adw-gtk3 proportions
   ═══════════════════════════════════════════════════════════════ */
scale {
  min-height: 10px;
  min-width: 10px;
  padding: 12px;
}
scale slider {
  min-height: 18px;
  min-width: 18px;
  margin: -9px;
  background-color: mix(white,${BG},0.2);
  border: 1px solid transparent;
  border-radius: 50%;
  box-shadow: 0 1px 3px rgba(0,0,0,0.3);
}
scale trough {
  outline-offset: 2px;
  background-color: alpha(currentColor,0.15);
  border-radius: 5px;
}
scale horizontal trough {
  min-height: 4px;
}
scale vertical trough {
  min-width: 4px;
}
scale trough highlight {
  background-color: ${ACCENT};
  border-radius: 5px;
}
scale slider:hover {
  background-color: white;
}

/* ═══════════════════════════════════════════════════════════════
   Scrollbar
   ═══════════════════════════════════════════════════════════════ */
scrollbar {
  background-color: transparent;
}
scrollbar trough {
  background-color: transparent;
}
scrollbar slider {
  background-color: #444444;
  border-radius: ${RADIUS_SM}px;
  min-width: 6px;
  min-height: 6px;
  margin: 3px;
  border: none;
}
scrollbar:hover trough {
  background-color: ${BORDER};
}
scrollbar:hover slider {
  background-color: #555555;
}
scrollbar slider:active {
  background-color: ${ACCENT};
}

/* ═══════════════════════════════════════════════════════════════
   Progress bar
   ═══════════════════════════════════════════════════════════════ */
progressbar > trough {
  background-color: ${BORDER};
  border-radius: ${RADIUS_SM}px;
  min-height: 4px;
}
progressbar > trough > progress {
  background-color: ${ACCENT};
  border-radius: ${RADIUS_SM}px;
}

/* ═══════════════════════════════════════════════════════════════
   Info bar
   ═══════════════════════════════════════════════════════════════ */
infobar {
  border-bottom: 1px solid ${BORDER};
}
infobar.info {
  background-color: ${SURFACE};
  color: ${FG};
}
infobar.warning {
  background-color: rgba(205,147,9,0.15);
  color: #cd9309;
  border-color: rgba(205,147,9,0.3);
}
infobar.error {
  background-color: rgba(192,28,40,0.15);
  color: #e01c28;
  border-color: rgba(192,28,40,0.3);
}

/* ═══════════════════════════════════════════════════════════════
   Popover & menu — nearly solid for readability
   ═══════════════════════════════════════════════════════════════ */
popover {
  background-color: ${SURFACE};
  color: ${FG};
  border: 1px solid ${BORDER};
  border-radius: ${RADIUS_MD}px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.3);
}
popover menuitem {
  border-radius: ${RADIUS_SM}px;
  padding: 4px 8px;
  margin: 1px 4px;
}
popover menuitem:hover {
  background-color: ${SURFACE_HOVER};
}
popover menuitem:selected {
  background-color: ${ACCENT_BG};
  color: ${WHITE};
}
popover separator {
  background-color: ${BORDER};
  margin: 4px 8px;
}
menu {
  background-color: ${SURFACE};
  color: ${FG};
  border: 1px solid ${BORDER};
  border-radius: ${RADIUS_MD}px;
  padding: 4px;
}
menu menuitem {
  border-radius: ${RADIUS_SM}px;
  padding: 4px 24px 4px 8px;
  margin: 1px 2px;
}
menu menuitem:hover {
  background-color: ${SURFACE_HOVER};
}
menu menuitem:selected {
  background-color: ${ACCENT_BG};
  color: ${WHITE};
}
menu separator {
  background-color: ${BORDER};
  margin: 4px 8px;
}

/* ═══════════════════════════════════════════════════════════════
   Tooltip
   ═══════════════════════════════════════════════════════════════ */
tooltip {
  background-color: ${SURFACE};
  color: ${FG};
  border: 1px solid ${BORDER_SUBTLE};
  border-radius: ${RADIUS_SM}px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.3);
  padding: 4px 8px;
}
tooltip label {
  color: ${FG};
}

/* ═══════════════════════════════════════════════════════════════
   OSD
   ═══════════════════════════════════════════════════════════════ */
.osd {
  background-color: ${SURFACE};
  color: ${FG};
  border: 1px solid ${BORDER_SUBTLE};
  border-radius: ${RADIUS_MD}px;
  box-shadow: 0 4px 16px rgba(0,0,0,0.4);
}
.osd progressbar > trough > progress {
  background-color: ${ACCENT};
}

/* ═══════════════════════════════════════════════════════════════
   Frames & separators
   ═══════════════════════════════════════════════════════════════ */
frame > border, .frame {
  border: 1px solid ${BORDER};
  border-radius: ${RADIUS_SM}px;
}
separator {
  background-color: ${BORDER};
  min-width: 1px;
  min-height: 1px;
}
separator.horizontal { margin: 4px 0; }
separator.vertical { margin: 0 4px; }

/* ═══════════════════════════════════════════════════════════════
   ComboBox / dropdown
   ═══════════════════════════════════════════════════════════════ */
combobox button.combo {
  background-color: ${SURFACE_ALT};
  background-image: none;
  border: 1px solid ${BORDER};
  border-radius: ${RADIUS_SM}px;
  color: ${FG};
  padding: 4px 8px;
}
combobox button.combo:hover {
  background-color: ${SURFACE_HOVER};
}

/* ═══════════════════════════════════════════════════════════════
   Spin button
   ═══════════════════════════════════════════════════════════════ */
spinbutton button {
  background-color: ${SURFACE_ALT};
  background-image: none;
  border: 1px solid ${BORDER};
  color: ${FG};
}
spinbutton button:hover {
  background-color: ${SURFACE_HOVER};
}
spinbutton button:active {
  background-color: ${SURFACE};
}

/* ═══════════════════════════════════════════════════════════════
   Check & radio buttons — adw-gtk3 proportions
   ═══════════════════════════════════════════════════════════════ */
checkbutton, radiobutton { color: ${FG}; }
check {
  margin: 0 4px;
  padding: 1px;
  min-height: 14px;
  min-width: 14px;
  border: 2px solid;
  background-clip: padding-box;
  background-image: image(transparent);
  border-color: alpha(currentColor,0.15);
  box-shadow: none;
}
check:hover:not(:checked):not(:indeterminate) {
  border-color: alpha(currentColor,0.2);
}
check:checked {
  background-clip: border-box;
  background-color: ${ACCENT};
  border-color: ${ACCENT};
  color: ${WHITE};
}
check:disabled {
  color: alpha(${FG},0.5);
  border-color: alpha(currentColor,0.15);
  background-image: image(transparent);
}
radio {
  margin: 0 4px;
  padding: 1px;
  min-height: 14px;
  min-width: 14px;
  border: 2px solid;
  background-clip: padding-box;
  background-image: image(transparent);
  border-color: alpha(currentColor,0.15);
  border-radius: 50%;
  box-shadow: none;
}
radio:hover:not(:checked):not(:indeterminate) {
  border-color: alpha(currentColor,0.2);
}
radio:checked {
  background-clip: border-box;
  background-color: ${ACCENT};
  border-color: ${ACCENT};
  color: ${WHITE};
}
radio:disabled {
  color: alpha(${FG},0.5);
  border-color: alpha(currentColor,0.15);
  background-image: image(transparent);
}

/* ═══════════════════════════════════════════════════════════════
   Links
   ═══════════════════════════════════════════════════════════════ */
link, *:link { color: ${ACCENT}; }
link:visited, *:link:visited { color: ${ACCENT_HOVER}; }
link:hover, *:link:hover { color: ${ACCENT_HOVER}; text-decoration: underline; }

/* ═══════════════════════════════════════════════════════════════
   Search bar
   ═══════════════════════════════════════════════════════════════ */
searchbar > revealer > box {
  background-color: ${BG};
  border-bottom: 1px solid ${BORDER};
  padding: 6px;
}
EOF

  cp "$HOME/.config/gtk-4.0/gtk.css" "$THEME_DIR/gtk-4.0/gtk.css"
  cp "$THEME_DIR/gtk-4.0/gtk.css" "$THEME_DIR/gtk-4.0/gtk-dark.css"
  echo "[gtk-qt-theme] GTK 4: CSS generated (headerbar solid, content translucent)"
}
