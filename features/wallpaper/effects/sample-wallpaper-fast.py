#!/usr/bin/env python3
"""Fast wallpaper illuminance sampler using Pillow.

Outputs base64-encoded RGB binary wrapped in a small JSON envelope:
  { "b": "<base64 RGB bytes>", "w": cols, "h": rows, "n": pixel_count }

This is 3x smaller than JSON packed-ints and decodes at the same speed:
  - Raw RGB: 3 bytes/pixel * 65536 = 196608 bytes
  - Base64:   ~262144 bytes (1.33x overhead)
  - JSON env: ~50 bytes overhead
  Total:      ~262KB  vs  ~786KB for JSON packed-ints

Luminance (Rec. 709) is computed on the QML side during parse — zero extra
cost since the parse loop already iterates every pixel.
"""

import base64
import json
import os
import sys

from PIL import Image


def main():
    args = sys.argv[1:]
    if len(args) < 2:
        _write_fallback()
        return

    wp = args[0]
    output = None
    if "--output" in args:
        idx = args.index("--output")
        output = args[idx + 1]
        args = args[:idx]

    try:
        img = Image.open(wp)
    except Exception:
        _write_fallback()
        return

    cols = int(args[2]) if len(args) > 2 else 32
    rows = int(args[3]) if len(args) > 3 else 32

    img = img.convert("RGB")
    img = img.resize((cols, rows), Image.BILINEAR)

    pixels = img.load()
    w, h = img.size

    raw = bytearray(w * h * 3)
    idx = 0
    for y in range(h):
        for x in range(w):
            r, g, b = pixels[x, y][:3]
            raw[idx] = r
            raw[idx + 1] = g
            raw[idx + 2] = b
            idx += 3

    b64 = base64.b64encode(raw).decode("ascii")
    result = json.dumps({"b": b64, "w": w, "h": h, "n": w * h},
                         separators=(",", ":"))

    print(result)
    if output:
        os.makedirs(os.path.dirname(output), exist_ok=True)
        with open(output, "w") as f:
            f.write(result)


def _write_fallback():
    print('{"b":"","w":1,"h":1,"n":1}')


if __name__ == "__main__":
    main()
