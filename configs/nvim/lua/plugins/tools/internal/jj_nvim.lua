-- jujutsu (jj) integration
-- keymaps are set in lua/plugins/tools/internal/which_key_nvim.lua (<LEADER>j)
return {
	{
		"NicolasGB/jj.nvim",
		lazy = true,
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			local colors = require("utils.colors").colors
			require("jj").setup({
				-- highlights
				highlights = {
					-- editor
					added = { fg = colors.Green },
					modified = { fg = colors.Blue },
					deleted = { fg = colors.Red },
					renamed = { fg = colors.Yellow },
					-- log buffer
					selected = { bg = colors.Bg },
					targeted = { fg = colors.Green, bold = true },
				},
				-- describe editor
				describe = {
					editor = {
						type = "buffer",
						keymaps = {
							close = { "q", "<Esc>" },
						},
					},
				},
				-- log
				log = {
					close_on_edit = true,
				},
			})
		end,
	},
}
