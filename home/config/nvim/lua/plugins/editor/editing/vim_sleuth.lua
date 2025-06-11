-- automatically adjusts shiftwidth and expandtab
return {
	{
		"tpope/vim-sleuth",
		lazy = true,
		event = { "BufReadPost", "BufNewFile" },
		config = function() end,
	},
}
