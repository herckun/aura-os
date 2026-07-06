# Shared helpers for the theme generators (kitty/fish/sddm/wleave/gtk-qt).
# Each generator's inline python does `from theme_lib import ...` after adding
# this directory to sys.path.
import json
import os

DEFAULT_ACCENT = "D71921"

_STYLE_KEYS = {0: "default", 1: "zen", 2: "focus", 3: "gaming", 4: "theater"}


def style_key_for(mode):
    try:
        return _STYLE_KEYS.get(int(mode), "default")
    except (TypeError, ValueError):
        return "default"


def clean_font(f, default="monospace"):
    if not f:
        return default
    return f.split(",")[0].strip().replace('"', "").replace("'", "")


def _styles_dirs():
    here = os.path.dirname(os.path.realpath(__file__))
    return (os.path.join(here, "../../config/quickshell/styles"),
            os.path.expanduser("~/.config/quickshell/styles"))


def _load_json(path):
    try:
        with open(path) as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def active_preset_id():
    config_home = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
    settings = _load_json(os.path.join(config_home, "aura-os", "settings.json")) or {}
    preset = str((settings.get("theme") or {}).get("preset") or "aura")
    return preset if preset.replace("-", "").replace("_", "").isalnum() else "aura"


def load_preset(preset_id=None):
    pid = preset_id or active_preset_id()
    for d in _styles_dirs():
        preset = _load_json(os.path.join(d, "presets", pid + ".json"))
        if preset:
            return preset
    return {}


def find_theme_json():
    theme = None
    for d in _styles_dirs():
        theme = _load_json(os.path.join(d, "theme.json"))
        if theme:
            break
    if not theme:
        return {}
    preset = load_preset()
    if preset.get("colors"):
        merged = dict(theme.get("colors", {}))
        merged.update(preset["colors"])
        theme["colors"] = merged
    if preset.get("fonts"):
        typ = dict(theme.get("typography", {}))
        typ.update(preset["fonts"])
        theme["typography"] = typ
    if preset.get("accent"):
        theme["presetAccent"] = preset["accent"]
    if preset.get("monoAccent"):
        theme["monoAccent"] = preset["monoAccent"]
    return theme


def normalize_accent(blob, default=DEFAULT_ACCENT):
    params = json.loads(blob or "{}")
    accent = str(params.get("accent", default)).lstrip("#").upper()
    if len(accent) != 6 or not all(c in "0123456789ABCDEF" for c in accent):
        accent = default
    return params, accent
