-- define colors using everforest palette
local M = {}

local function get_palette()
	local _, everforest = pcall(require, "everforest")
	local config = everforest.config or {}
	local background = config.background or "medium"
	local colours = require("everforest.colours")
	local theme = vim.o.background or "dark"
	local options = {
		background = background,
		colours_override = function() end,
	}
	return colours.generate_palette(options, theme)
end
-- generate colors from palette
local palette = get_palette()
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
