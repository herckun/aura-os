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


def find_theme_json():
    here = os.path.dirname(os.path.realpath(__file__))
    for p in (os.path.join(here, "../../config/quickshell/styles/theme.json"),
              os.path.expanduser("~/.config/quickshell/styles/theme.json")):
        try:
            with open(p) as f:
                return json.load(f)
        except (OSError, ValueError):
            continue
    return {}


def normalize_accent(blob, default=DEFAULT_ACCENT):
    params = json.loads(blob or "{}")
    accent = str(params.get("accent", default)).lstrip("#").upper()
    if len(accent) != 6 or not all(c in "0123456789ABCDEF" for c in accent):
        accent = default
    return params, accent
