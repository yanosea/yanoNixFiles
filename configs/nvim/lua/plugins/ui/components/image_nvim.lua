-- image viewer for image files, markdown, etc.
-- backend auto-switches: sixel inside zellij (no kitty graphics passthrough), kitty otherwise
-- requires ImageMagick (with sixel support for the sixel backend)
-- keymaps are set in lua/plugins/tools/internal/which_key_nvim.lua (<LEADER>I)
return {
	{
		"3rd/image.nvim",
		lazy = true,
		event = { "BufReadPost", "BufNewFile" },
		build = false,
		opts = {
			backend = vim.env.ZELLIJ and "sixel" or "kitty",
			processor = "magick_cli",
		},
	},
}
