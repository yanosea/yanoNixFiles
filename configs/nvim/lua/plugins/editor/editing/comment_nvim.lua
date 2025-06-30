-- comment utilizes the same keybinding as the default comment plugin
-- keymaps are set in lua/plugins/tools/internal/which_key_nvim.lua (<LEADER>/)
return {
	{
		"numToStr/Comment.nvim",
		lazy = true,
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			-- Comment.nvim config
			require("Comment").setup()
		end,
	},
}
