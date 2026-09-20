-- notification (vim.notify backend, also used by noice's notify view)
-- replaces nvim-notify: it allocated 4 buffer-scoped highlight groups per
-- notification and never reused them, so long sessions hit E849
return {
	{
		"folke/snacks.nvim",
		lazy = true,
		event = "VimEnter",
		config = function()
			local colors = require("utils.colors").colors
			-- snacks.nvim config (notifier only)
			require("snacks").setup({
				notifier = {
					enabled = true,
					style = "compact",
					-- the whole on-screen time now: there is no fade padding either end
					timeout = 1500,
					top_down = false,
					-- chronological only: the default hoists errors above older notifications
					sort = { "added" },
				},
				styles = {
					notification = {
						wo = {
							-- opaque, like nvim-notify's faded-in state (snacks defaults to 5)
							winblend = 0,
						},
					},
				},
			})
			-- level colors carried over from the previous nvim-notify setup
			local level_colors = {
				Debug = colors.Blue,
				Error = colors.Red,
				Info = colors.Green,
				Trace = colors.Purple,
				Warn = colors.Yellow,
			}
			local highlights = {}
			for level, color in pairs(level_colors) do
				for _, part in ipairs({ "Border", "Footer", "Icon", "Title" }) do
					highlights["SnacksNotifier" .. part .. level] = { fg = color }
				end
			end
			require("snacks").util.set_hl(highlights)
		end,
	},
}
