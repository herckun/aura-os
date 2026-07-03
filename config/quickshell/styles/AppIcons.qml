pragma Singleton
import QtQuick
import Quickshell

Singleton {
  id: root

  readonly property string fontFamily: "\"JetBrainsMono Nerd Font Mono\", \"JetBrainsMono Nerd Font\", \"FiraCode Nerd Font Mono\", monospace"

  function iconForClass(appClass: string): string {
    if (!appClass || appClass.length === 0) return "\uf15c"
    var c = appClass.toLowerCase()

    if (c === "kitty") return "\uf489"
    if (c === "alacritty" || c === "wezterm" || c === "foot" || c === "footclient") return "\uf120"
    if (c === "gnome-terminal" || c === "konsole" || c === "xterm" || c === "urxvt" || c === "st") return "\uf120"

    if (c === "firefox") return "\uf269"
    if (c === "google-chrome" || c === "chromium" || c === "brave-browser" || c === "vivaldi" || c === "opera" || c === "epiphany" || c === "qutebrowser") return "\uf0ac"

    if (c === "thunar" || c === "nautilus" || c === "dolphin" || c === "nemo" || c === "pcmanfm" || c === "spacefm" || c === "doublecmd") return "\uf07b"
    if (c === "ranger" || c === "lf" || c === "nnn" || c === "yazi") return "\uf07b"

    if (c === "code" || c === "code-oss" || c === "vscodium" || c === "cursor" || c === "zed") return "\uf121"
    if (c === "sublime_text" || c === "atom") return "\uf15c"

    if (c === "vim" || c === "nvim" || c === "neovim" || c === "helix") return "\ue62b"
    if (c === "emacs") return "\ue779"

    if (c === "gedit" || c === "kate" || c === "kwrite" || c === "geany" || c === "mousepad" || c === "xed") return "\uf15c"

    if (c === "mpv" || c === "vlc" || c === "celluloid" || c === "smplayer" || c === "totem" || c === "playerctl") return "\uf04b"
    if (c === "spotify") return "\uf1bc"
    if (c === "audacious" || c === "rhythmbox" || c === "lollypop" || c === "cmus") return "\uf001"

    if (c === "feh" || c === "sxiv" || c === "nsxiv" || c === "imv" || c === "eog" || c === "gwenview" || c === "eye-of-mate" || c === "nomacs") return "\uf03e"

    if (c === "discord") return "\uf392"
    if (c === "telegram-desktop") return "\uf2c6"
    if (c === "signal" || c === "element") return "\uf27a"
    if (c === "slack") return "\uf198"
    if (c === "thunderbird") return "\uf0e0"
    if (c === "hexchat") return "\uf086"
    if (c === "zoom" || c === "teams" || c === "skype") return "\uf095"
    if (c === "mumble") return "\uf130"

    if (c === "gnome-system-monitor" || c === "htop" || c === "btop" || c === "btop++" || c === "stacer") return "\uf0e4"
    if (c === "gnome-tweaks" || c === "gnome-settings") return "\uf013"
    if (c === "nm-connection-editor") return "\uf0ac"
    if (c === "blueman-manager") return "\uf294"
    if (c === "pavucontrol" || c === "alsamixer") return "\uf028"
    if (c === "bitwarden" || c === "keepassxc" || c === "1password") return "\uf023"
    if (c === "gparted") return "\uf085"
    if (c === "timeshift") return "\uf1da"
    if (c === "arandr") return "\uf337"

    if (c === "libreoffice-writer") return "\uf15c"
    if (c === "libreoffice-calc") return "\uf0ce"
    if (c === "libreoffice-impress") return "\uf008"
    if (c === "libreoffice-draw" || c === "krita" || c === "krita2" || c === "gimp" || c === "inkscape" || c === "insomnia") return "\uf1fc"
    if (c === "libreoffice-base") return "\uf1c0"
    if (c === "evince" || c === "zathura" || c === "okular" || c === "epdfview" || c === "foliate" || c === "calibre") return "\uf02d"

    if (c === "blender") return "\uf021"

    if (c === "gitkraken" || c === "sublime_merge") return "\uf126"
    if (c === "github-desktop") return "\uf09b"
    if (c === "postman") return "\uf0c3"
    if (c === "dbeaver" || c === "datagrip") return "\uf1c0"

    if (c.indexOf("jetbrains") >= 0 || c === "idea" || c === "pycharm" || c === "webstorm" || c === "rider" || c === "clion" || c === "goland" || c === "phpstorm" || c === "rubymine") return "\uf121"

    if (c === "steam" || c === "lutris" || c === "heroic" || c === "wine" || c === "bottles") return "\uf1b6"
    if (c === "retroarch" || c === "mupen64plus") return "\uf11b"

    if (c === "gnome-calculator") return "\uf07a"
    if (c === "file-roller" || c === "ark" || c === "peazip") return "\uf187"
    if (c === "obsidian" || c === "logseq") return "\uf2d2"
    if (c === "notion") return "\uf15c"
    if (c === "godot" || c === "godot3" || c === "unity") return "\uf03d"
    if (c === "android-studio") return "\uf17b"
    if (c.indexOf("appimage") >= 0) return "\uf1b2"

    return "\uf15c"
  }
}
