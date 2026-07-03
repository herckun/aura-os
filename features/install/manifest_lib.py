#!/usr/bin/env python3
"""Shared manifest parsing for the installer.

Subcommands emit exactly what the previous inline heredocs in main.sh,
sync-icons.sh and sync-fonts.sh printed, so the callers' eval/consumption is
byte-for-byte unchanged. Usage: manifest_lib.py <subcommand> <manifest.json>
"""
import json
import os
import re
import sys


def _load(path):
    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def cmd_installvars(manifest_path):
    d = _load(manifest_path)

    app = d.get('app', {})
    print(f'APP_NAME="{app.get("name", "aura-os")}"')
    print(f'APP_DISPLAY="{app.get("displayName", "AuraOS")}"')
    print(f'APP_VERSION="{app.get("version", "2.0")}"')
    print(f'APP_ENV_PREFIX="{app.get("name", "aura-os").upper().replace("-", "_")}"')

    plugins = d.get('plugins', {})
    for kind in ('core', 'extra'):
        var = 'CORE_PLUGINS' if kind == 'core' else 'EXTRA_PLUGINS'
        entries = []
        for p in plugins.get(kind, []):
            # Fields: 1=id 2=name 3=description 4=dep 5=install 6=file
            parts = [p['id'], p['name'], p['description'],
                     p.get('dep', ''), p.get('install', ''), p.get('file', '')]
            entries.append('|'.join(parts))
        print(f'{var}="')
        for e in entries:
            print(e)
        print('"')

    deps = d.get('deps', {})
    entries = []
    for dep in deps.get('system', []):
        v = dep.get('version', '')
        entries.append(f"{dep['bin']}={dep['pkg']}{'@' + v if v else ''}")
    print('SYSTEM_DEPS="')
    for e in entries:
        print(e)
    print('"')

    entries = []
    for dep in deps.get('aur', []):
        t = dep.get('type', 'aur')
        v = dep.get('version', '')
        suffix = f':{t}' if t != 'aur' else ''
        ver = f'@{v}' if v else ''
        entries.append(f"{dep['bin']}={dep['pkg']}{suffix}{ver}")
    print('AUR_DEPS="')
    for e in entries:
        print(e)
    print('"')

    entries = []
    for f in deps.get('fonts', []):
        entries.append(f"{f['fcName']}={f['pkg']}")
    print('FONT_DEPS="')
    for e in entries:
        print(e)
    print('"')

    entries = []
    for f in deps.get('syncFonts', []):
        entries.append(f"{f['ofl']}|{f['file']}|{f['fcName']}")
    print('SYNC_FONTS="')
    for e in entries:
        print(e)
    print('"')

    entries = []
    for s in deps.get('screenshare', []):
        entries.append(f"{s['pkg']}|{s.get('source', 'repo')}")
    print('SCREENSHARE_DEPS="')
    for e in entries:
        print(e)
    print('"')

    gpu = deps.get('gpu', {})
    print(f'GPU_NVIDIA="{" ".join(gpu.get("nvidia", []))}"')
    print(f'GPU_AMD="{" ".join(gpu.get("amd", []))}"')
    print(f'GPU_INTEL="{" ".join(gpu.get("intel", []))}"')

    entries = []
    for a in d.get('apps', []):
        # Fields: 1=id 2=name 3=category 4=pkg 5=source 6=description
        entries.append('|'.join([a['id'], a['name'], a.get('category', ''),
                                 a['pkg'], a.get('source', 'repo'), a.get('description', '')]))
    print('APPS="')
    for e in entries:
        print(e)
    print('"')


def cmd_icons(manifest_path):
    d = _load(manifest_path)
    icons = dict(d.get('icons', {}).get('map', {}))

    # Resolve plugin icon fields through core/Icons.qml's logical map so any
    # plugin icon not already covered by the main list gets merged in.
    _base = os.path.dirname(manifest_path)
    _candidates = [
        os.path.join(_base, 'quickshell', 'core', 'Icons.qml'),
        os.path.join(_base, 'core', 'Icons.qml'),
    ]
    icons_qml = next((c for c in _candidates if os.path.isfile(c)), None)
    logical = {}
    if icons_qml:
        for m in re.finditer(r'"([^"]+)":\s*iconPath\("([^"]+)"\)', open(icons_qml).read()):
            logical[m.group(1)] = m.group(2)

    def consider(icon):
        if not icon:
            return
        # Already a downloadable local name
        if icon in icons:
            return
        # Resolves through Icons.get logical map to a local name
        if icon in logical:
            return
        # Genuinely new icon — best-effort identity download
        icons[icon] = icon

    for cat in ('core', 'extra'):
        for p in d.get('plugins', {}).get(cat, []):
            consider(p.get('icon', ''))
            consider(p.get('overviewTab', {}).get('icon', ''))

    for k, v in sorted(icons.items()):
        print(f'{k}={v}')


def cmd_cdn(manifest_path):
    print(_load(manifest_path).get('icons', {}).get(
        'cdn', 'https://raw.githubusercontent.com/tabler/tabler-icons/main/icons/outline'))


def cmd_fonts(manifest_path):
    data = _load(manifest_path)
    for entry in data.get("deps", {}).get("syncFonts", []):
        ofl_dir = str(entry.get("ofl", "")).strip()
        filename = str(entry.get("file", "")).strip()
        fc_name = str(entry.get("fcName", "")).strip()
        if ofl_dir and filename:
            print(f"{ofl_dir}|{filename}|{fc_name}")


_DISPATCH = {
    "installvars": cmd_installvars,
    "icons": cmd_icons,
    "cdn": cmd_cdn,
    "fonts": cmd_fonts,
}


def main():
    if len(sys.argv) < 3 or sys.argv[1] not in _DISPATCH:
        sys.exit("usage: manifest_lib.py <installvars|icons|cdn|fonts> <manifest.json>")
    _DISPATCH[sys.argv[1]](sys.argv[2])


if __name__ == "__main__":
    main()
