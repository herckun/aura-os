#!/usr/bin/env bash
# ── GTK(2/3/4) + Qt Theme Generator ──────────────────
# Generates theme files from the accent color.
# Usage: update-gtk-qt-theme.sh '<json_blob>'
# JSON keys: accent, shellMode, transparency, animations, monochrome, blur

set -euo pipefail

# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core/bash" && pwd)/bootstrap.sh"

# Default to empty JSON object if no argument provided (e.g. called from install.sh)
DEFAULT_JSON='{}'
INPUT_JSON="${1:-$DEFAULT_JSON}"

# ── Normalize accent from JSON blob ──────────────────────────────────
# shellcheck disable=SC2046,SC2086 — eval of controlled Python output is intentional
eval "$(python3 -c '
import json, os, sys

sys.path.insert(0, os.path.dirname(os.path.realpath(sys.argv[1])))
from theme_lib import find_theme_json, normalize_accent, style_key_for, clean_font

params, raw_accent = normalize_accent(sys.argv[2])
print("ACCENT_HEX=\"%s\"" % raw_accent)
print("ACCENT=\"#%s\"" % raw_accent)

style_mode = int(params.get("shellMode", 0))
trans = str(params.get("transparency", True)).lower() == "true"
blur_state = str(params.get("blur", True)).lower() == "true"

theme_data = find_theme_json()

colors = theme_data.get("colors", {})
typography = theme_data.get("typography", {})
styles = theme_data.get("styles", {})

style_conf = styles.get(style_key_for(style_mode), styles.get("default", {}))
radius = style_conf.get("radius", {})

bg = colors.get("background", "#000000").lstrip("#")
surface = colors.get("backgroundSecondary", "#111111").lstrip("#")
surface_alt = colors.get("backgroundTertiary", "#1A1A1A").lstrip("#")

def hex_to_rgb(h):
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)

bg_r, bg_g, bg_b = hex_to_rgb(bg)
sf_r, sf_g, sf_b = hex_to_rgb(surface)
sfa_r, sfa_g, sfa_b = hex_to_rgb(surface_alt)

sfl_r = (bg_r + sf_r) // 2
sfl_g = (bg_g + sf_g) // 2
sfl_b = (bg_b + sf_b) // 2
surface_low = f"{sfl_r:02x}{sfl_g:02x}{sfl_b:02x}"

print("BG_HEX=\"#%s\"" % bg)
print("BG_R=%d; BG_G=%d; BG_B=%d" % (bg_r, bg_g, bg_b))
print("SURFACE_HEX=\"#%s\"" % surface)
print("SURFACE_R=%d; SURFACE_G=%d; SURFACE_B=%d" % (sf_r, sf_g, sf_b))
print("SURFACE_ALT_HEX=\"#%s\"" % surface_alt)
print("SURFACE_ALT_R=%d; SURFACE_ALT_G=%d; SURFACE_ALT_B=%d" % (sfa_r, sfa_g, sfa_b))
print("SURFACE_LOW_HEX=\"#%s\"" % surface_low)
print("SURFACE_LOW_R=%d; SURFACE_LOW_G=%d; SURFACE_LOW_B=%d" % (sfl_r, sfl_g, sfl_b))

print("FG=\"%s\"" % colors.get("textPrimary", "#E8E8E8"))
print("DIMMED_FG=\"%s\"" % colors.get("textSecondary", "#999999"))
print("BORDER=\"%s\"" % colors.get("border", "#222222"))
print("BORDER_SUBTLE=\"%s\"" % colors.get("borderVisible", "#333333"))
print("WHITE=\"%s\"" % colors.get("textDisplay", "#FFFFFF"))

print("FONT_SANS=\"%s\"" % clean_font(typography.get("fontFamily", "Space Grotesk")))
print("FONT_MONO=\"%s\"" % clean_font(typography.get("fontFamilyMono", "Space Mono")))

print("RADIUS_SM=%d" % radius.get("sm", 4))
print("RADIUS_MD=%d" % radius.get("md", 8))
print("RADIUS_UI=%d" % radius.get("ui", 12))

print("TRANSPARENCY=\"%s\"" % ("true" if trans else "false"))
print("BLUR=\"%s\"" % ("true" if blur_state else "false"))
' "$0" "$INPUT_JSON")"

ADW_GTK4_DIR="/usr/share/themes/adw-gtk3-dark/gtk-4.0"

# Resolve to CSS values: rgba() when transparent, solid hex otherwise
if [[ "$TRANSPARENCY" == "true" ]]; then
  BG="rgba($BG_R,$BG_G,$BG_B,0.85)"
  SURFACE="rgba($SURFACE_R,$SURFACE_G,$SURFACE_B,0.85)"
  SURFACE_ALT="rgba($SURFACE_ALT_R,$SURFACE_ALT_G,$SURFACE_ALT_B,0.85)"
  SURFACE_LOW="rgba($SURFACE_LOW_R,$SURFACE_LOW_G,$SURFACE_LOW_B,0.85)"
else
  BG="${BG_HEX}"
  SURFACE="${SURFACE_HEX}"
  SURFACE_ALT="${SURFACE_ALT_HEX}"
  SURFACE_LOW="${SURFACE_LOW_HEX}"
fi

# ── Accent variants ─────────────────────────────────────────────
ACCENT_BG=$(python3 -c "
h = '$ACCENT_HEX'; r = int(h[0:2],16)//3; g = int(h[2:4],16)//3; b = int(h[4:6],16)//3
print(f'#{r:02x}{g:02x}{b:02x}')
")
ACCENT_HOVER=$(python3 -c "
h = '$ACCENT_HEX'; r = int(h[0:2],16)*2//3; g = int(h[2:4],16)*2//3; b = int(h[4:6],16)*2//3
print(f'#{r:02x}{g:02x}{b:02x}')
")

FG_HEX_NO_HASH="${FG#\#}"
FG_R=$((16#${FG_HEX_NO_HASH:0:2}))
FG_G=$((16#${FG_HEX_NO_HASH:2:2}))
FG_B=$((16#${FG_HEX_NO_HASH:4:2}))

DIMMED_FG_HEX_NO_HASH="${DIMMED_FG#\#}"
DIMMED_FG_R=$((16#${DIMMED_FG_HEX_NO_HASH:0:2}))
DIMMED_FG_G=$((16#${DIMMED_FG_HEX_NO_HASH:2:2}))
DIMMED_FG_B=$((16#${DIMMED_FG_HEX_NO_HASH:4:2}))

# FG with various opacities for Kvantum text states
FG_OPAQUE="rgba(${FG_R},${FG_G},${FG_B},1.0)"
FG_92="rgba(${FG_R},${FG_G},${FG_B},0.92)"
FG_78="rgba(${FG_R},${FG_G},${FG_B},0.78)"
FG_71="rgba(${FG_R},${FG_G},${FG_B},0.71)"
FG_55="rgba(${FG_R},${FG_G},${FG_B},0.55)"
FG_49="rgba(${FG_R},${FG_G},${FG_B},0.49)"
FG_43="rgba(${FG_R},${FG_G},${FG_B},0.43)"

ACCENT_R=$((16#${ACCENT_HEX:0:2}))
ACCENT_G=$((16#${ACCENT_HEX:2:2}))
ACCENT_B=$((16#${ACCENT_HEX:4:2}))
ACCENT_BG_R=$(( ACCENT_R / 3 ))
ACCENT_BG_G=$(( ACCENT_G / 3 ))
ACCENT_BG_B=$(( ACCENT_B / 3 ))
DH_R=$(( ACCENT_R * 2 / 3 ))
DH_G=$(( ACCENT_G * 2 / 3 ))
DH_B=$(( ACCENT_B * 2 / 3 ))

echo "[gtk-qt-theme] BG=${BG} FG=${FG} ACCENT=${ACCENT}"

THEME_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/themes/${APP_THEME_KEY}"

# ═══════════════════════════════════════════════════════════════
# Theme directory — registers "${APP_THEME_KEY}" as a proper GTK theme
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
# GTK 4.0 — full CSS with @define-color + :root custom properties
# ═══════════════════════════════════════════════════════════════
mkdir -p "$HOME/.config/gtk-4.0"
cat > "$HOME/.config/gtk-4.0/gtk.css" << EOF
/* Import adw-gtk3-dark for full libadwaita widget styling */
@import url('${ADW_GTK4_DIR}/gtk.css');

/* ── ${APP_DISPLAY} colors — override libadwaita defaults ── */
@define-color theme_bg_color ${BG};
@define-color theme_fg_color ${FG};
@define-color theme_base_color ${BG};
@define-color theme_text_color ${FG};
@define-color theme_selected_bg_color ${ACCENT};
@define-color theme_selected_fg_color ${WHITE};
@define-color theme_unfocused_base_color ${BG};
@define-color theme_unfocused_text_color ${FG};
@define-color theme_unfocused_selected_bg_color ${ACCENT_BG};
@define-color theme_unfocused_selected_fg_color ${WHITE};

@define-color borders ${BORDER};
@define-color unfocused_borders ${BORDER};
@define-color warning_color #cd9309;
@define-color error_color #c01c28;
@define-color success_color #26a269;

@define-color window_bg_color ${BG};
@define-color window_fg_color ${FG};
@define-color view_bg_color ${BG};
@define-color view_fg_color ${FG};
@define-color headerbar_bg_color ${BG};
@define-color headerbar_fg_color ${FG};
@define-color headerbar_backdrop_color ${BG};
@define-color headerbar_border_color ${BORDER};
@define-color headerbar_shade_color ${BORDER};
@define-color sidebar_bg_color ${BG};
@define-color sidebar_fg_color ${FG};
@define-color sidebar_backdrop_color ${BG};
@define-color sidebar_border_color ${BORDER};
@define-color secondary_sidebar_bg_color ${BG};
@define-color secondary_sidebar_fg_color ${FG};
@define-color secondary_sidebar_backdrop_color ${BG};
@define-color secondary_sidebar_border_color ${BORDER};

@define-color card_bg_color ${SURFACE};
@define-color card_fg_color ${FG};
@define-color card_shade_color ${BORDER};
@define-color popover_bg_color ${SURFACE};
@define-color popover_fg_color ${FG};
@define-color dialog_bg_color ${BG};
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

@define-color border_color ${BORDER};
@define-color dim_label_color ${DIMMED_FG};
@define-color scrollbar_bg_color ${BORDER};
@define-color scrollbar_slider_color #444444;

@define-color button_bg_color ${SURFACE};
@define-color button_fg_color ${FG};
@define-color button_border_color ${BORDER};
@define-color entry_bg_color ${BG};
@define-color entry_fg_color ${FG};
@define-color entry_border_color ${BORDER};

:root {
  --window-bg-color: ${BG};
  --window-fg-color: ${FG};
  --view-bg-color: ${BG};
  --view-fg-color: ${FG};
  --headerbar-bg-color: ${BG};
  --headerbar-fg-color: ${FG};
  --headerbar-backdrop-color: ${BG};
  --headerbar-border-color: ${BORDER};
  --sidebar-bg-color: ${BG};
  --sidebar-fg-color: ${FG};
  --sidebar-backdrop-color: ${BG};
  --sidebar-border-color: ${BORDER};
  --secondary-sidebar-bg-color: ${BG};
  --secondary-sidebar-fg-color: ${FG};
  --secondary-sidebar-backdrop-color: ${BG};
  --secondary-sidebar-border-color: ${BORDER};
  --card-bg-color: ${SURFACE};
  --card-fg-color: ${FG};
  --card-shade-color: ${BORDER};
  --popover-bg-color: ${SURFACE};
  --popover-fg-color: ${FG};
  --dialog-bg-color: ${BG};
  --dialog-fg-color: ${FG};
  --accent-bg-color: ${ACCENT};
  --accent-color: ${ACCENT};
  --accent-fg-color: ${WHITE};
  --destructive-bg-color: #c01c28;
  --destructive-color: #c01c28;
  --destructive-fg-color: ${WHITE};
  --success-bg-color: #26a269;
  --success-color: #26a269;
  --success-fg-color: ${WHITE};
  --warning-bg-color: #cd9309;
  --warning-color: #cd9309;
  --warning-fg-color: rgba(0,0,0,0.8);
  --error-bg-color: #c01c28;
  --error-color: #c01c28;
  --error-fg-color: ${WHITE};
  --border-color: ${BORDER};
  --dim-label-color: ${DIMMED_FG};
  --scrollbar-bg-color: ${BORDER};
  --scrollbar-slider-color: #444444;

  /* Theme.json radius overrides */
  --card-border-radius: ${RADIUS_MD}px;
  --popover-border-radius: ${RADIUS_MD}px;
  --button-border-radius: ${RADIUS_SM}px;
}

*:selected { background-color: ${ACCENT}; color: ${WHITE}; }
*:selected:backdrop { background-color: ${ACCENT_BG}; color: ${WHITE}; }

/* Direct overrides to win over libadwaita re-defining @define-color */
window.background, .background, decoration {
  background-color: ${BG};
}
textview, textview text {
  background-color: ${BG};
}
entry, entry text {
  background-color: ${BG};
}

/* ── Button states ── */
button:hover { background-color: ${SURFACE_ALT}; }
button:active, button:checked { background-color: ${SURFACE}; }
button:checked:hover { background-color: ${SURFACE_ALT}; }

/* ── Entry focus ── */
entry:focus { border-color: ${ACCENT}; }
entry selection { background-color: ${ACCENT}; color: ${WHITE}; }

/* ── Scrollbar — thin, rounded, subtle ── */
scrollbar slider {
  background-color: #444444;
  border-radius: ${RADIUS_SM}px;
  min-width: 6px;
  min-height: 6px;
  margin: 3px;
}
scrollbar trough {
  background-color: ${BORDER};
  border-radius: ${RADIUS_SM}px;
}
scrollbar:hover slider { background-color: #555555; }
scrollbar slider:active { background-color: ${ACCENT}; }

/* ── Sizing overrides ── */
button, entry {
  border-radius: ${RADIUS_SM}px;
}
.card, .popover, dialog {
  border-radius: ${RADIUS_MD}px;
}

/* ── Tooltip ── */
tooltip {
  border-radius: ${RADIUS_SM}px;
}
tooltip label {
  color: ${FG};
}

/* ── Link color ── */
link, *:link {
  color: ${ACCENT};
}
EOF
cp "$HOME/.config/gtk-4.0/gtk.css" "$THEME_DIR/gtk-4.0/gtk.css"
# Dark variant is identical (our theme is always dark)
cp "$THEME_DIR/gtk-4.0/gtk.css" "$THEME_DIR/gtk-4.0/gtk-dark.css"

# ═══════════════════════════════════════════════════════════════
# GTK 3.0 — same CSS + settings.ini
# ═══════════════════════════════════════════════════════════════
mkdir -p "$HOME/.config/gtk-3.0"
cat > "$HOME/.config/gtk-3.0/gtk.css" << EOF
@define-color theme_bg_color ${BG_HEX};
@define-color theme_fg_color ${FG};
@define-color theme_base_color ${BG_HEX};
@define-color theme_text_color ${FG};
@define-color theme_selected_bg_color ${ACCENT};
@define-color theme_selected_fg_color ${WHITE};
@define-color theme_unfocused_base_color ${BG_HEX};
@define-color theme_unfocused_text_color ${FG};
@define-color theme_unfocused_selected_bg_color ${ACCENT_BG};
@define-color theme_unfocused_selected_fg_color ${WHITE};

@define-color borders ${BORDER};
@define-color unfocused_borders ${BORDER};
@define-color warning_color #cd9309;
@define-color error_color #c01c28;
@define-color success_color #26a269;

@define-color window_bg_color ${BG_HEX};
@define-color window_fg_color ${FG};
@define-color view_bg_color ${BG_HEX};
@define-color view_fg_color ${FG};
@define-color headerbar_bg_color ${BG_HEX};
@define-color headerbar_fg_color ${FG};
@define-color headerbar_backdrop_color ${BG_HEX};
@define-color headerbar_border_color ${BORDER};
@define-color headerbar_shade_color ${BORDER};
@define-color sidebar_bg_color ${BG_HEX};
@define-color sidebar_fg_color ${FG};
@define-color sidebar_backdrop_color ${BG_HEX};
@define-color sidebar_border_color ${BORDER};

@define-color card_bg_color ${SURFACE_HEX};
@define-color card_fg_color ${FG};
@define-color card_shade_color ${BORDER};
@define-color popover_bg_color ${SURFACE_HEX};
@define-color popover_fg_color ${FG};
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

@define-color border_color ${BORDER};
@define-color dim_label_color ${DIMMED_FG};
@define-color scrollbar_bg_color ${BORDER};
@define-color scrollbar_slider_color #444444;

:selected { background-color: ${ACCENT}; color: ${WHITE}; }
:selected:backdrop { background-color: ${ACCENT_BG}; color: ${WHITE}; }

/* Direct overrides to win over adw-gtk3-dark re-defining @define-color */
GtkWindow, .background {
  background-color: ${BG};
}
GtkTextView, textview text {
  background-color: ${BG};
}
GtkEntry, entry {
  background-color: ${BG};
}

/* ── Button states ── */
button:hover, GtkButton:hover {
  background-color: ${SURFACE_ALT};
}
button:active, button:checked, GtkButton:active {
  background-color: ${SURFACE};
}

/* ── Entry focus ── */
entry:focus, GtkEntry:focus {
  border-color: ${ACCENT};
}
entry selection, GtkEntry selection {
  background-color: ${ACCENT};
  color: ${WHITE};
}

/* ── Scrollbar — thin, rounded, subtle ── */
scrollbar slider, GtkScrollbar slider {
  background-color: #444444;
  border-radius: ${RADIUS_SM}px;
  min-width: 6px;
  min-height: 6px;
  margin: 3px;
}
scrollbar trough, GtkScrollbar trough {
  background-color: ${BORDER};
  border-radius: ${RADIUS_SM}px;
}
scrollbar:hover slider { background-color: #555555; }

/* ── Sizing overrides ── */
button, entry, GtkButton, GtkEntry {
  border-radius: ${RADIUS_SM}px;
}
.card, .popover, GtkDialog {
  border-radius: ${RADIUS_MD}px;
}

/* ── Link color ── */
*:link, GtkLinkButton {
  color: ${ACCENT};
}
EOF
cp "$HOME/.config/gtk-3.0/gtk.css" "$THEME_DIR/gtk-3.0/gtk.css"
# Dark variant is identical (our theme is always dark)
cp "$THEME_DIR/gtk-3.0/gtk.css" "$THEME_DIR/gtk-3.0/gtk-dark.css"

cat > "$HOME/.config/gtk-3.0/settings.ini" << EOF
[Settings]
gtk-theme-name=${APP_THEME_KEY}
gtk-icon-theme-name=Papirus-Dark
gtk-application-prefer-dark-theme=1
gtk-font-name=${FONT_SANS} 10
gtk-cursor-theme-name=default
EOF

# GTK 4.0 — same settings.ini
mkdir -p "$HOME/.config/gtk-4.0"
cp "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"

# ═══════════════════════════════════════════════════════════════
# GTK 2.0 — simple gtkrc
# ═══════════════════════════════════════════════════════════════
mkdir -p "$HOME/.config/gtk-2.0"
cat > "$HOME/.config/gtk-2.0/gtkrc" << EOF
style "${APP_THEME_KEY}-selected" {
  bg[SELECTED] = "${ACCENT}"
  fg[SELECTED] = "${WHITE}"
  bg[ACTIVE]   = "${ACCENT_BG}"
}
widget_class "*" style "${APP_THEME_KEY}-selected"
EOF
# Copy GTK2 gtkrc to theme directory for theme-level discovery
mkdir -p "$THEME_DIR/gtk-2.0"
cp "$HOME/.config/gtk-2.0/gtkrc" "$THEME_DIR/gtk-2.0/gtkrc"

# ═══════════════════════════════════════════════════════════════
# Kvantum — full Qt theme (rounded corners, adwaita-style)
# ═══════════════════════════════════════════════════════════════
KVANTUM_DIR="$HOME/.config/Kvantum/${APP_DISPLAY}"
mkdir -p "$KVANTUM_DIR"

# Copy decorative SVG from KvGnomeDark (adwaita-like style)
SVG_SRC="/usr/share/Kvantum/KvGnomeDark/KvGnomeDark.svg"
if [[ -f "$SVG_SRC" ]]; then
  cp "$SVG_SRC" "$KVANTUM_DIR/${APP_DISPLAY}.svg"
fi

cat > "$KVANTUM_DIR/${APP_DISPLAY}.kvconfig" << KVEOF
[%General]
author=${APP_DISPLAY}
comment=${APP_DISPLAY} — dark monochrome Kvantum theme
x11drag=all
alt_mnemonic=true
left_tabs=false
attach_active_tab=false
mirror_doc_tabs=false
group_toolbar_buttons=false
toolbar_item_spacing=2
toolbar_interior_spacing=2
spread_progressbar=true
spread_menuitems=true
composite=true
menu_shadow_depth=6
tooltip_shadow_depth=6
scroll_width=12
scroll_arrows=false
scroll_min_extent=50
transient_scrollbar=true
transient_groove=true
slider_width=4
slider_handle_width=22
slider_handle_length=18
tickless_slider_handle_size=20
center_toolbar_handle=true
check_size=16
textless_progressbar=false
progressbar_thickness=4
menubar_mouse_tracking=true
toolbutton_style=1
click_behavior=0
translucent_windows=${TRANSPARENCY}
blurring=${BLUR}
popup_blurring=${BLUR}
vertical_spin_indicators=false
inline_spin_indicators=true
inline_spin_separator=true
spin_button_width=32
fill_rubberband=false
merge_menubar_with_toolbar=true
small_icon_size=16
large_icon_size=32
button_icon_size=16
toolbar_icon_size=22
combo_as_lineedit=false
square_combo_button=true
combo_menu=true
hide_combo_checkboxes=true
combo_focus_rect=true
spread_header=true
layout_spacing=3
tooltip_delay=-1
submenu_overlap=0
animate_states=true
tree_branch_line=true
contrast=1.00
dialog_button_layout=2
groupbox_top_label=false
intensity=1.00
joined_inactive_tabs=true
no_inactiveness=false
no_window_pattern=false
reduce_menu_opacity=0
reduce_window_opacity=0
respect_DE=true
saturation=1.00
scrollable_menu=true
scrollbar_in_view=true
submenu_delay=250

[GeneralColors]
window.color=${BG_HEX}
inactive.window.color=${BG_HEX}
base.color=${BG_HEX}
inactive.base.color=${SURFACE_HEX}
alt.base.color=${SURFACE_HEX}
inactive.alt.base.color=${SURFACE_HEX}
button.color=${SURFACE_HEX}
light.color=${FG}
mid.light.color=${FG}
dark.color=${BORDER}
mid.color=${SURFACE_HEX}
highlight.color=${ACCENT}
inactive.highlight.color=${ACCENT_BG}
text.color=${FG}
inactive.text.color=${DIMMED_FG}
window.text.color=${FG}
inactive.window.text.color=${DIMMED_FG}
button.text.color=${FG}
disabled.text.color=${DIMMED_FG}
tooltip.text.color=${FG}
highlight.text.color=${WHITE}
link.color=${ACCENT}
link.visited.color=${ACCENT_HOVER}
progress.indicator.text.color=${FG}

[Hacks]
transparent_ktitle_label=false
transparent_dolphin_view=false
transparent_pcmanfm_sidepane=false
blur_translucent=false
transparent_menutitle=false
transparent_arrow_button=false
respect_darkness=true
force_size_grip=true
iconless_pushbutton=false
iconless_menu=false
disabled_icon_opacity=100
normal_default_pushbutton=false
single_top_toolbar=true
tint_on_mouseover=0
lxqtmainmenu_iconsize=0
middle_click_scroll=false
no_selection_tint=false
transparent_pcmanfm_view=false

[PanelButtonCommand]
frame=true
frame.element=btn
frame.expandedElement=button
frame.top=3
frame.bottom=3
frame.left=3
frame.right=3
interior=true
interior.element=button
indicator.size=9
text.normal.color=${FG_OPAQUE}
text.normal.inactive.color=${FG_55}
text.focus.color=${FG_OPAQUE}
text.press.color=${FG_OPAQUE}
text.toggle.color=${FG_OPAQUE}
text.toggle.inactive.color=${FG_55}
text.shadow=true
text.shadow.color=black
text.shadow.alpha=210
text.shadow.xshift=1
text.shadow.yshift=1
text.shadow.depth=1
text.margin=1
text.iconspacing=4
indicator.element=arrow
text.margin.top=3
text.margin.bottom=4
text.margin.left=3
text.margin.right=3
min_width=+0.2font
min_height=+0.2font
frame.expansion=12

[PanelButtonTool]
inherits=PanelButtonCommand
frame.element=btn
frame.expandedElement=button

[ToolbarButton]
inherits=PanelButtonCommand
interior.element=tbutton
frame.element=tbtn
frame.expandedElement=tbutton

[Dock]
inherits=PanelButtonCommand
interior.element=dock
frame.element=dock
frame.top=1
frame.bottom=1
frame.left=1
frame.right=1
text.normal.color=${FG_OPAQUE}

[DockTitle]
inherits=PanelButtonCommand
frame.top=3
frame.bottom=3
frame.left=3
frame.right=3
frame=false
interior=false
text.normal.color=${FG_OPAQUE}
text.focus.color=${FG_OPAQUE}
text.bold=true
text.shadow=false
text.margin.top=2
text.margin.bottom=2

[IndicatorSpinBox]
inherits=PanelButtonCommand
frame.element=btn
frame.expandedElement=button
interior.element=button
indicator.element=iarrow
indicator.size=10
text.normal.color=${FG_OPAQUE}

[RadioButton]
inherits=PanelButtonCommand
frame=false
interior.element=radio
text.normal.color=${FG_OPAQUE}
text.focus.color=${FG_OPAQUE}
text.shadow=false
text.margin.top=2
text.margin.bottom=2

[CheckBox]
inherits=PanelButtonCommand
frame=false
interior.element=checkbox
text.normal.color=${FG_OPAQUE}
text.focus.color=${FG_OPAQUE}
text.shadow=false
text.margin.top=2
text.margin.bottom=2

[GenericFrame]
inherits=PanelButtonCommand
frame=true
interior=false
frame.element=common
interior.element=common
frame.top=1
frame.bottom=1
frame.left=1
frame.right=1

[LineEdit]
inherits=PanelButtonCommand
frame.element=le
frame.expandedElement=lineedit
interior.element=lineedit
text.margin.left=2
text.margin.right=2
text.margin.top=3
text.margin.bottom=4

[DropDownButton]
inherits=PanelButtonCommand
indicator.element=arrow-down
indicator.size=10

[IndicatorArrow]
indicator.element=arrow
indicator.size=9

[ToolboxTab]
inherits=PanelButtonCommand
text.normal.color=${FG_71}
text.normal.inactive.color=${FG_55}
text.press.color=${FG_OPAQUE}
text.press.inactive.color=${FG_55}
text.focus.color=${FG_OPAQUE}
text.shadow=false

[Tab]
inherits=PanelButtonCommand
interior.element=button
text.margin.left=8
text.margin.right=8
text.margin.top=3
text.margin.bottom=4
frame.element=button
focusFrame=true
indicator.element=tab
indicator.size=12
frame.top=3
frame.bottom=3
frame.left=3
frame.right=3
text.normal.color=${FG_49}
text.normal.inactive.color=${FG_43}
text.focus.color=${FG_71}
text.toggle.color=${FG_OPAQUE}
text.bold=true
min_width=4font

[TabFrame]
inherits=PanelButtonCommand
frame.element=none
interior=false
frame.top=2
frame.bottom=2
frame.left=2
frame.right=2

[TreeExpander]
inherits=PanelButtonCommand
frame=false
interior=false
indicator.size=11
indicator.element=tree

[HeaderSection]
inherits=PanelButtonCommand
frame.element=header
interior.element=header
frame.top=1
frame.bottom=1
frame.left=1
frame.right=1
text.margin.top=3
text.margin.bottom=3
text.margin.left=3
text.margin.right=3
text.shadow=false
text.normal.color=${FG_49}
text.normal.inactive.color=${FG_43}
text.focus.color=${FG_71}
text.toggle.color=${FG_OPAQUE}
text.bold=true
frame.expansion=0

[SizeGrip]
indicator.element=resize-grip

[Toolbar]
inherits=PanelButtonCommand
indicator.element=toolbar
indicator.size=5
text.margin=0
interior=true
frame=true
interior.element=menubar
frame.element=menubar
text.normal.color=${FG_OPAQUE}
text.focus.color=${FG_OPAQUE}
frame.left=0
frame.right=0
frame.top=0
frame.bottom=1
text.shadow=false

[Slider]
inherits=PanelButtonCommand
frame.element=slider
interior.element=slider
frame.top=2
frame.bottom=2
frame.left=2
frame.right=2

[SliderCursor]
inherits=PanelButtonCommand
frame=false
interior.element=slidercursor

[Progressbar]
inherits=PanelButtonCommand
frame.top=2
frame.bottom=2
frame.left=2
frame.right=2
frame.element=progress
interior.element=progress
text.margin=0
text.normal.color=${FG_55}
text.normal.inactive.color=${FG_43}
text.focus.color=${FG_OPAQUE}
text.press.color=${FG_OPAQUE}
text.toggle.color=${FG_OPAQUE}
text.bold=true
frame.expansion=8
text.shadow=false

[ProgressbarContents]
inherits=PanelButtonCommand
frame.top=2
frame.bottom=2
frame.left=2
frame.right=2
frame=true
frame.element=progress-pattern
interior.element=progress-pattern

[ItemView]
inherits=PanelButtonCommand
text.margin=0
frame.element=itemview
interior.element=itemview
frame.top=2
frame.bottom=2
frame.left=2
frame.right=2
text.margin.top=3
text.margin.bottom=3
text.margin.left=4
text.margin.right=4
text.normal.color=${FG_OPAQUE}
text.normal.inactive.color=${FG_78}
text.focus.color=${FG_OPAQUE}
text.press.color=${FG_OPAQUE}
text.toggle.color=${FG_OPAQUE}
text.toggle.inactive.color=${FG_92}
text.shadow=false
min_height=0

[Splitter]
indicator.size=32

[Scrollbar]
inherits=PanelButtonCommand
indicator.element=arrow
indicator.size=10

[ScrollbarSlider]
inherits=PanelButtonCommand
frame.element=scrollbarslider
interior=false
frame.left=6
frame.right=6
frame.top=6
frame.bottom=6
indicator.element=grip
indicator.size=13
frame.expansion=0

[ScrollbarGroove]
inherits=PanelButtonCommand
interior=false
frame=false

[MenuItem]
inherits=PanelButtonCommand
frame=true
frame.element=menuitem
interior.element=menuitem
indicator.element=menuitem
text.normal.color=${FG_OPAQUE}
text.focus.color=${FG_OPAQUE}
text.margin.top=2
text.margin.bottom=2
text.margin.left=15
text.margin.right=5
frame.top=2
frame.bottom=2
frame.left=2
frame.right=2
text.shadow=false
min_width=0
min_height=0

[MenuBar]
inherits=PanelButtonCommand
interior=true
interior.element=menubar
frame=true
frame.element=menubar
frame.left=2
frame.right=2
frame.top=0
frame.bottom=1

[MenuBarItem]
inherits=PanelButtonCommand
interior=false
frame=true
frame.element=menubaritem
frame.top=2
frame.bottom=3
frame.left=2
frame.right=2
text.margin.left=4
text.margin.right=4
text.margin.top=0
text.margin.bottom=2
text.normal.color=${FG_OPAQUE}
text.focus.color=${ACCENT}
text.shadow=false
min_width=0
min_height=0

[TitleBar]
inherits=PanelButtonCommand
frame=false
interior.element=titlebar
indicator.size=12
indicator.element=mdi
text.normal.color=${DIMMED_FG}
text.focus.color=${FG_OPAQUE}
text.bold=true
text.italic=true

[ComboBox]
inherits=PanelButtonCommand
frame.element=btn
frame.expandedElement=button

[Menu]
inherits=PanelButtonCommand
frame.top=1
frame.bottom=1
frame.left=1
frame.right=1
frame.element=menu
interior.element=menu
text.normal.color=${FG_OPAQUE}
text.shadow=false

[GroupBox]
inherits=GenericFrame
frame=true
frame.element=group
text.margin=0
frame.top=4
frame.bottom=4
frame.left=4
frame.right=4
text.normal.color=${FG_OPAQUE}
text.press.color=${FG_OPAQUE}
text.focus.color=${FG_OPAQUE}

[TabBarFrame]
inherits=PanelButtonCommand
frame.top=3
frame.bottom=5
frame.left=3
frame.right=3
frame=true
interior=true
frame.element=tabbarframe
interior.element=tabbarframe

[ToolTip]
inherits=GenericFrame
frame.top=6
frame.bottom=6
frame.left=6
frame.right=6
interior=true
text.margin=0
interior.element=tooltip
frame.element=tooltip

[StatusBar]
inherits=GenericFrame
frame=false
interior=false
KVEOF

# Select the active Kvantum theme
cat > "$HOME/.config/Kvantum/kvantum.kvconfig" << KVCFG
[General]
theme=${APP_DISPLAY}
KVCFG

echo "[gtk-qt-theme] Kvantum: ${APP_DISPLAY} theme generated (rounded corners, adwaita-style)"

# ═══════════════════════════════════════════════════════════════
# GSettings + xsettingsd
# ═══════════════════════════════════════════════════════════════
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null || true
gsettings set org.gnome.desktop.interface gtk-theme "${APP_THEME_KEY}" 2>/dev/null || true
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
# Qt: KDE platform theme uses ${APP_DISPLAY}.colors via kdeglobals
# ═══════════════════════════════════════════════════════════════
# KDE platform theme (QT_QPA_PLATFORMTHEME=kde) reads
# kdeglobals to find the active color scheme, then loads
# the .colors file from ~/.local/share/color-schemes/
# ${APP_DISPLAY}.colors is generated in the next section below.

# ═══════════════════════════════════════════════════════════════
# KDE color scheme — ${APP_DISPLAY}.colors
# ═══════════════════════════════════════════════════════════════
COLORS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/color-schemes"
mkdir -p "$COLORS_DIR"

cat > "$COLORS_DIR/${APP_DISPLAY}.colors" << EOF
[ColorScheme]
Author=${APP_DISPLAY}
Name=${APP_DISPLAY}
Comment=Generated from accent ${ACCENT}

[ColorEffects:Disabled]
Color=0,0,0
ColorAmount=0.5
ColorEffect=3
ContrastAmount=0
ContrastEffect=0
IntensityAmount=0
IntensityEffect=0

[ColorEffects:Inactive]
ChangeSelectionColor=true
Color=0,0,0
ColorAmount=0.05
ColorEffect=0
ContrastAmount=0.1
ContrastEffect=0
Enable=true
IntensityAmount=0
IntensityEffect=0

[Colors:Button]
BackgroundAlternate=${SURFACE_R},${SURFACE_G},${SURFACE_B}
BackgroundNormal=${SURFACE_LOW_R},${SURFACE_LOW_G},${SURFACE_LOW_B}
DecorationFocus=${ACCENT_R},${ACCENT_G},${ACCENT_B}
DecorationHover=${ACCENT_R},${ACCENT_G},${ACCENT_B}
ForegroundActive=${ACCENT_R},${ACCENT_G},${ACCENT_B}
ForegroundInactive=${DIMMED_FG_R},${DIMMED_FG_G},${DIMMED_FG_B}
ForegroundLink=${ACCENT_R},${ACCENT_G},${ACCENT_B}
ForegroundNormal=${FG_R},${FG_G},${FG_B}
ForegroundNegative=192,28,40
ForegroundNeutral=${FG_R},${FG_G},${FG_B}
ForegroundPositive=70,190,100
ForegroundVisited=${DH_R},${DH_G},${DH_B}

[Colors:Complementary]
BackgroundAlternate=${SURFACE_R},${SURFACE_G},${SURFACE_B}
BackgroundNormal=${SURFACE_R},${SURFACE_G},${SURFACE_B}
DecorationFocus=${ACCENT_R},${ACCENT_G},${ACCENT_B}
DecorationHover=${ACCENT_R},${ACCENT_G},${ACCENT_B}
ForegroundActive=${ACCENT_R},${ACCENT_G},${ACCENT_B}
ForegroundInactive=${DIMMED_FG_R},${DIMMED_FG_G},${DIMMED_FG_B}
ForegroundLink=${ACCENT_R},${ACCENT_G},${ACCENT_B}
ForegroundNormal=${FG_R},${FG_G},${FG_B}
ForegroundNegative=192,28,40
ForegroundNeutral=${FG_R},${FG_G},${FG_B}
ForegroundPositive=70,190,100
ForegroundVisited=${DH_R},${DH_G},${DH_B}

[Colors:Header]
BackgroundAlternate=${BG_R},${BG_G},${BG_B}
BackgroundNormal=${BG_R},${BG_G},${BG_B}
DecorationFocus=${ACCENT_R},${ACCENT_G},${ACCENT_B}
DecorationHover=${ACCENT_R},${ACCENT_G},${ACCENT_B}
ForegroundActive=${ACCENT_R},${ACCENT_G},${ACCENT_B}
ForegroundInactive=${DIMMED_FG_R},${DIMMED_FG_G},${DIMMED_FG_B}
ForegroundLink=${ACCENT_R},${ACCENT_G},${ACCENT_B}
ForegroundNormal=${FG_R},${FG_G},${FG_B}
ForegroundNegative=192,28,40
ForegroundNeutral=${FG_R},${FG_G},${FG_B}
ForegroundPositive=70,190,100
ForegroundVisited=${DH_R},${DH_G},${DH_B}

[Colors:Selection]
BackgroundAlternate=${ACCENT_R},${ACCENT_G},${ACCENT_B}
BackgroundNormal=${ACCENT_BG_R},${ACCENT_BG_G},${ACCENT_BG_B}
DecorationFocus=${ACCENT_R},${ACCENT_G},${ACCENT_B}
DecorationHover=${ACCENT_R},${ACCENT_G},${ACCENT_B}
ForegroundActive=255,255,255
ForegroundInactive=200,200,200
ForegroundLink=255,255,255
ForegroundNormal=255,255,255
ForegroundNegative=255,255,255
ForegroundNeutral=255,255,255
ForegroundPositive=255,255,255
ForegroundVisited=255,255,255

[Colors:Tooltip]
BackgroundAlternate=${SURFACE_ALT_R},${SURFACE_ALT_G},${SURFACE_ALT_B}
BackgroundNormal=${SURFACE_R},${SURFACE_G},${SURFACE_B}
DecorationFocus=${ACCENT_R},${ACCENT_G},${ACCENT_B}
DecorationHover=${ACCENT_R},${ACCENT_G},${ACCENT_B}
ForegroundActive=${ACCENT_R},${ACCENT_G},${ACCENT_B}
ForegroundInactive=${DIMMED_FG_R},${DIMMED_FG_G},${DIMMED_FG_B}
ForegroundLink=${ACCENT_R},${ACCENT_G},${ACCENT_B}
ForegroundNormal=${FG_R},${FG_G},${FG_B}
ForegroundNegative=192,28,40
ForegroundNeutral=${FG_R},${FG_G},${FG_B}
ForegroundPositive=70,190,100
ForegroundVisited=${DH_R},${DH_G},${DH_B}

[Colors:View]
BackgroundAlternate=${SURFACE_R},${SURFACE_G},${SURFACE_B}
BackgroundNormal=${BG_R},${BG_G},${BG_B}
DecorationFocus=${ACCENT_R},${ACCENT_G},${ACCENT_B}
DecorationHover=${ACCENT_R},${ACCENT_G},${ACCENT_B}
ForegroundActive=${ACCENT_R},${ACCENT_G},${ACCENT_B}
ForegroundInactive=${DIMMED_FG_R},${DIMMED_FG_G},${DIMMED_FG_B}
ForegroundLink=${ACCENT_R},${ACCENT_G},${ACCENT_B}
ForegroundNormal=${FG_R},${FG_G},${FG_B}
ForegroundNegative=192,28,40
ForegroundNeutral=${FG_R},${FG_G},${FG_B}
ForegroundPositive=70,190,100
ForegroundVisited=${DH_R},${DH_G},${DH_B}

[Colors:Window]
BackgroundAlternate=${SURFACE_R},${SURFACE_G},${SURFACE_B}
BackgroundNormal=${BG_R},${BG_G},${BG_B}
DecorationFocus=${ACCENT_R},${ACCENT_G},${ACCENT_B}
DecorationHover=${ACCENT_R},${ACCENT_G},${ACCENT_B}
ForegroundActive=${ACCENT_R},${ACCENT_G},${ACCENT_B}
ForegroundInactive=${DIMMED_FG_R},${DIMMED_FG_G},${DIMMED_FG_B}
ForegroundLink=${ACCENT_R},${ACCENT_G},${ACCENT_B}
ForegroundNormal=${FG_R},${FG_G},${FG_B}
ForegroundNegative=192,28,40
ForegroundNeutral=${FG_R},${FG_G},${FG_B}
ForegroundPositive=70,190,100
ForegroundVisited=${DH_R},${DH_G},${DH_B}
EOF

# ═══════════════════════════════════════════════════════════════
# kdeglobals — ${APP_DISPLAY} color scheme + Papirus-Dark icons
# ═══════════════════════════════════════════════════════════════
cat > "$HOME/.config/kdeglobals" << KDECEOF
[General]
ColorScheme=${APP_DISPLAY}
font=${FONT_SANS},10,-1,5,50,0,0,0,0,0
fixed=${FONT_MONO},10,-1,5,50,0,0,0,0,0
TerminalApplication=konsole

[Icons]
Theme=Papirus-Dark

[KDE]
widgetStyle=kvantum

[UiSettings]
ColorScheme=${APP_DISPLAY}
KDECEOF

echo "[gtk-qt-theme] Done — GTK2/3/4 + Qt themes generated from ${ACCENT}"

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
echo "[gtk-qt-theme] GTK:  custom '${APP_NAME}' theme (inherits adw-gtk3-dark)"
echo "[gtk-qt-theme] Qt:   Kvantum ${APP_DISPLAY} theme (adwaita-style, rounded corners)"
echo "[gtk-qt-theme] Icons: Papirus-Dark"

# ── Live reload Kvantum for running Qt apps ──────────────────────────
if command -v kvantummanager &>/dev/null && pgrep -x kvantummanager &>/dev/null; then
  kvantummanager --set "${APP_DISPLAY}" 2>/dev/null && \
    echo "[gtk-qt-theme] Kvantum: reloaded in running Qt apps" || true
fi

# ── Notify xsettingsd to reload GTK settings ─────────────────────────
if pgrep -x xsettingsd &>/dev/null; then
  pkill -SIGHUP -x xsettingsd 2>/dev/null && \
    echo "[gtk-qt-theme] xsettingsd: reloaded GTK settings" || true
fi

echo "[gtk-qt-theme]"
echo "[gtk-qt-theme] Some apps may need restart. Flatpak: run"
echo "[gtk-qt-theme]   flatpak override --user --filesystem=xdg-config/gtk-3.0:ro"
echo "[gtk-qt-theme]   flatpak override --user --filesystem=xdg-config/gtk-4.0:ro"
