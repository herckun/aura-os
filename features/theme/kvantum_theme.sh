#!/usr/bin/env bash
# ── Kvantum Qt Theme Generator ──────────────────────────────
# Generates SVG + kvconfig for Qt apps.
# SVG elements use actual theme colors (not hardcoded grays).
# Kvconfig controls translucency and blur behavior.

generate_kvantum() {
  local KVANTUM_DIR="$HOME/.config/Kvantum/${APP_DISPLAY}"
  mkdir -p "$KVANTUM_DIR"

  # Generate SVG with theme colors
  cat > "$KVANTUM_DIR/${APP_DISPLAY}.svg" << SVGEOF
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 96 96">
  <rect id="button" x="0" y="0" width="96" height="96" rx="4" fill="${SURFACE_ALT_HEX}"/>
  <rect id="tbutton" x="0" y="0" width="96" height="96" rx="4" fill="${SURFACE_ALT_HEX}"/>
  <rect id="lineedit" x="0" y="0" width="96" height="96" rx="4" fill="${SURFACE_LOW_HEX}"/>
  <rect id="menu" x="0" y="0" width="96" height="96" rx="6" fill="${SURFACE_HEX}"/>
  <rect id="menuitem" x="0" y="0" width="96" height="96" fill="transparent"/>
  <rect id="menubar" x="0" y="0" width="96" height="96" fill="${BG_HEX}"/>
  <rect id="menubaritem" x="0" y="0" width="96" height="96" fill="transparent"/>
  <rect id="tooltip" x="0" y="0" width="96" height="96" rx="6" fill="${SURFACE_HEX}"/>
  <rect id="progress" x="0" y="0" width="96" height="96" rx="4" fill="${SURFACE_ALT_HEX}"/>
  <rect id="progress-pattern" x="0" y="0" width="96" height="96" rx="4" fill="${ACCENT}"/>
  <rect id="scrollbarslider" x="0" y="0" width="96" height="96" rx="4" fill="#444444"/>
  <rect id="itemview" x="0" y="0" width="96" height="96" fill="${BG_HEX}"/>
  <rect id="header" x="0" y="0" width="96" height="96" fill="${BG_HEX}"/>
  <rect id="dock" x="0" y="0" width="96" height="96" fill="${BG_HEX}"/>
  <rect id="tabbarframe" x="0" y="0" width="96" height="96" fill="${BG_HEX}"/>
  <rect id="common" x="0" y="0" width="96" height="96" fill="${BG_HEX}"/>
  <rect id="slider" x="0" y="0" width="96" height="96" fill="${SURFACE_ALT_HEX}"/>
  <rect id="slidercursor" x="0" y="0" width="96" height="96" rx="12" fill="${FG}"/>
  <rect id="radio" x="0" y="0" width="96" height="96" fill="transparent"/>
  <rect id="checkbox" x="0" y="0" width="96" height="96" fill="transparent"/>
  <rect id="titlebar" x="0" y="0" width="96" height="96" fill="${BG_HEX}"/>
  <rect id="none" x="0" y="0" width="96" height="96" fill="transparent"/>
  <rect id="btn" x="0.5" y="0.5" width="95" height="95" rx="4" fill="none" stroke="${BORDER}" stroke-width="1"/>
  <rect id="tbtn" x="0.5" y="0.5" width="95" height="95" rx="4" fill="none" stroke="${BORDER}" stroke-width="1"/>
  <rect id="le" x="0.5" y="0.5" width="95" height="95" rx="4" fill="none" stroke="${BORDER}" stroke-width="1"/>
  <rect id="group" x="0.5" y="0.5" width="95" height="95" rx="4" fill="none" stroke="${BORDER}" stroke-width="1"/>
  <path id="arrow" d="M48,36 L56,48 L40,48 Z" fill="${DIMMED_FG}"/>
  <path id="arrow-down" d="M40,40 L48,52 L56,40 Z" fill="${DIMMED_FG}"/>
  <path id="iarrow" d="M48,36 L56,48 L40,48 Z" fill="${DIMMED_FG}"/>
  <path id="tree" d="M48,36 L56,48 L40,48 Z" fill="${DIMMED_FG}"/>
  <path id="tab" d="M0,80 L96,80 L96,96 L0,96 Z" fill="${ACCENT}"/>
  <g id="mdi">
    <rect x="20" y="20" width="56" height="56" rx="4" fill="none" stroke="${DIMMED_FG}" stroke-width="2"/>
    <line x1="20" y1="20" x2="76" y2="76" stroke="${DIMMED_FG}" stroke-width="2"/>
    <line x1="76" y1="20" x2="20" y2="76" stroke="${DIMMED_FG}" stroke-width="2"/>
  </g>
  <g id="resize-grip">
    <line x1="80" y1="88" x2="88" y2="96" stroke="${DIMMED_FG}" stroke-width="1.5"/>
    <line x1="72" y1="88" x2="88" y2="96" stroke="${DIMMED_FG}" stroke-width="1.5" opacity="0.6"/>
    <line x1="88" y1="80" x2="88" y2="96" stroke="${DIMMED_FG}" stroke-width="1.5" opacity="0.6"/>
  </g>
  <g id="grip">
    <line x1="44" y1="36" x2="52" y2="36" stroke="${DIMMED_FG}" stroke-width="1.5"/>
    <line x1="44" y1="44" x2="52" y2="44" stroke="${DIMMED_FG}" stroke-width="1.5"/>
    <line x1="44" y1="52" x2="52" y2="52" stroke="${DIMMED_FG}" stroke-width="1.5"/>
  </g>
  <rect id="toolbar" x="40" y="44" width="16" height="8" rx="2" fill="${DIMMED_FG}"/>
</svg>
SVGEOF

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
button.color=${SURFACE_ALT_HEX}
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
frame.element=group
interior.element=group
frame.top=4
frame.bottom=4
frame.left=4
frame.right=4
text.normal.color=${FG_OPAQUE}

[TabBar]
inherits=PanelButtonCommand
frame.top=3
frame.bottom=0
frame.left=3
frame.right=3
frame.element=tabbarframe
interior.element=tabbarframe
text.normal.color=${DIMMED_FG}
text.focus.color=${FG_OPAQUE}
text.bold=true
text.margin.top=2
text.margin.bottom=2

[Tab]
inherits=PanelButtonCommand
frame.top=0
frame.bottom=3
frame.left=2
frame.right=2
frame.element=tab
interior.element=tab
text.normal.color=${DIMMED_FG}
text.focus.color=${FG_OPAQUE}
text.bold=true
text.margin.top=2
text.margin.bottom=2

[TabActive]
inherits=Tab
text.normal.color=${FG_OPAQUE}

[TabPane]
frame.top=3
frame.bottom=3
frame.left=3
frame.right=3
frame=false
interior=false

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

[ScrollBars]
inherits=PanelButtonCommand
frame=false
interior=true
interior.element=scrollbarslider
slider.width=6
slider.min_length=30
slider.handle_length=20
no_arrow=false
button.type=scrollbar
scrollbar.type=scrollbar
min_ticks_paragraph=2
min_ticks_page=5

[Slider]
inherits=PanelButtonCommand
frame=false
interior=true
interior.element=slider
indicator.element=slidercursor
indicator.size=18
text.normal.color=${FG_OPAQUE}

[Toolbar]
inherits=PanelButtonCommand
frame.top=1
frame.bottom=1
frame.left=0
frame.right=0
frame=false
interior=true
interior.element=header
text.normal.color=${FG_OPAQUE}

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

[MenuItem]
inherits=PanelButtonCommand
frame=false
interior.element=menuitem
text.normal.color=${FG_OPAQUE}
text.focus.color=${ACCENT}
text.shadow=false
text.margin.top=2
text.margin.bottom=2
min_width=0
min_height=0

[MenuBar]
inherits=PanelButtonCommand
frame.top=2
frame.bottom=2
frame.left=2
frame.right=2
frame.element=menubar
interior.element=menubar
text.normal.color=${FG_OPAQUE}
text.shadow=false
spread_menubar=true
no_menu_light=false

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

  cat > "$HOME/.config/Kvantum/kvantum.kvconfig" << KVCFG
[General]
theme=${APP_DISPLAY}
KVCFG

  echo "[gtk-qt-theme] Kvantum: ${APP_DISPLAY} theme generated"
}
