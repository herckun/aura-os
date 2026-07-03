#!/usr/bin/env python3
"""Check if dock should hide in smartHide mode.
Returns "1" if dock should hide, "0" if it should show.
Hides dock when there are any windows on the current workspace.
"""
import subprocess
import sys
import json

def main():
    try:
        active_ws = json.loads(
            subprocess.run(
                ["hyprctl", "activeworkspace", "-j"],
                capture_output=True, text=True, timeout=2
            ).stdout
        )
        active_id = active_ws["id"]
        
        clients = json.loads(
            subprocess.run(
                ["hyprctl", "clients", "-j"],
                capture_output=True, text=True, timeout=2
            ).stdout
        )
        
        # Check if any client is on the active workspace
        for client in clients:
            ws = client.get("workspace", {})
            if ws.get("id") == active_id:
                print("1")  # Hide dock - workspace has windows
                return
        
        print("0")  # Show dock - workspace is empty
    except Exception:
        print("0")

if __name__ == "__main__":
    main()