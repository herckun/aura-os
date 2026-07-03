-- Hyprland Configuration
-- Lua format (Hyprland 0.55+)

require("monitors")
require("decorations")
require("animations")
require("windowrules")
require("keybinds")

-- Persistent workspaces (prevent renumbering when empty)
for i = 1, 10 do
    hl.workspace_rule({ workspace = tostring(i), persistent = true })
end

-- Autostart
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("qs")
    hl.exec_cmd("awww-daemon &")
    hl.exec_cmd("polkit-kde-agent")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("kdeconnect-indicator")
    hl.exec_cmd("xsettingsd &")
    hl.exec_cmd("xwaylandvideobridge")
end)

-- Environment
hl.env("XCURSOR_THEME", "Colloid-cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_STYLE_OVERRIDE", "kvantum")
hl.env("GTK_THEME", "@APP_NAME@:dark")
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- Misc settings
hl.config({
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        enable_swallow = true,
        swallow_regex = "^(kitty|foot|wezterm|alacritty)$",
        force_default_wallpaper = 0,
        animate_mouse_windowdragging = false,
        vrr = 0,
        on_focus_under_fullscreen = 2,
        initial_workspace_tracking = false,
        focus_on_activate = true,
    },
    binds = {
        hide_special_on_workspace_change = true,
    },
})

-- Debug
hl.config({
    debug = {
        vfr = true,
    },
})

-- Input
hl.config({
    input = {
        kb_layout = "us",
        numlock_by_default = true,
        follow_mouse = 1,
        touchpad = {
            natural_scroll = true,
            disable_while_typing = true,
            clickfinger_behavior = true,
            tap_to_click = true,
        },
        sensitivity = 0,
        accel_profile = "flat",
    },
})

-- Gestures
hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

-- General appearance
hl.config({
    general = {
        layout = "dwindle",
        gaps_in = 4,
        gaps_out = 8,
        border_size = 1,
        col = {
            active_border = "rgba(333333ff)",
            inactive_border = "rgba(111111ff)",
        },
        resize_on_border = true,
        no_focus_fallback = true,
        extend_border_grab_area = 15,
        hover_icon_on_border = true,
    },
})

-- Dwindle layout
hl.config({
    dwindle = {
        preserve_split = true,
        smart_split = false,
        smart_resizing = false,
        special_scale_factor = 0.8,
        split_width_multiplier = 1.0,
        use_active_for_splits = true,
        default_split_ratio = 0.52,
    },
})

-- Master layout
hl.config({
    master = {
        mfact = 0.55,
        new_on_top = false,
        new_status = "master",
        orientation = "center",
        special_scale_factor = 0.8,
    },
})

hl.config({
    xwayland = {
        force_zero_scaling = true
    }
})

-- Cursor
hl.config({
    cursor = {
        no_hardware_cursors = false,
    }
})

-- Blur lists (set via decoration.blur in decorations.lua)
