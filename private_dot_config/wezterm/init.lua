local wezterm = require("wezterm")
local utils = require("utils")
local scheme = require("config-scheme")
local window = require("config-window")
local keybindings = require("config-keybindings")
local status = require("config-status")

local config = wezterm.config_builder()

config.webgpu_preferred_adapter = utils.get_discrete_gpu()
config.front_end = "WebGpu"
config.enable_wayland = false

config.font = wezterm.font("JetbrainsMonoNL Nerd Font", { weight = 'Medium' })
config.use_ime = true
config.font_size = 12
config.line_height = 1.5
config.cell_width = 1.05

config.automatically_reload_config = false
config.default_gui_startup_args = {"start", "--always-new-process"}

config.animation_fps = 1
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"
config.default_cursor_style = "BlinkingBlock"

config.enable_tab_bar = true
config.show_close_tab_button_in_tabs = false
config.show_new_tab_button_in_tab_bar = false
config.use_fancy_tab_bar = false
config.tab_max_width = 200

scheme.config_scheme(config)
window.config_window(config)
keybindings.config_keybindings(config)
status.config_status(config)

return config
