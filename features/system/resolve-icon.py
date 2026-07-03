#!/usr/bin/env python3
"""Resolve application class names to icon paths.

Usage: resolve-icon.py <class1> [class2] ...
Output: JSON object mapping class names to icon paths.
"""
import sys, os, json

ICON_DIRS = (
    os.path.expanduser("~/.local/share/icons"),
    "/usr/share/icons",
    "/usr/share/pixmaps",
)

THEMES = ("hicolor", "breeze", "Papirus", "Numix", "Tela", "Sumppa")
EXTS = (".svg", ".png", ".xpm")

def find_icon(app_class: str) -> str:
    name = app_class.lower().replace(" ", "-")

    for icon_dir in ICON_DIRS:
        if not os.path.isdir(icon_dir):
            continue

        for theme in THEMES:
            theme_dir = os.path.join(icon_dir, theme)
            if not os.path.isdir(theme_dir):
                continue

            for entry in os.listdir(theme_dir):
                apps_dir = os.path.join(theme_dir, entry, "apps")
                if not os.path.isdir(apps_dir):
                    continue
                for ext in EXTS:
                    path = os.path.join(apps_dir, name + ext)
                    if os.path.isfile(path):
                        return path

        for ext in EXTS:
            path = os.path.join(icon_dir, name + ext)
            if os.path.isfile(path):
                return path

    for ext in EXTS:
        path = os.path.join("/usr/share/pixmaps", name + ext)
        if os.path.isfile(path):
            return path

    return ""

def main():
    if len(sys.argv) < 2:
        print("{}")
        return
    result = {a.lower(): find_icon(a) for a in sys.argv[1:]}
    print(json.dumps(result))

if __name__ == "__main__":
    main()
