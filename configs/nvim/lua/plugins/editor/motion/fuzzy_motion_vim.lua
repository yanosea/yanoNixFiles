-- jump to fuzzy match word
-- keymaps are set in lua/plugins/tools/internal/which_key_nvim.lua (<LEADER><SPACE>)
return {
	{
		"yuki-yano/fuzzy-motion.vim",
		dependencies = {
			"vim-denops/denops.vim",
			"lambdalisue/kensaku.vim",
		},
		lazy = true,
		event = "VeryLazy",
		config = function()
			-- matchers
			vim.g.fuzzy_motion_matchers = { "fzf", "kensaku" }
		end,
	},
}
