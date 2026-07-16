#!/usr/bin/env bash
# ── KDE Color Scheme + kdeglobals Generator ─────────────────
# Generates ~/.local/share/color-schemes/<name>.colors
# and ~/.config/kdeglobals for Qt/KDE integration.

generate_kde() {
  local COLORS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/color-schemes"
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
BackgroundNormal=${SURFACE_ALT_R},${SURFACE_ALT_G},${SURFACE_ALT_B}
DecorationFocus=${ACCENT_R},${ACCENT_G},${ACCENT_B}
DecorationHover=${ACCENT_R},${ACCENT_G},${ACCENT_B}
ForegroundActive=${ACCENT_R},${ACCENT_G},${ACCENT_B}
ForegroundInactive=${DIMMED_FG_R},${DIMMED_FG_G},${DIMMED_FG_B}
ForegroundLink=${ACCENT_R},${ACCENT_G},${ACCENT_B}
ForegroundNormal=${FG_R},${FG_G},${FG_B}
ForegroundNegative=192,28,40
ForegroundNeutral=${FG_R},${FG_G},${FG_B}
ForegroundPositive=70,190,100
ForegroundVisited=${AH_R},${AH_G},${AH_B}

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
ForegroundVisited=${AH_R},${AH_G},${AH_B}

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
ForegroundVisited=${AH_R},${AH_G},${AH_B}

[Colors:Selection]
BackgroundAlternate=${ACCENT_BG_R},${ACCENT_BG_G},${ACCENT_BG_B}
BackgroundNormal=${ACCENT_R},${ACCENT_G},${ACCENT_B}
DecorationFocus=${ACCENT_R},${ACCENT_G},${ACCENT_B}
DecorationHover=${ACCENT_R},${ACCENT_G},${ACCENT_B}
ForegroundActive=255,255,255
ForegroundInactive=${DIMMED_FG_R},${DIMMED_FG_G},${DIMMED_FG_B}
ForegroundLink=255,255,255
ForegroundNormal=255,255,255
ForegroundNegative=192,28,40
ForegroundNeutral=255,255,255
ForegroundPositive=70,190,100
ForegroundVisited=255,255,255

[Colors:Tooltip]
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
ForegroundVisited=${AH_R},${AH_G},${AH_B}

[Colors:View]
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
ForegroundVisited=${AH_R},${AH_G},${AH_B}

[Colors:Window]
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
ForegroundVisited=${AH_R},${AH_G},${AH_B}

[Colors:Scrollbar]
BackgroundAlternate=${SURFACE_R},${SURFACE_G},${SURFACE_B}
BackgroundNormal=${SURFACE_ALT_R},${SURFACE_ALT_G},${SURFACE_ALT_B}
DecorationFocus=${ACCENT_R},${ACCENT_G},${ACCENT_B}
DecorationHover=${ACCENT_R},${ACCENT_G},${ACCENT_B}
ForegroundActive=${ACCENT_R},${ACCENT_G},${ACCENT_B}
ForegroundInactive=${DIMMED_FG_R},${DIMMED_FG_G},${DIMMED_FG_B}
ForegroundLink=${ACCENT_R},${ACCENT_G},${ACCENT_B}
ForegroundNormal=${FG_R},${FG_G},${FG_B}
ForegroundNegative=192,28,40
ForegroundNeutral=${FG_R},${FG_G},${FG_B}
ForegroundPositive=70,190,100
ForegroundVisited=${AH_R},${AH_G},${AH_B}

[Colors:TitleBar]
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
ForegroundVisited=${AH_R},${AH_G},${AH_B}
EOF

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

  echo "[gtk-qt-theme] KDE: color scheme generated"
}
