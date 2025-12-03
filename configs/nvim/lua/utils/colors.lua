-- define colors using everforest palette with fallback support
local M = {}

-- fallback palette for everforest medium/dark theme
-- used when everforest plugin is not yet installed (first-time startup)
local fallback_palette = {
	bg0 = "#2d353b",
	fg = "#d3c6aa",
	red = "#e67e80",
	green = "#a7c080",
	yellow = "#dbbc7f",
	blue = "#7fbbb3",
	purple = "#d699b6",
	aqua = "#83c092",
	orange = "#e69875",
}

local function get_palette()
	-- safely check if everforest is available
	local ok, everforest = pcall(require, "everforest")
	if not ok or type(everforest) ~= "table" then
		return fallback_palette
	end

	-- safely check if everforest.colours is available
	local colours_ok, colours = pcall(require, "everforest.colours")
	if not colours_ok or type(colours) ~= "table" or type(colours.generate_palette) ~= "function" then
		return fallback_palette
	end

	-- get config with defaults
	local config = everforest.config or {}
	local background = config.background or "medium"
	local theme = vim.o.background or "dark"
	local options = {
		background = background,
		colours_override = function() end,
	}

	-- safely generate palette
	local palette_ok, palette = pcall(colours.generate_palette, options, theme)
	if not palette_ok or type(palette) ~= "table" then
		return fallback_palette
	end

	return palette
end

-- generate colors from palette
local palette = get_palette()

-- export colors with PascalCase keys
M.colors = {
	Bg = palette.bg0,
	Fg = palette.fg,
	Red = palette.red,
	Green = palette.green,
	Yellow = palette.yellow,
	Blue = palette.blue,
	Purple = palette.purple,
	Aqua = palette.aqua,
	Orange = palette.orange,
}

return M
