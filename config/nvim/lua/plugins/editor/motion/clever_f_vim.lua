-- extends f, F, t, T commands
return {
	{
		"rhysd/clever-f.vim",
		lazy = true,
		event = { "BufReadPost", "BufNewFile" },
		config = function() end,
	},
}
