-- search and replace text
-- keymaps are set in lua/pulugins/tools/internal/which_key_nvim.lua (<LEADER>G)
return {
	{
		"MagicDuck/grug-far.nvim",
		lazy = true,
		cmd = { "GrugFar", "GrugFarWithin" },
		config = function()
			-- grug-far.nvim config
			require("grug-far").setup()
		end,
	},
}
