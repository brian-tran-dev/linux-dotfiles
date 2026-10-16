import importlib.util
import io
import json
import os
from pathlib import Path
import socket
import stat
import struct
import subprocess
import sys
import tempfile
import threading
import unittest
from unittest.mock import Mock, patch


spec = importlib.util.spec_from_file_location("clipboard", Path(__file__).resolve().parents[1] / "helpers/clipboard.py")
clipboard = importlib.util.module_from_spec(spec)
spec.loader.exec_module(clipboard)


class ClipboardTest(unittest.TestCase):
    def test_text_validation_preserves_unicode_whitespace_and_empty_text(self):
        for text in ("", "first\nsecond\n", "  tiếng Việt 🐱\t\r\n", "-option; $(command)"):
            self.assertEqual(clipboard.validate_text(text), text)

    def test_text_validation_bounds_utf8_bytes_and_rejects_nul(self):
        for text in (None, 12, "a\0b", "a" * (clipboard.MAX_TEXT + 1), "é" * clipboard.MAX_TEXT, "\ud800"):
            with self.subTest(text_type=type(text).__name__), self.assertRaises(ValueError):
                clipboard.validate_text(text)

    def test_dispatch_only_accepts_exact_copy_and_paste_operations(self):
        for payload in (
            {}, {"action": "exec", "command": "sh"},
            {"action": "paste", "command": "sh"},
            {"action": "copy"}, {"action": "copy", "text": "test", "selection": "primary"},
        ):
            with self.subTest(payload=payload), self.assertRaises(ValueError):
                clipboard.dispatch(payload)

    @patch.object(clipboard.subprocess, "run")
    def test_copy_uses_fixed_argv_and_no_output_pipes(self, run):
        run.return_value.returncode = 0
        text = "-flag; $(anything)\n🐱"
        self.assertEqual(clipboard.dispatch({"action": "copy", "text": text}), {"ok": True})
        run.assert_called_once_with(
            ["xclip", "-selection", "clipboard", "-in"],
            input=text.encode("utf-8"), stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL, timeout=clipboard.COMMAND_TIMEOUT,
        )

    def test_message_rejects_non_objects_incomplete_and_oversized_frames(self):
        for raw in (b"[]\n", b"null\n", b'{"action":"paste"}', b"invalid\n"):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                clipboard.read_message(io.BytesIO(raw))
        with patch.object(clipboard, "MAX_MESSAGE", 8), self.assertRaises(ValueError):
            clipboard.read_message(io.BytesIO(b'{"action":"paste"}\n'))

    def test_peer_credentials_reject_other_users(self):
        server = clipboard.ClipboardServer.__new__(clipboard.ClipboardServer)
        server.slots = threading.BoundedSemaphore(1)
        request = Mock()
        request.getsockopt.return_value = struct.pack("3i", 1, os.getuid() + 1, 1)
        self.assertFalse(server.verify_request(request, None))
        request.getsockopt.return_value = struct.pack("3i", 1, os.getuid(), 1)
        self.assertTrue(server.verify_request(request, None))
        self.assertFalse(server.verify_request(request, None))
        server.slots.release()

    def read_from_process(self, program):
        popen = subprocess.Popen
        with patch.object(clipboard.subprocess, "Popen", side_effect=lambda _args, **kwargs: popen(
            [sys.executable, "-c", program], **kwargs,
        )):
            return clipboard.read_clipboard()

    def test_read_preserves_exact_text(self):
        text = "  tiếng Việt 🐱\nsecond\n"
        self.assertEqual(self.read_from_process(f"import sys; sys.stdout.write({text!r})"), text)
        self.assertEqual(self.read_from_process("pass"), "")

    def test_read_rejects_oversized_output(self):
        with self.assertRaises(ValueError):
            self.read_from_process(f"import sys; sys.stdout.write('x' * {clipboard.MAX_TEXT + 1})")

    def test_read_times_out_and_reaps_child(self):
        with patch.object(clipboard, "COMMAND_TIMEOUT", 0.05), self.assertRaises(TimeoutError):
            self.read_from_process("import time; time.sleep(10)")

    def test_read_rejects_failed_commands(self):
        with self.assertRaises(OSError):
            self.read_from_process("import sys; sys.exit(1)")


class SocketTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.path = Path(self.directory.name) / "clipboard.sock"
        self.server = clipboard.ClipboardServer(str(self.path), clipboard.Handler)
        os.chmod(self.path, 0o600)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join()
        self.directory.cleanup()

    @patch.object(clipboard, "read_clipboard")
    @patch.object(clipboard, "write_clipboard")
    def test_socket_round_trip_is_exact_and_private(self, write, read):
        text = "line one\n🐱 tiếng Việt\n"
        read.return_value = text
        self.assertEqual(clipboard.exchange(self.path, {"action": "copy", "text": text}), {"ok": True})
        write.assert_called_once_with(text)
        self.assertEqual(clipboard.exchange(self.path, {"action": "paste"})["text"], text)
        self.assertEqual(stat.S_IMODE(self.path.stat().st_mode), 0o600)

    def test_missing_socket_fails_without_waiting(self):
        with self.assertRaises(FileNotFoundError):
            clipboard.exchange(self.path.with_name("missing.sock"), {"action": "paste"})

    def test_non_socket_path_is_rejected(self):
        path = self.path.with_name("file")
        path.write_text("not a socket")
        with self.assertRaises(ValueError):
            clipboard.exchange(path, {"action": "paste"})

    def test_arbitrary_commands_are_rejected_over_the_socket(self):
        with self.assertRaisesRegex(ValueError, "Invalid clipboard request"):
            clipboard.exchange(self.path, {"action": "exec", "command": "sh"})

    @patch.object(clipboard, "read_clipboard", side_effect=TimeoutError())
    def test_backend_errors_do_not_include_clipboard_text(self, _read):
        with self.assertRaisesRegex(ValueError, "Host clipboard unavailable or timed out"):
            clipboard.exchange(self.path, {"action": "paste"})

    def test_unresponsive_service_times_out(self):
        path = self.path.with_name("stalled.sock")
        with socket.socket(socket.AF_UNIX) as stalled:
            stalled.bind(str(path))
            stalled.listen(1)
            with patch.object(clipboard, "SOCKET_TIMEOUT", 0.05), self.assertRaises(TimeoutError):
                clipboard.exchange(path, {"action": "paste"})


if __name__ == "__main__":
    unittest.main()
