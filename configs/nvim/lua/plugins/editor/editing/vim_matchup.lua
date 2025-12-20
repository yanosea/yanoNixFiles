-- highlight pairs and extend % key to jump between matching pairs
return {
	{
		"andymass/vim-matchup",
		lazy = true,
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			-- vim-matchup config
			require("match-up").setup({
				treesitter = {
					enable = true,
				},
			})
			-- matchup matchparen offscreen method
			vim.g.matchup_matchparen_offscreen = { method = "popup" }
		end,
	},
}
