-- folding
return {
	{
		"mfussenegger/nvim-treehopper",
		lazy = true,
		keys = { "zf" },
		config = function()
			-- keymaps
			vim.keymap.set("n", "zf", function()
				require("tsht").nodes()
				vim.cmd("normal! zf")
			end, { desc = "treehopper", silent = true })
		end,
	},
}
