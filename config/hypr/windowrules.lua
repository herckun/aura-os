hl.window_rule({
  name  = "qs-nodim",
  match = { class = "qs" },
  no_dim = true,
})
hl.window_rule({
  name  = "qs-nofocus",
  match = { class = "qs" },
  no_focus = true,
})
hl.window_rule({
  name  = "qs-noround",
  match = { class = "qs" },
  rounding = 0,
})
hl.window_rule({
  name  = "qs-noborder",
  match = { class = "qs" },
  border_size = 0,
})

hl.window_rule({
  name  = "float-pavucontrol",
  match = { class = "pavucontrol" },
  float = true,
  center = true,
})
hl.window_rule({
  name  = "float-blueman",
  match = { class = "blueman-manager" },
  float = true,
})
hl.window_rule({
  name  = "float-pip",
  match = { title = "Picture-in-Picture" },
  float = true,
})
hl.window_rule({
  name  = "float-settings",
  match = { title = "Library|Settings|System.Preferences" },
  float = true,
})
hl.window_rule({
  name  = "float-qs-settings",
  match = { class = "org.quickshell", title = "Settings" },
  float = true,
  center = true,
})
hl.window_rule({
  name  = "float-kdialog",
  match = { class = "org.kde.kdialog" },
  float = true,
  center = true,
  size  = { 600, 400 },
})
hl.window_rule({
  name  = "float-calculator",
  match = { class = "org.gnome.Calculator" },
  float = true,
})

hl.window_rule({
  name  = "hide-xwaylandvideobridge",
  match = { class = "xwaylandvideobridge" },
  opacity = 0.0,
  no_anim = true,
  no_focus = true,
  no_initial_focus = true,
  no_blur = true,
  max_size = { 1, 1 },
})

hl.window_rule({
  name  = "dim-pavucontrol",
  match = { class = "pavucontrol" },
  dim_around = true,
})
hl.window_rule({
  name  = "dim-blueman",
  match = { class = "blueman-manager" },
  dim_around = true,
})

hl.window_rule({
  name  = "opacity-kitty",
  match = { class = "kitty" },
  opacity = 0.92,
})
hl.window_rule({
  name  = "opacity-alacritty",
  match = { class = "Alacritty" },
  opacity = 0.92,
})
hl.window_rule({
  name  = "opacity-foot",
  match = { class = "foot" },
  opacity = 0.92,
})

hl.window_rule({
  name  = "fullscreen-mpv",
  match = { class = "mpv" },
  fullscreen = true,
})
hl.window_rule({
  name  = "fullscreen-vlc",
  match = { class = "vlc" },
  fullscreen = true,
})
hl.window_rule({
  name  = "border-fullscreen",
  match = { fullscreen = true },
  border_size = 2,
})

-- QuickShell layer blur
hl.layer_rule({
  name  = "qs-blur",
  match = { namespace = "quickshell" },
  blur = true,
  ignore_alpha = 0.1,
})

-- Desktop widget blur
hl.layer_rule({
  name  = "qs-desktop-blur",
  match = { namespace = "quickshell:desktop" },
  blur = true,
  ignore_alpha = 0.5,
  xray = false,
})

-- wleave layer blur
hl.layer_rule({
  name  = "wleave-blur",
  match = { namespace = "wleave" },
  blur = true,
  ignore_alpha = 0.0,
})
