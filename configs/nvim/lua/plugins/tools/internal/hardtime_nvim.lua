-- hardtime.nvim breaks bad habits by preventing you from repeating the same action too many times
-- keymaps are set in lua/plugins/tools/internal/which_key_nvim.lua (<LEADER>H)
return {
	{
		"m4xshen/hardtime.nvim",
		dependencies = { "MunifTanjim/nui.nvim" },
		lazy = true,
		event = "VeryLazy",
		config = function()
			require("hardtime").setup()
		end,
	},
}
