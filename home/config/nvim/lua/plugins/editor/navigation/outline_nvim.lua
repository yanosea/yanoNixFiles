-- a sidebar with a tree-like outline of symbols from the code, powered by LSP
-- keymaps are set in lua/pulugins/tools/internal/which_key_nvim.lua (<LEADER>lo)
return {
	{
		"hedyhli/outline.nvim",
		lazy = true,
		cmd = { "Outline", "OutlineOpen" },
		config = function()
			require("outline").setup()
		end,
	},
}
