import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


def load(name):
    spec = importlib.util.spec_from_file_location(name, Path(__file__).with_name(name + ".py"))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


battery = load("battery-status")
split = load("split-pane")


class HelpersTest(unittest.TestCase):
    def test_battery_charging_and_missing(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.assertEqual(battery.battery_status(root), "")
            supply = root / "BAT0"
            supply.mkdir()
            for name, value in {"type": "Battery", "capacity": "75", "status": "Charging"}.items():
                (supply / name).write_text(value)
            self.assertEqual(battery.battery_status(root), "🔌 75%")
            (supply / "status").write_text("Discharging")
            self.assertEqual(battery.battery_status(root), "▆ 75%")

    @patch.object(split, "request")
    def test_left_split_swaps_live_panes(self, request):
        request.side_effect = [{"pane": {"pane_id": "w1:p2"}}, {}]
        with patch.dict(split.os.environ, {"HERDR_ACTIVE_PANE_ID": "w1:p1"}):
            split.split("left")
        self.assertEqual(request.call_args_list[0].args[1]["direction"], "right")
        self.assertEqual(request.call_args_list[1].args, ("pane.swap", {"source_pane_id": "w1:p2", "target_pane_id": "w1:p1"}))


if __name__ == "__main__":
    unittest.main()
