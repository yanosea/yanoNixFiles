-- translate text
-- keymaps are set in lua/pulugins/tools/internal/which_key_nvim.lua (<LEADER>T)
return {
	{
		"skanehira/denops-translate.vim",
		dependencies = {
			"vim-denops/denops.vim",
		},
		lazy = true,
		event = "VeryLazy",
		config = function()
			-- keymaps
			-- visual mode mapping for selection translation
			vim.api.nvim_set_keymap(
				"v",
				"<LEADER>T",
				":'<,'>Translate<CR>",
				{ desc = "translate selection", silent = true, noremap = true }
			)
		end,
	},
}
