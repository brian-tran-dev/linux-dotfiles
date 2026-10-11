import re
import os
import ipaddress
import json
import socket
import subprocess
import shlex
from urllib.parse import unquote
from os import path

PATTERN = re.compile(
    r"(?P<full>"
    r"(?<![@A-Za-z0-9_])"
    r"(?:(?P<scheme>https?)://)?"
    r"(?P<host>"
    r"localhost"
    r"|(?:\d{1,3}\.){3}\d{1,3}"
    r"|\[[0-9A-Fa-f:]+\]"
    r"|(?:"
    r"(?:[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)+"
    r"(?:[A-Za-z]{2,63}|xn--[A-Za-z0-9-]{2,59})"
    r")"
    r")"
    r"(?::(?P<port>\d{1,5}))?"
    r"(?P<path>"
    r"(?:/[^\s<>\"\'`]*)?"
    r"(?:\?[^\s<>\"\'`]*)?"
    r"(?:#[^\s<>\"\'`]*)?"
    r")"
    r")",
    re.IGNORECASE,
)


FILE_PATTERN = re.compile(
    r"(?P<full>"
    r"(?<![@\w/.-])"
    r"(?P<path>"
    r"file:///[^\s)\]}>\"\',;:`]+"
    r"|(?:~/|\./|\.\./|/)?[\w./~+%=-]+"
    r")"
    r"(?P<line>:\d{1,9})?"
    r"(?P<col>:\d{1,9})?"
    r")"
)

QUOTED_FILE_PATTERN = re.compile(
    r"(?P<full>(?P<quote>[\"'])(?P<path>[^\"'\n]+)(?P=quote)"
    r"(?P<line>:\d{1,9})?(?P<col>:\d{1,9})?)"
)


TLD_FILE = path.join(path.dirname(__file__), "iana-tlds.txt")
EXTRA_TLDS = {
    # Common non-IANA roots used locally / for testing.
    "local",
    "localhost",
    "test",
    "example",
    "invalid",
    "onion",
}


def _load_iana_tlds(file_path):
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            out = set()
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                out.add(line.lower())
            return out
    except OSError:
        return set()


IANA_TLDS = _load_iana_tlds(TLD_FILE)


def _run_json(command):
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=1, check=True)
        return json.loads(result.stdout)
    except (OSError, ValueError, subprocess.SubprocessError):
        return None


def _window_info():
    window_id = os.environ.get("KITTY_WINDOW_ID")
    if not window_id or not window_id.isdigit():
        return {}
    command = ["kitten", "@"]
    if os.environ.get("KITTY_LISTEN_ON"):
        command += ["--to", os.environ["KITTY_LISTEN_ON"]]
    data = _run_json(command + ["ls", "--match", f"id:{window_id}"])
    for os_window in data if isinstance(data, list) else []:
        for tab in os_window.get("tabs", []):
            for window in tab.get("windows", []):
                if str(window.get("id")) == window_id:
                    return window
    return {}


def _herdr_pane(socket_path):
    try:
        with socket.socket(socket.AF_UNIX) as client:
            client.settimeout(0.5)
            client.connect(socket_path)
            client.sendall(b'{"id":"kitty-hints","method":"pane.current","params":{}}\n')
            with client.makefile("r") as stream:
                return json.loads(stream.readline()).get("result", {}).get("pane", {})
    except (OSError, ValueError):
        return {}


def _cwd_candidates():
    """Prefer the focused multiplexer pane or Podman's explicit workdir."""
    window = _window_info()
    directories = []
    processes = window.get("foreground_processes", [])
    for process in processes:
        command = _process_args(process)
        if not isinstance(command, list):
            continue
        names = [path.basename(arg) for arg in command]
        if "herdr" in names:
            base = path.expanduser("~/.config/herdr")
            if "--session" in command:
                index = command.index("--session") + 1
                if index < len(command) and re.fullmatch(r"[\w.-]+", command[index]):
                    base = path.join(base, "sessions", command[index])
            pane = _herdr_pane(path.join(base, "herdr.sock"))
            directories += [pane.get("foreground_cwd"), pane.get("cwd")]
            # Herdr's foreground host process can itself be podman.
            if pane.get("pane_id"):
                binary = os.environ.get("HERDR_BIN_PATH", "herdr")
                info = _run_json([binary, "pane", "process-info", pane["pane_id"]])
                if isinstance(info, dict):
                    info = info.get("result", info).get("process_info", {})
                    processes = processes + info.get("foreground_processes", [])
        if any(name.startswith("tmux") for name in names):
            args = ["tmux", "display-message", "-p"]
            try:
                tty = os.readlink(f"/proc/{process['pid']}/fd/0")
                if tty.startswith("/dev/pts/"):
                    args += ["-c", tty]
                result = subprocess.run(args + ["#{pane_current_path}"], capture_output=True, text=True, timeout=0.5)
                if result.returncode == 0:
                    directories.append(result.stdout.strip())
            except (OSError, KeyError, subprocess.SubprocessError):
                pass
    for process in processes:
        command = _process_args(process)
        if not isinstance(command, list):
            continue
        if any(path.basename(arg) == "podman" for arg in command):
            for index, arg in enumerate(command):
                if arg in ("--workdir", "-w") and index + 1 < len(command):
                    directories.insert(0, command[index + 1])
                elif arg.startswith("--workdir="):
                    directories.insert(0, arg.split("=", 1)[1])
        if process.get("cwd"):
            directories.append(process["cwd"])
    directories += [window.get("cwd"), os.getcwd()]
    return list(dict.fromkeys(directory for directory in directories if directory and path.isdir(directory)))


def _process_args(process):
    command = process.get("argv") or process.get("cmdline") or []
    if isinstance(command, str):
        try:
            return shlex.split(command)
        except ValueError:
            return []
    return command if isinstance(command, list) else []


def _resolve_path(raw_path, directories):
    if raw_path.startswith("file://"):
        raw_path = unquote(raw_path[len("file://"):])
    raw_path = path.expanduser(raw_path)
    for candidate in (raw_path, raw_path.rstrip(".,;")):
        if candidate in ("", ".", "..", "/"):
            continue
        choices = [candidate] if path.isabs(candidate) else [path.join(base, candidate) for base in directories]
        for choice in choices:
            if path.exists(choice):
                return path.abspath(choice)
    return None


def _iter_file_candidates(text, directories=None, excluded=()):
    directories = _cwd_candidates() if directories is None else directories
    quoted = list(QUOTED_FILE_PATTERN.finditer(text))
    for m in quoted + list(FILE_PATTERN.finditer(text)):
        start, end = m.span("full")
        if any(_overlaps(start, end, left, right) for left, right in excluded):
            continue
        if m.re is FILE_PATTERN and any(_overlaps(start, end, *q.span("full")) for q in quoted):
            continue
        g = m.groupdict()
        full = g.get("full") or ""
        raw_path = g.get("path") or ""

        # Strip the :line:col suffixes from the matched text; we keep them separately.
        line = g.get("line")
        col = g.get("col")

        fs_path = _resolve_path(raw_path, directories)
        if not fs_path:
            continue

        start, end = m.span("full")
        yield {
            "start": start,
            "end": end,
            "full": full,
            "kind": "path",
            "raw_path": raw_path,
            "fs_path": fs_path,
            "is_dir": os.path.isdir(fs_path),
            "line": int(line[1:]) if line else None,
            "col": int(col[1:]) if col else None,
        }


def _overlaps(a_start, a_end, b_start, b_end):
    return a_start < b_end and a_end > b_start


def _is_valid_ipv4(host):
    parts = host.split(".")
    if len(parts) != 4:
        return False
    try:
        nums = [int(p) for p in parts]
    except ValueError:
        return False
    return all(0 <= n <= 255 for n in nums)


def _is_domain(host):
    # Very small check; PATTERN already restricts the shape.
    if host.lower() == "localhost":
        return False
    if host.startswith("[") and host.endswith("]"):
        return False
    if ":" in host:
        return False
    if host.replace(".", "").isdigit():
        return False
    return "." in host


def _tld_allowed(host):
    # If we have the IANA list, require the final label to exist there
    # (or in our small local allowlist).
    if not IANA_TLDS:
        return True

    h = host.lower().rstrip(".")
    tld = h.rsplit(".", 1)[-1]
    return tld in IANA_TLDS or tld in EXTRA_TLDS


def _is_valid_port(port):
    if port is None:
        return True
    try:
        p = int(port)
    except ValueError:
        return False
    return 0 <= p <= 65535


def _is_valid_host_token(host):
    host_no_brackets = host[1:-1] if host.startswith("[") and host.endswith("]") else host

    # If it looks numeric-with-dots, only accept it as a real IPv4.
    # This avoids false positives like version numbers: 3.13.11
    if host_no_brackets != "localhost" and ":" not in host_no_brackets and host_no_brackets.replace(".", "").isdigit():
        return _is_valid_ipv4(host_no_brackets)

    return True


def _normalized_text(text):
    # Kitty distinguishes soft wraps (CR) from hard line breaks (LF). Match
    # across soft wraps, but retain original offsets for the hint highlights.
    chars, offsets = [], []
    for index, char in enumerate(text):
        if char not in ("\0", "\r"):
            chars.append(char)
            offsets.append(index)
    return "".join(chars), offsets


def _trim_url(url):
    while True:
        previous = url
        url = url.rstrip(".,;")
        for opening, closing in (("(", ")"), ("[", "]"), ("{", "}")):
            while url.endswith(closing) and url.count(closing) > url.count(opening):
                url = url[:-1].rstrip(".,;")
        if url == previous:
            return url


def _url_from_groups(groups):
    host = groups["host"]
    bare_host = host.strip("[]")
    if not _is_valid_host_token(host) or not _is_valid_port(groups.get("port")):
        return None
    if _is_domain(host) and not _tld_allowed(host):
        return None
    scheme = groups.get("scheme")
    if not scheme:
        local = bare_host.lower() == "localhost" or host.lower().endswith((".local", ".test"))
        try:
            local = local or ipaddress.ip_address(bare_host).is_private
        except ValueError:
            pass
        scheme = "http" if local else "https"
    if bare_host == "0.0.0.0":
        host = "127.0.0.1"
    elif bare_host == "::":
        host = "[::1]"
    port = groups.get("port")
    return _trim_url(f"{scheme}://{host}{(':' + port) if port else ''}{groups.get('path') or ''}")


def mark(text, args, Mark, extra_cli_args, *a):
    text, offsets = _normalized_text(text)
    possible_urls = list(PATTERN.finditer(text))
    # Never mistake the /path inside an explicit URL for a local file.
    explicit_spans = [m.span("full") for m in possible_urls if m.group("scheme")]
    file_matches = list(_iter_file_candidates(text, excluded=explicit_spans))
    file_spans = [(m["start"], m["end"]) for m in file_matches]

    url_matches = []
    for m in possible_urls:
        g = m.groupdict()
        url = _url_from_groups(g)
        if not url:
            continue

        start, end = m.span("full")
        if any(_overlaps(start, end, fs, fe) for fs, fe in file_spans):
            continue

        g["kind"] = "url"
        g["url"] = url
        url_matches.append({
            "start": start,
            "end": end,
            "full": m.group("full"),
            "groupdict": g,
        })

    marks = []
    for fm in file_matches:
        gd = {
            "kind": "path",
            "raw_path": fm["raw_path"],
            "fs_path": fm["fs_path"],
            "is_dir": fm["is_dir"],
            "line": fm["line"],
            "col": fm["col"],
        }
        marks.append((fm["start"], fm["end"], fm["full"], gd))

    for um in url_matches:
        marks.append((um["start"], um["end"], um["full"], um["groupdict"]))

    marks.sort(key=lambda x: (x[0], -(x[1] - x[0])))
    for idx, (start, end, text, gd) in enumerate(marks):
        yield Mark(idx, offsets[start], offsets[end - 1] + 1, text, gd)


def handle_result(args, data, target_window_id, boss, extra_cli_args, *a):
    for m, g in zip(data["match"], data["groupdicts"]):
        if not m:
            continue
        kind = (g.get("kind") or "url").lower()

        if kind == "path":
            fs_path = g.get("fs_path") or ""
            if not fs_path or not os.path.exists(fs_path):
                continue
            line = g.get("line")
            col = g.get("col")
            copy_text = fs_path
            if isinstance(line, int) and line > 0:
                copy_text += f":{line}"
                if isinstance(col, int) and col > 0:
                    copy_text += f":{col}"
            try:
                from kitty.clipboard import set_clipboard_string
                set_clipboard_string(copy_text)
            except Exception as error:
                # Never type a selected path into a shell/agent as a fallback.
                boss.show_error("Could not copy file path", str(error))
            continue

        url = g.get("url") or _url_from_groups(g)
        if url:
            boss.open_url(url, cwd=data.get("cwd"))
