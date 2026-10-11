#!/usr/bin/env python3
"""Split left/up by splitting right/down and swapping the two live panes."""

import json
import os
import socket
import sys


def request(method, params):
    socket_path = os.environ.get("HERDR_SOCKET_PATH")
    if not socket_path:
        raise RuntimeError("Run this command from a Herdr keybinding")
    with socket.socket(socket.AF_UNIX) as client:
        client.settimeout(3)
        client.connect(socket_path)
        client.sendall((json.dumps({"id": "directional-split", "method": method, "params": params}) + "\n").encode())
        with client.makefile("r") as stream:
            response = json.loads(stream.readline())
    if "error" in response:
        raise RuntimeError(response["error"].get("message", "Herdr request failed"))
    return response["result"]


def split(direction):
    if direction not in ("left", "up"):
        raise ValueError("Direction must be left or up")
    original = os.environ.get("HERDR_ACTIVE_PANE_ID")
    if not original:
        original = request("pane.current", {})["pane"]["pane_id"]
    result = request("pane.split", {
        "target_pane_id": original,
        "direction": "right" if direction == "left" else "down",
        "focus": True,
    })
    new_pane = result["pane"]["pane_id"]
    request("pane.swap", {"source_pane_id": new_pane, "target_pane_id": original})


if __name__ == "__main__":
    try:
        split(sys.argv[1] if len(sys.argv) > 1 else "")
    except (OSError, ValueError, RuntimeError, KeyError) as error:
        print(error, file=sys.stderr)
        sys.exit(1)
