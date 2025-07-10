-- copilot cmp config
return {
	{
		"zbirenbaum/copilot-cmp",
		dependencies = { "zbirenbaum/copilot.lua" },
		lazy = true,
		event = { "InsertEnter", "CmdlineEnter" },
		-- disable copilot-cmp when monthly limit is reached
		enabled = vim.g.copilot_enabled ~= false,
		config = function()
			-- copilot-cmp config
			require("copilot_cmp").setup({
				fix_pairs = true,
			})
		end,
	},
}
