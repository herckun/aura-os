#!/usr/bin/env python3
"""
Generate a new AuraDE plugin that extends BasePlugin (the golden rule).

BasePlugin already handles registration, enabled-state, PluginService signal
wiring, lifecycle and the _set/_setArray helpers — so this only scaffolds the
manifest, lifecycle hooks and one UI Component per location. See docs/PLUGINS.md.

Usage:
  dev/generate-plugin.py                         # interactive
  dev/generate-plugin.py "Net Speed" \
      --category extra --icon activity \
      --locations bar_right,overview \
      --settings "unit:select:mbit,showIcon:toggle:true"

Settings are "key:type:default" (types: toggle, stepper, text, select).
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
PLUGINS_DIR = REPO / "config" / "quickshell" / "services" / "plugins"
CATEGORIES = ("core", "extra", "community")
DEFAULT_AUTHOR = "herckun"
SHELL_VERSION = "2.0"   # AuraDE shell version plugins target (see core/AppInfo.qml)

# location -> UI Component property (mirrors PluginService.componentMap).
# Locations not listed here (e.g. "settings") have no UI component — their
# presence is settings-driven.
LOCATION_COMPONENT = {
    "connectivity": "connectivityComponent",
    "controlcenter_row": "controlCenterComponent",
    "controlcenter_toggle": "controlCenterToggle",
    "overview": "overviewComponent",
    "audio": "audioComponent",
    "appearance": "appearanceComponent",
    "wallpaper": "wallpaperComponent",
    "desktop": "desktopComponent",
    "about": "aboutComponent",
    "bar_left": "barComponent",
    "bar_center": "barComponent",
    "bar_right": "barComponent",
    "dashboard": "dashboardComponent",
}
KNOWN_LOCATIONS = list(LOCATION_COMPONENT.keys()) + ["settings"]
SETTING_DEFAULTS = {"toggle": "false", "stepper": "0", "text": '""', "select": '""'}


def pascal(name: str) -> str:
    parts = re.split(r"[^A-Za-z0-9]+", name)
    return "".join(p[:1].upper() + p[1:] for p in parts if p)


def plugin_id(name: str) -> str:
    return re.sub(r"[^a-z0-9]", "", name.lower())


def qml_bool_or(v: str, typ: str) -> str:
    if typ == "toggle":
        return "true" if str(v).lower() in ("1", "true", "yes", "on") else "false"
    if typ == "stepper":
        return str(v) if re.fullmatch(r"-?\d+", str(v)) else "0"
    return f'"{v}"'


def parse_settings(raw: str):
    out = []
    for chunk in filter(None, (c.strip() for c in raw.split(","))):
        bits = chunk.split(":")
        key = bits[0].strip()
        typ = (bits[1].strip() if len(bits) > 1 else "toggle").lower()
        if typ not in SETTING_DEFAULTS:
            typ = "toggle"
        default = bits[2].strip() if len(bits) > 2 else None
        out.append({"key": key, "type": typ, "default": default})
    return out


def render_settings(settings) -> str:
    if not settings:
        return "settings: []"
    lines = []
    for s in settings:
        dv = s["default"] if s["default"] is not None else None
        dv = qml_bool_or(dv, s["type"]) if dv is not None else SETTING_DEFAULTS[s["type"]]
        label = re.sub(r"[^A-Za-z0-9]+", " ", s["key"]).strip().upper()
        extra = ""
        if s["type"] == "stepper":
            extra = ", min: 0, max: 100, step: 1"
        lines.append(
            f'      {{ key: "{s["key"]}", label: "{label}", description: "", '
            f'type: "{s["type"]}", default: {dv}{extra} }}'
        )
    return "settings: [\n" + ",\n".join(lines) + "\n    ]"


def render_on_setting_changed(settings) -> str:
    if not settings:
        return "  function onSettingChanged(key, value): void {}"
    cases = "\n".join(
        f'    case "{s["key"]}": /* apply {s["key"]} */ break' for s in settings
    )
    return (
        "  function onSettingChanged(key, value): void {\n"
        "    switch (key) {\n"
        f"{cases}\n"
        "    }\n"
        "  }"
    )


def render_components(locations, name) -> str:
    seen, blocks = set(), []
    for loc in locations:
        prop = LOCATION_COMPONENT.get(loc)
        if not prop or prop in seen:
            continue
        seen.add(prop)
        blocks.append(
            f"  property Component {prop}: Column {{\n"
            f"    width: parent.width\n"
            f"    spacing: Theme.spaceSm\n\n"
            f'    SectionLabel {{ label: "{name.upper()}" }}\n\n'
            f"    Text {{\n"
            f'      text: "Edit {prop} in this plugin"\n'
            f"      color: Theme.textSecondary\n"
            f"      font.pixelSize: Theme.fontSizeCaption\n"
            f"      font.family: Theme.fontFamilyMono\n"
            f"    }}\n"
            f"  }}"
        )
    if not blocks:
        return "  // No UI location selected — add a `property Component <x>Component` when needed."
    return "\n\n".join(blocks)


TEMPLATE = '''pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../../styles"
import "../../../../components"
import "../../../../core"
import "../../../"

// ═══════════════════════════════════════════════════════════════════
//  {name} — extends BasePlugin (registration, enabled-state, signal
//  wiring, lifecycle and helpers are all handled by the base). Fill in
//  the sections below; keep the section headers (see docs/PLUGINS.md).
// ═══════════════════════════════════════════════════════════════════

BasePlugin {{
  id: root

  // ── Manifest ─────────────────────────────────────────────────────
  pluginId: "{id}"
  manifest: ({{
    author: "{author}",
    version: "1.0",
    shellVersion: "{shell_version}",
    name: "{name}",
    description: "{description}",
    icon: "{icon}",
    locations: {locations_json},
    icons: {{}},
    {settings}
  }})

  // ── Public state ─────────────────────────────────────────────────

  // ── Internal state ───────────────────────────────────────────────

  // ── Signal handlers ──────────────────────────────────────────────
  // Connections to OTHER services; PluginService signals are on the base.

  // ── Public API ───────────────────────────────────────────────────

  // ── Helpers ──────────────────────────────────────────────────────

  // ── Timers ───────────────────────────────────────────────────────

  // ── Lifecycle ────────────────────────────────────────────────────
  // Start polling / processes here (fires on enable + at startup if enabled).
  function onActivated(): void {{}}

  // Counterpart to onActivated.
  function onDeactivated(): void {{}}

{on_setting_changed}

  // Stop EVERY timer / process / poll this plugin owns. Called on disable
  // and destruction — must be safe to call repeatedly.
  function stopAllActivity(): void {{}}

  // ── UI components ────────────────────────────────────────────────
{components}
}}
'''


def ask(prompt, default=""):
    d = f" [{default}]" if default else ""
    try:
        val = input(f"{prompt}{d}: ").strip()
    except EOFError:
        val = ""
    return val or default


def interactive(args):
    print("── New AuraDE plugin ──")
    args.name = args.name or ask("Plugin name", "My Plugin")
    args.category = args.category or ask(f"Category ({'/'.join(CATEGORIES)})", "community")
    args.description = args.description or ask("Description", "")
    args.icon = args.icon or ask("Icon (tabler name)", "puzzle")
    print(f"  locations: {', '.join(KNOWN_LOCATIONS)}")
    args.locations = args.locations or ask("Locations (comma)", "overview")
    args.settings = args.settings or ask("Settings key:type:default (comma)", "")
    return args


def main():
    p = argparse.ArgumentParser(description="Generate a BasePlugin-based AuraDE plugin.")
    p.add_argument("name", nargs="?", help="Plugin display name (e.g. \"Net Speed\")")
    p.add_argument("--category", choices=CATEGORIES)
    p.add_argument("--description", "--desc", default=None)
    p.add_argument("--icon", default=None)
    p.add_argument("--author", default=DEFAULT_AUTHOR)
    p.add_argument("--locations", default=None, help="comma-separated location keys")
    p.add_argument("--settings", default=None, help='"key:type:default,..."')
    p.add_argument("--id", default=None, help="override plugin id (default: from name)")
    p.add_argument("--force", action="store_true", help="overwrite if the file exists")
    p.add_argument("--no-qmldir", action="store_true", help="skip regenerating qmldir")
    args = p.parse_args()

    if not (args.name and args.category):
        args = interactive(args)
    if not args.name:
        sys.exit("error: a plugin name is required")
    args.category = args.category or "community"
    if args.category not in CATEGORIES:
        sys.exit(f"error: category must be one of {CATEGORIES}")

    locations = [l.strip() for l in (args.locations or "").split(",") if l.strip()]
    unknown = [l for l in locations if l not in KNOWN_LOCATIONS]
    if unknown:
        print(f"warning: unknown locations {unknown} (no UI component will be scaffolded)")

    settings = parse_settings(args.settings or "")
    pid = args.id or plugin_id(args.name)
    class_name = pascal(args.name)
    if not class_name.endswith("Plugin"):
        class_name += "Plugin"

    content = TEMPLATE.format(
        name=args.name,
        id=pid,
        description=args.description or "",
        author=args.author or DEFAULT_AUTHOR,
        shell_version=SHELL_VERSION,
        icon=args.icon or "puzzle",
        locations_json="[" + ", ".join(f'"{l}"' for l in locations) + "]",
        settings=render_settings(settings),
        on_setting_changed=render_on_setting_changed(settings),
        components=render_components(locations, args.name),
    )

    folder = class_name[:-6] if class_name.endswith("Plugin") else class_name
    out = PLUGINS_DIR / args.category / folder / f"{class_name}.qml"
    if out.exists() and not args.force:
        sys.exit(f"error: {out} already exists (use --force to overwrite)")
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(content)
    print(f"✓ created {out.relative_to(REPO)}")

    if not args.no_qmldir:
        gen = REPO / "dev" / "generate-qmldir.sh"
        if gen.exists():
            subprocess.run(["bash", str(gen)], check=False,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            print("✓ regenerated qmldir")
    print("  Restart quickshell to load it (pkill -x qs; qs &).")


if __name__ == "__main__":
    main()
