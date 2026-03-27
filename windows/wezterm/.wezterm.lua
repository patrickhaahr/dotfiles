local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

-- Your defaults
config.default_cwd = "C:/Dev"
config.default_prog = { "nu", "-l" }

-- Disable shell integration markers that cause extra spacing
config.enable_scroll_bar = false

-- More importantly: disable the problematic OSC 133 integration
config.canonicalize_pasted_newlines = "None"

-- Disable semantic zones / prompt marking
config.skip_close_confirmation_for_processes_named = {}

-- Ensure clean scrollback behavior
config.scrollback_lines = 10000

-- Cool config: visual and behavior settings
config.front_end = "OpenGL"
config.max_fps = 144
config.animation_fps = 1
config.term = "xterm-256color"

-- Font and sizing
config.font = wezterm.font("Cascadia Code")
config.cell_width = 0.9
config.font_size = 18.0

-- Transparency and padding
config.window_background_opacity = 0.9
config.prefer_egl = true
config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}

-- Tabs: minimal like cool config
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true

-- Window: frameless with resize border
config.window_decorations = "NONE | RESIZE"
config.initial_cols = 80

-- Your color scheme (kept your preference)
config.color_scheme = "Catppuccin Mocha"

-- Key bindings: your ┬╜ prefix + cool config actions
config.keys = {
	-- Your prefix key
	{
		key = "┬╜",
		action = wezterm.action.ActivateKeyTable({
			name = "mux",
			one_shot = true,
			timeout_milliseconds = 1000,
		}),
	},
}

-- Merge: your mux table + cool config pane actions
config.key_tables = {
	mux = {
		-- Your tab/window management
		{ key = "c", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
		{ key = "n", action = wezterm.action.ActivateTabRelative(1) },
		{ key = "p", action = wezterm.action.ActivateTabRelative(-1) },
		{ key = "1", action = wezterm.action.ActivateTab(0) },
		{ key = "2", action = wezterm.action.ActivateTab(1) },
		{ key = "&", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
		{ key = "d", action = wezterm.action.Hide },

		-- Cool config: pane splits (h/v like vim, but under your prefix)
		{
			key = "h",
			action = wezterm.action.SplitPane({
				direction = "Right",
				size = { Percent = 50 },
			}),
		},
		{
			key = "v",
			action = wezterm.action.SplitPane({
				direction = "Down",
				size = { Percent = 50 },
			}),
		},

		-- Cool config: pane resizing
		{ key = "H", action = act.AdjustPaneSize({ "Left", 5 }) },
		{ key = "J", action = act.AdjustPaneSize({ "Down", 5 }) },
		{ key = "K", action = act.AdjustPaneSize({ "Up", 5 }) },
		{ key = "L", action = act.AdjustPaneSize({ "Right", 5 }) },

		-- Cool config: pane selection
		{ key = "9", action = act.PaneSelect },

		-- Cool config: opacity toggle
		{
			key = "o",
			action = wezterm.action_callback(function(window, _)
				local overrides = window:get_config_overrides() or {}
				if overrides.window_background_opacity == 1.0 then
					overrides.window_background_opacity = 0.9
				else
					overrides.window_background_opacity = 1.0
				end
				window:set_config_overrides(overrides)
			end),
		},

		-- Cool config: debug overlay
		{ key = "D", action = act.ShowDebugOverlay },

		-- Your WSL spawn
		{
			key = "w",
			action = wezterm.action.SpawnCommandInNewTab({
				args = { "wsl.exe", "-d", "archlinux" },
			}),
		},

		-- Your pane navigation (arrows)
		{ key = "LeftArrow", action = wezterm.action.ActivatePaneDirection("Left") },
		{ key = "RightArrow", action = wezterm.action.ActivatePaneDirection("Right") },
		{ key = "UpArrow", action = wezterm.action.ActivatePaneDirection("Up") },
		{ key = "DownArrow", action = wezterm.action.ActivatePaneDirection("Down") },

		-- Close pane
		{ key = "x", action = wezterm.action.CloseCurrentPane({ confirm = true }) },

		-- Cancel
		{ key = "Escape", action = "PopKeyTable" },
	},
}

return config
