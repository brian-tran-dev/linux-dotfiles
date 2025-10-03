local wezterm = require("wezterm")
-- local misc = require("core.misc")
local tab = require("config.tab")
local theme = require("config.theme")
local window = require("config.window")
local keybindings = require("config.keybindings")
local status = require("config.status")

local config = wezterm.config_builder()

-- wezterm.log_info()misc.get_discrete_gpu())
config.webgpu_preferred_adapter = {
    backend = "Vulkan",
    device = 8081,
    device_type = "DiscreteGpu",
    driver = "NVIDIA",
    driver_info = "535.183.01",
    name = "NVIDIA GeForce GTX 1650",
    vendor = 4318,
}
config.front_end = "WebGpu"
config.enable_wayland = false

config.font = wezterm.font_with_fallback {
	{ family = "JetBrainsMonoNL Nerd Font", weight = 'Medium' },
	{ family = "Unifont", weight = 'Regular' },
	{ family = "Unifont CSUR", weight = 'Regular' },
	{ family = "Unifont Upper", weight = 'Regular' },
}
config.use_ime = true
config.font_size = 12
config.line_height = 1.4
-- config.font_size = 14
-- config.line_height = 1.5
-- config.font_size = 17
-- config.line_height = 1.5
config.cell_width = 1.05

config.automatically_reload_config = false
config.default_gui_startup_args = {"start", "--always-new-process"}

config.animation_fps = 1
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"
config.default_cursor_style = "BlinkingBlock"
config.window_close_confirmation = "NeverPrompt"
config.skip_close_confirmation_for_processes_named = {}

tab.config(config)
theme.config(config)
window.config(config)
keybindings.config(config)
status.config(config)

return config
