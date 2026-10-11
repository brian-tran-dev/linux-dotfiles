#!/usr/bin/env python3
"""A tmux-style battery indicator, without a dependency on a running tmux."""

from pathlib import Path


def battery_status(root=Path("/sys/class/power_supply")):
    batteries = []
    for supply in sorted(root.glob("*")):
        try:
            if (supply / "type").read_text().strip() != "Battery":
                continue
            capacity = int((supply / "capacity").read_text().strip())
            status = (supply / "status").read_text().strip().lower()
            batteries.append((max(0, min(100, capacity)), status))
        except (OSError, ValueError):
            continue
    if not batteries:
        return ""
    capacity = round(sum(item[0] for item in batteries) / len(batteries))
    if any(status in ("charging", "full", "not charging") for _, status in batteries):
        icon = "🔌"
    else:
        # Match tmux-battery's default charge tiers.
        tiers = ((95, "█"), (80, "▇"), (65, "▆"), (50, "▅"),
                 (35, "▄"), (20, "▃"), (6, "▂"), (0, "▁"))
        icon = next(glyph for threshold, glyph in tiers if capacity >= threshold)
    return f"{icon} {capacity}%"


if __name__ == "__main__":
    print(battery_status())
