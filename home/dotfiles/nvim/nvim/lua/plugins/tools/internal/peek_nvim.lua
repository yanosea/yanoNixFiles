-- preview markdown in browser
-- keymaps are set in lua/plugins/tools/internal/which_key_nvim.lua (<LEADER>m)
return {
	{
		"toppair/peek.nvim",
		lazy = true,
		ft = { "markdown" },
		build = "deno task --quiet build:fast",
		config = function()
			-- define user commands
			vim.api.nvim_create_user_command("PeekOpen", require("peek").open, {})
			vim.api.nvim_create_user_command("PeekClose", require("peek").close, {})
			-- peek.nvim config
			require("peek").setup({
				auto_load = true,
				close_on_bdelete = true,
				syntax = true,
				theme = "dark",
				update_on_change = true,
				app = "browser",
				filetype = { "markdown" },
				throttle_at = 200000,
				throttle_time = "auto",
			})
		end,
	},
}
