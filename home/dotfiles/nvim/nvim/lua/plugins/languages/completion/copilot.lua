-- copilot config
return {
	{
		"zbirenbaum/copilot.lua",
		lazy = true,
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			-- copilot.lua config
			require("copilot").setup({
				-- disable suggestion
				suggestion = { enabled = false },
				-- disable panel
				panel = { enabled = false },
			})
		end,
	},
}
