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


def _manifest_block(text):
    """Return the balanced `manifest: ({ ... })` object literal from a plugin QML."""
    i = text.find("manifest:")
    if i < 0:
        return ""
    b = text.find("{", i)
    if b < 0:
        return ""
    depth = 0
    for j in range(b, len(text)):
        if text[j] == "{":
            depth += 1
        elif text[j] == "}":
            depth -= 1
            if depth == 0:
                return text[b:j + 1]
    return text[b:]


def _plugin_meta(base, kind, rel_file):
    """Read name/description/dependencies from a plugin's own QML manifest.
    The manifest.json only stores {id, file}; everything else lives in the plugin.
    All dependency entries are kept: bins joined with ',', installs with ';;',
    paired by index."""
    meta = {"name": "", "description": "", "dep": "", "install": ""}
    if not rel_file:
        return meta
    path = os.path.join(base, "quickshell", "services", "plugins", kind, rel_file)
    try:
        with open(path, "r", encoding="utf-8") as handle:
            block = _manifest_block(handle.read())
    except OSError:
        return meta
    m = re.search(r'\bname\s*:\s*"([^"]*)"', block)
    if m:
        meta["name"] = m.group(1)
    m = re.search(r'\bdescription\s*:\s*"([^"]*)"', block)
    if m:
        meta["description"] = m.group(1)
    dm = re.search(r'\bdependencies\s*:\s*\[(.*?)\]', block, re.S)
    if dm:
        bins = []
        installs = []
        for em in re.finditer(r'\{[^}]*\}', dm.group(1)):
            bm = re.search(r'\bbin\s*:\s*"([^"]*)"', em.group(0))
            im = re.search(r'\binstall\s*:\s*"([^"]*)"', em.group(0))
            if bm:
                bins.append(bm.group(1))
                installs.append(im.group(1) if im else "")
        meta["dep"] = ",".join(bins)
        meta["install"] = ";;".join(installs)
    return meta


def _plugin_icons(base, kind, rel_file):
    """Every string `icon:` prop anywhere in a plugin's QML — manifest fields
    (icon/overviewTab.icon/controlCenterToggle.icon) and UI (buttons, toggles).
    The manifest.json only stores {id, file}, so plugin icons to download live here.
    Only literal `icon: "name"` is captured; expression bindings (icon: root.foo)
    and sibling props (iconKind:, iconFallback:) don't match `\\bicon\\s*:\\s*"`.
    Captures are constrained to tabler-style names (lowercase/digits/hyphens) so
    runtime image URLs (e.g. favicon sources on iconKind:"image") are excluded."""
    if not rel_file:
        return []
    path = os.path.join(base, "quickshell", "services", "plugins", kind, rel_file)
    try:
        with open(path, "r", encoding="utf-8") as handle:
            text = handle.read()
    except OSError:
        return []
    return [m.group(1) for m in re.finditer(r'\bicon\s*:\s*"([a-z0-9-]+)"', text)]


def cmd_installvars(manifest_path):
    d = _load(manifest_path)

    app = d.get('app', {})
    print(f'APP_NAME="{app.get("name", "aura-os")}"')
    print(f'APP_DISPLAY="{app.get("displayName", "AuraOS")}"')
    print(f'APP_VERSION="{app.get("version", "2.0")}"')
    print(f'APP_ENV_PREFIX="{app.get("name", "aura-os").upper().replace("-", "_")}"')

    plugins = d.get('plugins', {})
    base = os.path.dirname(manifest_path)
    for kind in ('core', 'extra'):
        var = 'CORE_PLUGINS' if kind == 'core' else 'EXTRA_PLUGINS'
        entries = []
        for p in plugins.get(kind, []):
            # manifest holds only {id, file}; name/description/deps come from the plugin QML
            meta = _plugin_meta(base, kind, p.get('file', ''))
            # Fields: 1=id 2=name 3=description 4=dep 5=install 6=file
            parts = [p['id'], meta['name'], meta['description'],
                     meta['dep'], meta['install'], p.get('file', '')]
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
            for name in _plugin_icons(_base, cat, p.get('file', '')):
                consider(name)

    for k, v in sorted(icons.items()):
        print(f'{k}={v}')


def cmd_cdn(manifest_path):
    print(_load(manifest_path).get('icons', {}).get(
        'cdn', 'https://raw.githubusercontent.com/tabler/tabler-icons/main/icons/outline'))


def cmd_sfx(manifest_path):
    for k, v in sorted(_load(manifest_path).get('sfx', {}).get('map', {}).items()):
        print(f'{k}={v}')


def cmd_sfxcdn(manifest_path):
    print(_load(manifest_path).get('sfx', {}).get('cdn', ''))


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
    "sfx": cmd_sfx,
    "sfxcdn": cmd_sfxcdn,
    "fonts": cmd_fonts,
}


def main():
    if len(sys.argv) < 3 or sys.argv[1] not in _DISPATCH:
        sys.exit("usage: manifest_lib.py <installvars|icons|cdn|sfx|sfxcdn|fonts> <manifest.json>")
    _DISPATCH[sys.argv[1]](sys.argv[2])


if __name__ == "__main__":
    main()
