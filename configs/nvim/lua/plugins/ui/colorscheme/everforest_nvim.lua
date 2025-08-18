-- everforest colorscheme
return {
	{
		"neanias/everforest-nvim",
		lazy = false,
		priority = 1000,
		init = function()
			-- set everforest background to medium
			vim.g.everforest_background = "medium"
			-- set neovim colorscheme
			vim.cmd("colorscheme everforest")
		end,
	},
}
