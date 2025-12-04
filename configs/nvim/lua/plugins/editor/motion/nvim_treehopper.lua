-- folding
return {
	{
		"mfussenegger/nvim-treehopper",
		lazy = true,
		keys = {
			{
				"zf",
				function()
					require("tsht").nodes()
					vim.cmd("normal! zf")
				end,
				desc = "treehopper: fold with treesitter",
			},
		},
	},
}
