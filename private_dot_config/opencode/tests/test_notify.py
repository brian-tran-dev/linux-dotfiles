import importlib.util
import json
from pathlib import Path
import socket
import threading
import unittest
from unittest.mock import patch


spec = importlib.util.spec_from_file_location("notify", Path(__file__).resolve().parents[1] / "helpers/notify.py")
notify = importlib.util.module_from_spec(spec)
spec.loader.exec_module(notify)


class NotificationsTest(unittest.TestCase):
    @patch.object(notify.subprocess, "Popen")
    @patch.object(notify.subprocess, "run")
    def test_notifications_use_distinct_sounds_and_deduplicate(self, run, popen):
        run.return_value.returncode = 0
        notifications = notify.Notifications()
        for event in ("ask", "done", "error"):
            self.assertTrue(notifications.notify({"event": event, "key": event, "title": "Test", "message": "<body>"})["ok"])
        self.assertEqual([call.args[0][-1] for call in popen.call_args_list], list(notify.SOUNDS.values()))
        self.assertEqual(run.call_count, 3)
        self.assertTrue(notifications.notify({"event": "done", "key": "done"})["duplicate"])
        self.assertEqual(run.call_count, 3)
        self.assertEqual(run.call_args_list[0].args[0][-1], "&lt;body&gt;")

    def test_only_valid_state_names_are_accepted(self):
        with self.assertRaises(ValueError):
            notify.Notifications().notify({"event": "working", "key": "test"})

    def test_controls_and_excess_text_are_removed(self):
        self.assertEqual(notify.clean_text(" hello\n\x1b[31mworld\x1b[0m ", 80), "hello world")
        self.assertEqual(notify.clean_text("x" * 100, 3), "xxx")

    def test_proxy_refuses_command_execution_and_wrong_pane(self):
        for payload in [
            {"method": "pane.send_keys", "params": {}},
            {"method": "pane.report_agent", "params": {"pane_id": "w1:p2"}},
            {"method": "pane.report_agent", "params": {"pane_id": "w1:p1", "source": "custom:test", "agent": "opencode"}},
            {"method": "pane.report_agent", "params": {"pane_id": "w1:p1", "source": "herdr:opencode", "agent": "opencode", "resume_argv": ["sh"]}},
        ]:
            with self.assertRaises(ValueError):
                notify.Notifications.forward_herdr(Path("/unused"), "w1:p1", payload)

    @patch.object(notify, "exchange", return_value={"id": "test", "result": {"type": "agent_reported"}})
    def test_proxy_forwards_valid_open_code_report(self, exchange):
        payload = {"id": "test", "method": "pane.report_agent", "params": {
            "pane_id": "w1:p1", "source": "herdr:opencode", "agent": "opencode", "state": "working", "seq": 1,
        }}
        result = notify.Notifications.forward_herdr(Path("/socket"), "w1:p1", payload)
        self.assertEqual(result["id"], "test")
        exchange.assert_called_once_with(Path("/socket"), payload)


if __name__ == "__main__":
    unittest.main()
