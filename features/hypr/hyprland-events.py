#!/usr/bin/env python3
"""Listen to Hyprland socket2 events and print them to stdout.

The event socket only sends events when something changes.
This script stays resident, forwarding events for QML SplitParser.
"""
import os, sys, socket, json
from pathlib import Path

his = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
if not his:
    sys.exit(1)

xdg = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
sock_path = Path(xdg) / "hypr" / his / ".socket2.sock"

if not sock_path.exists():
    sys.exit(1)

sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
sock.connect(str(sock_path))

buf = ""
while True:
    data = sock.recv(4096)
    if not data:
        break
    buf += data.decode()
    while "\n" in buf:
        line, buf = buf.split("\n", 1)
        line = line.strip()
        if not line:
            continue
        # Forward raw event line for parsing in QML
        print(line, flush=True)
