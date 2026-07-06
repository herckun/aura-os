<p align="center">
  <img src="assets/logo.png" width="96" alt="AuraOS logo">
</p>

<h1 align="center">AuraOS</h1>

<p align="center">
  A desktop environment for Arch Linux, built on <a href="https://hyprland.org">Hyprland</a> and <a href="https://quickshell.org">QuickShell</a>.<br>
  Opinionated enough to feel like an OS, modular enough to make it yours.
</p>

<p align="center">
  <a href="https://discord.gg/HD4Cvmpdnv">Discord</a> ·
  <a href="#install">Install</a> ·
  <a href="#features">Features</a> ·
  <a href="#plugins">Plugins</a>
</p>

---

<p align="center">
  <img src="assets/screenshots/desktop.png" alt="Desktop" width="100%">
</p>

One installer sets up the shell, themes, fonts, terminal and login screen. Switch between 11 themes and 5 shell modes on the fly, and arrange 40+ plugins with a drag-and-drop editor.

## Features

### Shell

Bar, control center, notification center, launcher, overview, app switcher, OSD, toasts and a dynamic smart island — one design system, all QML.

<table>
  <tr>
    <td width="33%">
      <img src="assets/screenshots/overview.png" alt="Overview and launcher">
      <sub><b>Overview</b> — app search, calculator, plugin <code>/commands</code>, workspaces, todo, notes, clipboard, timer</sub>
    </td>
    <td width="33%">
      <img src="assets/screenshots/notifications.png" alt="Notifications">
      <sub><b>Notifications</b> — toasts with actions that stack cleanly</sub>
    </td>
    <td width="33%">
      <img src="assets/screenshots/cheatsheet.png" alt="Keybinding cheatsheet">
      <sub><b>Cheatsheet</b> — every keybinding, one keypress away</sub>
    </td>
  </tr>
</table>

### Settings

Everything is configurable from one place — no config files required, though they're there if you want them.

<table>
  <tr>
    <td width="50%">
      <img src="assets/screenshots/settings-dashboard.png" alt="Dashboard">
      <sub><b>Dashboard</b> — power profiles and live system stats</sub>
    </td>
    <td width="50%">
      <img src="assets/screenshots/settings-connectivity.png" alt="Connectivity">
      <sub><b>Connectivity</b> — Wi-Fi, wired, Bluetooth and VPN in one page</sub>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <img src="assets/screenshots/settings-keybindings.png" alt="Keybindings">
      <sub><b>Keybindings</b> — searchable editor with conflict detection</sub>
    </td>
    <td width="50%">
      <img src="assets/screenshots/settings-wallpaper.png" alt="Wallpaper">
      <sub><b>Wallpaper</b> — palette, history, auto-cycle and an online carousel</sub>
    </td>
  </tr>
</table>

### Shell modes

One desktop, five personalities. A mode reshapes spacing, effects and bar behavior in one click.

<table>
  <tr>
    <td width="33%">
      <img src="assets/screenshots/mode-default.png" alt="Default mode">
      <sub><b>Default</b> — docked bar, hot areas, blur and glass</sub>
    </td>
    <td width="33%">
      <img src="assets/screenshots/mode-zen.png" alt="Zen mode">
      <sub><b>Zen</b> — floating bar, roomy spacing</sub>
    </td>
    <td width="33%">
      <img src="assets/screenshots/mode-focus.png" alt="Focus mode">
      <sub><b>Focus</b> — minimal bar, compact and flat</sub>
    </td>
  </tr>
  <tr>
    <td width="33%">
      <img src="assets/screenshots/mode-gaming.png" alt="Gaming mode">
      <sub><b>Gaming</b> — no bar, no gaps, no animations</sub>
    </td>
    <td width="33%">
      <img src="assets/screenshots/mode-theater.png" alt="Theater mode">
      <sub><b>Theater</b> — plush spacing, slow motion</sub>
    </td>
    <td width="33%"></td>
  </tr>
</table>

### Theming

11 themes, switchable at runtime — the whole desktop restyles instantly. Each theme brings its own palette and font stack, and reaches beyond the shell: GTK, Qt, kitty, fish, SDDM and wleave are regenerated on every switch. Accents can be picked by hand or extracted from your wallpaper. A theme is one JSON file in `config/quickshell/styles/themes/` — drop in your own.

<table>
  <tr>
    <td width="50%">
      <img src="assets/screenshots/themes.png" alt="Theme picker">
      <sub><b>The theme picker</b> — every card rendered in its own palette</sub>
    </td>
    <td width="50%">
      <img src="assets/screenshots/sddm.png" alt="SDDM login">
      <sub><b>The login screen follows</b> — SDDM with your wallpaper, avatar and accent</sub>
    </td>
  </tr>
</table>

<table>
  <tr>
    <td width="33%"><img src="assets/screenshots/theme-aura.png" alt="Aura"><sub><b>Aura</b></sub></td>
    <td width="33%"><img src="assets/screenshots/theme-catppuccin.png" alt="Catppuccin"><sub><b>Catppuccin</b></sub></td>
    <td width="33%"><img src="assets/screenshots/theme-dracula.png" alt="Dracula"><sub><b>Dracula</b></sub></td>
  </tr>
  <tr>
    <td width="33%"><img src="assets/screenshots/theme-everforest.png" alt="Everforest"><sub><b>Everforest</b></sub></td>
    <td width="33%"><img src="assets/screenshots/theme-github.png" alt="GitHub"><sub><b>GitHub</b></sub></td>
    <td width="33%"><img src="assets/screenshots/theme-gruvbox.png" alt="Gruvbox"><sub><b>Gruvbox</b></sub></td>
  </tr>
  <tr>
    <td width="33%"><img src="assets/screenshots/theme-nord.png" alt="Nord"><sub><b>Nord</b></sub></td>
    <td width="33%"><img src="assets/screenshots/theme-paper.png" alt="Paper"><sub><b>Paper</b></sub></td>
    <td width="33%"><img src="assets/screenshots/theme-rosepine.png" alt="Rosé Pine"><sub><b>Rosé Pine</b></sub></td>
  </tr>
  <tr>
    <td width="33%"><img src="assets/screenshots/theme-solarized.png" alt="Solarized"><sub><b>Solarized</b></sub></td>
    <td width="33%"><img src="assets/screenshots/theme-tokyonight.png" alt="Tokyo Night"><sub><b>Tokyo Night</b></sub></td>
    <td width="33%"></td>
  </tr>
</table>

Turn down the color — monochrome mode takes the whole desktop to black and white, wallpaper included:

<table>
  <tr>
    <td width="50%">
      <img src="assets/screenshots/mono-off.png" alt="Monochrome off">
      <sub><b>Color</b></sub>
    </td>
    <td width="50%">
      <img src="assets/screenshots/mono-on.png" alt="Monochrome on">
      <sub><b>Monochrome</b> — same desktop, one toggle</sub>
    </td>
  </tr>
</table>

### Desktop

- Widgets — clock, synced lyrics, audio visualizer, resource monitor — draggable, scalable, and aware of what's behind them
- Wallpaper engine with palette extraction, history, auto-cycle and an online carousel
- VPN quick toggle backed by NetworkManager, with ProtonVPN and Windscribe plugins
- Performance profiles, including a battery saver that tones down effects

## Requirements

- Arch Linux (or an Arch-based distro with `pacman` and `yay`)
- A GPU with Vulkan support — NVIDIA, AMD and Intel are detected during install

The installer takes care of the rest: Hyprland, QuickShell, fonts, icons, sounds.

## Install

```sh
git clone https://github.com/herckun/aura-os.git
cd aura-os
./install.sh
```

The installer is interactive and backs up your existing configs first. For an unattended setup with good defaults:

```sh
./install.sh --express
```

### Options

| Flag | Effect |
|---|---|
| `--express` | Install everything with best defaults |
| `--expert` | Choose exactly what runs |
| `--no-deps` | Skip package installation |
| `--no-backup` | Skip the config snapshot |
| `--skip-icons` / `--skip-sfx` | Skip icon / sound sync |
| `--reset-layout` | Reset the plugin layout to defaults |
| `--uninstall` | Remove AuraOS and restore your backups |

To update, pull and run `./install.sh` again — your settings, theme and layout are preserved.

## Plugins

40+ plugins cover everything from bar workspaces and media controls to Docker, systemd and SSH. The layout editor in Settings → Plugins lets you drag them between every surface: bar, control center, overview, dashboard, desktop.

<p align="center">
  <img src="assets/screenshots/layout-editor.png" alt="Layout editor" width="100%">
  <br><sub><b>The layout editor</b> — drag to rearrange, changes apply instantly</sub>
</p>

Writing a plugin is one QML file extending `BasePlugin`:

```sh
python3 dev/generate-plugin.py "My Plugin" --category community
```

## Community

Questions, showcases, themes and plugin ideas — join the [Discord](https://discord.gg/HD4Cvmpdnv).

## License

AuraOS is released under the [MIT License](LICENSE).

## Credits

- [Hyprland](https://hyprland.org) and [QuickShell](https://quickshell.org), which AuraOS is built on
- [Tabler Icons](https://tabler.io/icons) for the icon set
- [Wallhaven](https://wallhaven.cc) as the wallpaper carousel source
- Fonts from [Google Fonts](https://fonts.google.com)
