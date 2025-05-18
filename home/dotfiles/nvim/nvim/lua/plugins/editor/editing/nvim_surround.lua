-- surround selection with brackets, quotes, etc.
return {
	{
		"kylechui/nvim-surround",
		lazy = true,
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			-- nvim-surround config
			require("nvim-surround").setup()
		end,
	},
}
