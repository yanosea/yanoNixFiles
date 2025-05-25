-- copilot cmp config
return {
	{
		"zbirenbaum/copilot-cmp",
		dependencies = { "zbirenbaum/copilot.lua" },
		lazy = true,
		event = { "InsertEnter", "CmdlineEnter" },
		config = function()
			-- copilot-cmp config
			require("copilot_cmp").setup({
				fix_pairs = true,
			})
		end,
	},
}
