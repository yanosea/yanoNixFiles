-- everforest colorscheme
return {
	{
		"neanias/everforest-nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("everforest").setup({
				background = "medium",
				on_highlights = function(hl, palette)
					hl.TerminalNormal = { bg = palette.bg_dim }
					hl.TerminalNormalNC = { bg = palette.bg_dim }
				end,
			})
			vim.cmd("colorscheme everforest")
		end,
	},
}
