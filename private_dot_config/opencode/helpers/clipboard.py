#!/usr/bin/env python3
"""Text clipboard bridge: a private host socket, never host display access."""

import argparse
import json
import os
from pathlib import Path
import selectors
import signal
import socket
import socketserver
import stat
import struct
import subprocess
import sys
import threading
import time


MAX_TEXT = 1024 * 1024
MAX_MESSAGE = 6 * MAX_TEXT + 256
COMMAND_TIMEOUT = 2
SOCKET_TIMEOUT = 3


def socket_path():
    runtime = Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"))
    return Path(os.environ.get("OPENCODE_CLIPBOARD_SOCKET", runtime / "opencode-clipboard/clipboard.sock"))


def validate_text(text):
    if not isinstance(text, str) or "\0" in text:
        raise ValueError("Expected text without NUL bytes")
    if len(text.encode("utf-8")) > MAX_TEXT:
        raise ValueError("Clipboard text exceeds 1 MiB")
    return text


def read_message(stream):
    raw = stream.readline(MAX_MESSAGE + 1)
    if len(raw) > MAX_MESSAGE or not raw.endswith(b"\n"):
        raise ValueError("Invalid or oversized clipboard message")
    payload = json.loads(raw)
    if not isinstance(payload, dict):
        raise ValueError("Expected a JSON object")
    return payload


def write_message(stream, payload):
    stream.write((json.dumps(payload, ensure_ascii=False) + "\n").encode("utf-8"))
    stream.flush()


def write_clipboard(text):
    # xclip forks a selection owner; do not leave inherited output pipes open.
    result = subprocess.run(
        ["xclip", "-selection", "clipboard", "-in"],
        input=validate_text(text).encode("utf-8"),
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        timeout=COMMAND_TIMEOUT,
    )
    if result.returncode:
        raise OSError("Host clipboard write failed")


def read_clipboard():
    # Bound both the read time and output size, without putting text on disk.
    deadline = time.monotonic() + COMMAND_TIMEOUT
    with subprocess.Popen(
        ["xclip", "-selection", "clipboard", "-out"],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    ) as process:
        try:
            output = bytearray()
            with selectors.DefaultSelector() as selector:
                selector.register(process.stdout, selectors.EVENT_READ)
                while True:
                    remaining = deadline - time.monotonic()
                    if remaining <= 0 or not selector.select(remaining):
                        raise TimeoutError("Host clipboard read timed out")
                    chunk = os.read(process.stdout.fileno(), min(65536, MAX_TEXT + 1 - len(output)))
                    if not chunk:
                        break
                    output.extend(chunk)
                    if len(output) > MAX_TEXT:
                        raise ValueError("Clipboard text exceeds 1 MiB")
            if process.wait(timeout=max(0.001, deadline - time.monotonic())):
                raise OSError("Host clipboard read failed")
            return validate_text(output.decode("utf-8"))
        except BaseException:
            if process.poll() is None:
                process.kill()
            process.wait()
            raise


def dispatch(payload):
    if payload.get("action") == "copy" and set(payload) == {"action", "text"}:
        write_clipboard(validate_text(payload["text"]))
        return {"ok": True}
    if payload.get("action") == "paste" and set(payload) == {"action"}:
        return {"ok": True, "text": read_clipboard()}
    raise ValueError("Only clipboard copy and paste are allowed")


class ClipboardServer(socketserver.ThreadingUnixStreamServer):
    daemon_threads = True

    def __init__(self, address, handler):
        self.slots = threading.BoundedSemaphore(8)
        super().__init__(address, handler)

    def verify_request(self, request, _address):
        _, uid, _ = struct.unpack("3i", request.getsockopt(socket.SOL_SOCKET, socket.SO_PEERCRED, 12))
        return uid == os.getuid() and self.slots.acquire(blocking=False)

    def process_request(self, request, address):
        try:
            super().process_request(request, address)
        except BaseException:
            self.slots.release()
            raise

    def process_request_thread(self, request, address):
        try:
            super().process_request_thread(request, address)
        finally:
            self.slots.release()


class Handler(socketserver.StreamRequestHandler):
    def handle(self):
        self.connection.settimeout(SOCKET_TIMEOUT)
        try:
            result = dispatch(read_message(self.rfile))
        except ValueError:
            result = {"ok": False, "error": "Invalid clipboard request"}
        except (OSError, subprocess.SubprocessError):
            result = {"ok": False, "error": "Host clipboard unavailable or timed out"}
        try:
            write_message(self.wfile, result)
        except OSError:
            pass


def exchange(path, payload):
    info = path.lstat()
    if not stat.S_ISSOCK(info.st_mode) or info.st_uid != os.getuid():
        raise ValueError("Expected this user's clipboard socket")
    with socket.socket(socket.AF_UNIX) as client:
        client.settimeout(SOCKET_TIMEOUT)
        client.connect(str(path))
        with client.makefile("rwb") as stream:
            write_message(stream, payload)
            response = read_message(stream)
    if response.get("ok") is not True:
        raise ValueError(response.get("error", "Clipboard request failed"))
    return response


def notify_ready():
    address = os.environ.get("NOTIFY_SOCKET")
    if address:
        if address.startswith("@"):
            address = "\0" + address[1:]
        with socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM) as client:
            client.connect(address)
            client.sendall(b"READY=1")


def serve():
    os.umask(0o077)
    path = socket_path()
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    if path.parent.is_symlink() or path.parent.stat().st_uid != os.getuid():
        raise ValueError("Expected this user's private runtime directory")
    os.chmod(path.parent, 0o700)
    if path.exists() or path.is_symlink():
        info = path.lstat()
        if not stat.S_ISSOCK(info.st_mode) or info.st_uid != os.getuid():
            raise ValueError("Refusing to replace a non-owned socket")
        try:
            with socket.socket(socket.AF_UNIX) as probe:
                probe.settimeout(SOCKET_TIMEOUT)
                probe.connect(str(path))
            raise ValueError("Clipboard service is already running")
        except ConnectionRefusedError:
            path.unlink()
    with ClipboardServer(str(path), Handler) as server:
        os.chmod(path, 0o600)

        def stop(_signum, _frame):
            threading.Thread(target=server.shutdown, daemon=True).start()

        signal.signal(signal.SIGTERM, stop)
        signal.signal(signal.SIGINT, stop)
        try:
            notify_ready()
            server.serve_forever()
        finally:
            path.unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("serve", "copy", "paste"))
    args = parser.parse_args()
    try:
        if args.action == "serve":
            serve()
        elif args.action == "copy":
            raw = sys.stdin.buffer.read(MAX_TEXT + 1)
            exchange(socket_path(), {"action": "copy", "text": validate_text(raw.decode("utf-8"))})
        else:
            response = exchange(socket_path(), {"action": "paste"})
            sys.stdout.buffer.write(validate_text(response["text"]).encode("utf-8"))
        return 0
    except (OSError, ValueError, KeyError, subprocess.SubprocessError):
        # Do not include clipboard contents or subprocess output in errors/logs.
        print("Clipboard bridge unavailable: check opencode-clipboard.service and restart chat if needed.", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
