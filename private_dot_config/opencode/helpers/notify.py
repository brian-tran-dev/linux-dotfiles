#!/usr/bin/env python3
"""Local desktop notifications and a narrowly scoped Herdr container bridge.

The container receives this private socket directory, never the host D-Bus,
display socket, or Herdr's full control socket. Only this user's processes may
send requests. Notification payloads contain no prompts or provider responses.
"""

import argparse
from collections import OrderedDict
import hashlib
import html
import json
import logging
import os
from pathlib import Path
import re
import signal
import socket
import socketserver
import stat
import struct
import subprocess
import threading
import time


MAX_MESSAGE = 8192
LABELS = {"ask": "Needs input", "done": "Finished", "error": "Error"}
SOUNDS = {
    "ask": "/usr/share/sounds/LinuxMint/stereo/dialog-question.ogg",
    "done": "/usr/share/sounds/freedesktop/stereo/complete.oga",
    "error": "/usr/share/sounds/LinuxMint/stereo/dialog-error.ogg",
}
FALLBACK_SOUNDS = {
    "ask": "/usr/share/sounds/freedesktop/stereo/dialog-warning.oga",
    "done": "/usr/share/sounds/freedesktop/stereo/dialog-information.oga",
    "error": "/usr/share/sounds/freedesktop/stereo/suspend-error.oga",
}


def socket_path():
    runtime = Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"))
    return Path(os.environ.get("OPENCODE_NOTIFY_SOCKET", runtime / "opencode-notify/notify.sock"))


def notify_ready():
    """Tell systemd that both the notification and restored proxy sockets exist."""
    address = os.environ.get("NOTIFY_SOCKET")
    if not address:
        return
    if address.startswith("@"):
        address = "\0" + address[1:]
    with socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM) as status:
        status.connect(address)
        status.sendall(b"READY=1")


def clean_text(value, limit):
    if not isinstance(value, str):
        return ""
    value = re.sub(r"\x1b\[[0-?]*[ -/]*[@-~]", "", value)
    return " ".join("".join(c for c in value if c.isprintable() or c.isspace()).split())[:limit]


def exchange(path, payload):
    with socket.socket(socket.AF_UNIX) as client:
        client.settimeout(3)
        client.connect(str(path))
        client.sendall((json.dumps(payload) + "\n").encode())
        with client.makefile("rb") as stream:
            response = stream.readline(MAX_MESSAGE + 1)
    if not response or len(response) > MAX_MESSAGE:
        raise ValueError("Invalid socket response")
    return json.loads(response)


class LocalServer(socketserver.ThreadingUnixStreamServer):
    daemon_threads = True

    def verify_request(self, request, _address):
        _, uid, _ = struct.unpack("3i", request.getsockopt(socket.SOL_SOCKET, socket.SO_PEERCRED, 12))
        return uid == os.getuid()


class Handler(socketserver.StreamRequestHandler):
    def handle(self):
        self.connection.settimeout(3)
        try:
            raw = self.rfile.readline(MAX_MESSAGE + 1)
            if len(raw) > MAX_MESSAGE or not raw.endswith(b"\n"):
                raise ValueError("Request too large or incomplete")
            payload = json.loads(raw)
            if not isinstance(payload, dict):
                raise ValueError("Expected a JSON object")
            result = self.server.dispatch(payload)
        except (OSError, ValueError, KeyError, TypeError) as error:
            result = {"ok": False, "error": str(error)}
        try:
            self.wfile.write((json.dumps(result) + "\n").encode())
        except OSError:
            pass


class Notifications:
    def __init__(self):
        self.lock = threading.Lock()
        self.seen = OrderedDict()
        self.proxies = {}

    def notify(self, payload):
        event = payload.get("event")
        if event not in LABELS:
            raise ValueError("Unknown notification event")
        key = clean_text(payload.get("key"), 256)
        if not key:
            raise ValueError("Notification key is required")
        now = time.monotonic()
        with self.lock:
            # A shared OpenCode server can deliver the same event to multiple
            # TUIs. Deduplicate by event ID across host and container clients.
            if now - self.seen.get(key, -3600) < 300:
                return {"ok": True, "duplicate": True}
            self.seen[key] = now
            self.seen.move_to_end(key)
            while len(self.seen) > 2048:
                self.seen.popitem(last=False)
        title = clean_text(payload.get("title"), 160) or "OpenCode"
        message = clean_text(payload.get("message"), 240)
        if event == "error":
            message = "The agent execution failed. Check OpenCode for details."
        title = f"OpenCode · {LABELS[event]} · {title}"
        # -- prevents user-controlled titles from being parsed as flags.
        # Escape desktop notification markup, and suppress the desktop's generic
        # sound because the state-specific sound is played separately below.
        try:
            result = subprocess.run([
                "notify-send", "--app-name=OpenCode", "--icon=utilities-terminal",
                "--hint=boolean:suppress-sound:true", "--expire-time=10000",
                "--urgency=critical" if event == "error" else "--urgency=normal",
                "--", title, html.escape(message),
            ], stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, timeout=3)
            delivered = result.returncode == 0
        except (OSError, subprocess.SubprocessError):
            delivered = False
        if not delivered:
            logging.warning("Desktop notification failed")
        sound = SOUNDS[event]
        if not Path(sound).is_file():
            sound = FALLBACK_SOUNDS[event]
        if Path(sound).is_file():
            try:
                subprocess.Popen(["paplay", "--volume=26214", sound],
                                 stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except OSError:
                logging.warning("Sound player unavailable")
        return {"ok": delivered, "duplicate": False}

    def register_herdr(self, payload, restore=False):
        target = Path(payload.get("socket", "")).resolve()
        config_root = (Path.home() / ".config/herdr").resolve()
        if not target.is_relative_to(config_root):
            raise ValueError("Herdr socket must be inside ~/.config/herdr")
        if target.exists() or not restore:
            info = target.stat()
            if info.st_uid != os.getuid() or not stat.S_ISSOCK(info.st_mode):
                raise ValueError("Expected this user's Herdr socket")
        pane_id = payload.get("pane_id", "")
        if not isinstance(pane_id, str) or not re.fullmatch(r"[A-Za-z0-9_-]+:p[A-Za-z0-9_-]+", pane_id):
            raise ValueError("Invalid pane ID")
        name = hashlib.sha256(f"{target}:{pane_id}".encode()).hexdigest()[:20]
        proxy_path = socket_path().parent / f"herdr-{name}.sock"
        with self.lock:
            if str(proxy_path) not in self.proxies:
                if proxy_path.exists():
                    if not stat.S_ISSOCK(proxy_path.lstat().st_mode):
                        raise ValueError("Refusing to replace a non-socket")
                    proxy_path.unlink()
                server = LocalServer(str(proxy_path), Handler)
                os.chmod(proxy_path, 0o600)
                server.dispatch = lambda request: self.forward_herdr(target, pane_id, request)
                self.proxies[str(proxy_path)] = server
                threading.Thread(target=server.serve_forever, daemon=True).start()
                # Keep registrations in the private runtime directory so a
                # bridge restart does not require recreating live containers.
                metadata = proxy_path.with_suffix(".json")
                temporary = metadata.with_suffix(".tmp")
                temporary.write_text(json.dumps({"socket": str(target), "pane_id": pane_id}))
                temporary.replace(metadata)
        return {"ok": True, "socket": str(proxy_path)}

    def restore(self):
        for metadata in socket_path().parent.glob("herdr-*.json"):
            try:
                if metadata.stat().st_uid == os.getuid():
                    self.register_herdr(json.loads(metadata.read_text()), restore=True)
            except (OSError, ValueError, TypeError):
                logging.warning("Could not restore a Herdr bridge registration")

    @staticmethod
    def forward_herdr(target, pane_id, payload):
        if payload.get("method") not in ("pane.report_agent", "pane.report_agent_session"):
            raise ValueError("Only OpenCode state/session reports are allowed")
        params = payload.get("params", {})
        if not isinstance(params, dict) or params.get("pane_id") != pane_id:
            raise ValueError("Report is not for the registered pane")
        if params.get("source") != "herdr:opencode" or params.get("agent") != "opencode":
            raise ValueError("Only the Herdr OpenCode integration may report")
        # Never expose input, commands, pane control, or caller-supplied resume
        # commands to the container. Herdr's built-in OpenCode restore handles it.
        allowed = {"pane_id", "source", "agent", "state", "seq", "agent_session_id", "session_start_source"}
        if set(params) - allowed:
            raise ValueError("Unexpected report parameters")
        return exchange(target, payload)

    def dispatch(self, payload):
        if payload.get("action") == "register_herdr":
            return self.register_herdr(payload)
        return self.notify(payload)

    def close(self):
        for path, server in self.proxies.items():
            server.shutdown()
            server.server_close()
            Path(path).unlink(missing_ok=True)


def serve():
    os.umask(0o077)
    path = socket_path()
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    if path.exists():
        if not stat.S_ISSOCK(path.lstat().st_mode):
            raise ValueError("Refusing to replace a non-socket")
        try:
            with socket.socket(socket.AF_UNIX) as probe:
                probe.connect(str(path))
            raise ValueError("Notification service is already running")
        except ConnectionRefusedError:
            path.unlink()
    notifications = Notifications()
    notifications.restore()
    with LocalServer(str(path), Handler) as server:
        os.chmod(path, 0o600)
        server.dispatch = notifications.dispatch
        def stop(_signum, _frame):
            threading.Thread(target=server.shutdown, daemon=True).start()
        signal.signal(signal.SIGTERM, stop)
        signal.signal(signal.SIGINT, stop)
        try:
            notify_ready()
            server.serve_forever()
        finally:
            notifications.close()
            path.unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--serve", action="store_true")
    parser.add_argument("--register-herdr", metavar="SOCKET")
    parser.add_argument("--pane", metavar="PANE_ID")
    args = parser.parse_args()
    if args.serve:
        serve()
    elif args.register_herdr:
        result = exchange(socket_path(), {
            "action": "register_herdr", "socket": args.register_herdr, "pane_id": args.pane,
        })
        if not result.get("ok"):
            parser.exit(1, result.get("error", "Could not register Herdr bridge") + "\n")
        print(result["socket"])
    else:
        parser.error("Choose --serve or --register-herdr")


if __name__ == "__main__":
    main()
