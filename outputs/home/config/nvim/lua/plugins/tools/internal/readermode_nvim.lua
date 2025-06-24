-- keeping cursor centered while reading through code/text/whatever
-- keymaps are set in lua/plugins/tools/internal/which_key_nvim.lua (<LEADER>R)
return {
	{
		"sarrisv/readermode.nvim",
		lazy = true,
		cmd = { "ReaderMode" },
		opts = {
			enable = true,
			keymap = "<LEADER>R",
		},
	},
}
