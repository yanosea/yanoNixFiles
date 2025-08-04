-- improve w, e, b motions
return {
	{
		"chrisgrieser/nvim-spider",
		lazy = true,
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			-- nvim-spider config
			require("spider").setup({
				skipInsignificantPunctuation = true,
				consistentOperatorPending = true,
				subwordMovement = true,
			})
			-- keymaps
			vim.keymap.set(
				{ "n", "o", "x" },
				"w",
				"<CMD>lua require('spider').motion('w')<CR>",
				{ desc = "spider w", silent = true, noremap = true }
			)
			vim.keymap.set(
				{ "n", "o", "x" },
				"e",
				"<CMD>lua require('spider').motion('e')<CR>",
				{ desc = "spider e", silent = true, noremap = true }
			)
			vim.keymap.set(
				{ "n", "o", "x" },
				"b",
				"<CMD>lua require('spider').motion('b')<CR>",
				{ desc = "spider b", silent = true, noremap = true }
			)
		end,
	},
}
