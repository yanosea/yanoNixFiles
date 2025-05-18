-- everforest colorscheme
return {
	{
		"neanias/everforest-nvim",
		lazy = false,
		priority = 1000,
		init = function()
			-- set neovim colorscheme
			vim.cmd("colorscheme everforest")
		end,
	},
}
