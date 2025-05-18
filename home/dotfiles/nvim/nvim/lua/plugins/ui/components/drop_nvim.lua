-- screensaver
return {
	{
		"folke/drop.nvim",
		lazy = true,
		event = "VimEnter",
		config = function()
			-- drop.nvim config
			require("drop").setup({
				theme = "leaves",
				max = 20,
				interval = 250,
			})
		end,
	},
}
