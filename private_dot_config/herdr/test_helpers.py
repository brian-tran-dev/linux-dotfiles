import importlib.util
from pathlib import Path
import tempfile
import tomllib
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
    def test_complete_pane_frames_with_shared_edges_are_enabled(self):
        ui = tomllib.loads(Path(__file__).with_name("config.toml").read_text())["ui"]
        self.assertEqual(ui["pane_borders"], "always")
        self.assertTrue(ui["pane_outer_borders"])
        self.assertFalse(ui["pane_gaps"])

    def test_arrow_splits_and_sidebar_binding_do_not_collide(self):
        config = tomllib.loads(Path(__file__).with_name("config.toml").read_text())
        keys = config["keys"]
        self.assertEqual(keys["split_vertical"], "prefix+right")
        self.assertEqual(keys["split_horizontal"], "prefix+down")
        self.assertEqual(keys["toggle_sidebar"], "prefix+m")
        self.assertEqual(keys["settings"], "prefix+ctrl+alt+s")
        self.assertEqual(keys["workspace_picker"], ["prefix+s", "prefix+ctrl+s"])
        self.assertEqual({item["key"] for item in keys["command"]}, {"prefix+left", "prefix+up"})

    def test_directional_pane_aliases_and_no_cycling(self):
        keys = tomllib.loads(Path(__file__).with_name("config.toml").read_text())["keys"]
        for direction, key in (("left", "h"), ("down", "j"), ("up", "k"), ("right", "l")):
            self.assertEqual(keys[f"focus_pane_{direction}"], [f"prefix+{key}", f"prefix+ctrl+{key}"])
        for action in ("cycle_pane_next", "cycle_pane_previous", "last_pane"):
            self.assertEqual(keys[action], "")

    def test_configured_action_and_command_bindings_do_not_overlap(self):
        keys = tomllib.loads(Path(__file__).with_name("config.toml").read_text())["keys"]
        actions = [(name, value) for name, value in keys.items() if name not in ("prefix", "command", "indexed")]
        actions.extend((f"command[{index}]", command["key"]) for index, command in enumerate(keys.get("command", [])))
        seen = {}
        for action, value in actions:
            for binding in value if isinstance(value, list) else [value]:
                if not binding:
                    continue
                expanded = [binding.replace("1..9", str(index)) for index in range(1, 10)] if "1..9" in binding else [binding]
                for label in expanded:
                    *modifiers, key = label.split("+")
                    if key == "tab" and "shift" in modifiers:
                        key = "backtab"
                        modifiers.remove("shift")
                    combo = (tuple(sorted(modifiers)), key)
                    self.assertNotIn(combo, seen, f"{label}: {action} overlaps {seen.get(combo)}")
                    seen[combo] = action

    def test_ui_text_contrast_on_all_backgrounds(self):
        colors = tomllib.loads(Path(__file__).with_name("config.toml").read_text())["theme"]["custom"]
        def luminance(color):
            values = [int(color[i:i+2], 16) / 255 for i in (1, 3, 5)]
            linear = [value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4 for value in values]
            return sum(value * weight for value, weight in zip(linear, (0.2126, 0.7152, 0.0722)))
        for foreground in ("text", "subtext0", "overlay0", "overlay1"):
            for background in ("panel_bg", "sidebar_bg", "active_row_bg", "selection_bg", "surface0", "surface1"):
                light, dark = sorted((luminance(colors[foreground]), luminance(colors[background])), reverse=True)
                self.assertGreaterEqual((light + 0.05) / (dark + 0.05), 4.5, f"{foreground} on {background}")

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
