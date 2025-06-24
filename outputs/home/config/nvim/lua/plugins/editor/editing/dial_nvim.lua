-- extend increment and decrement
return {
	{
		"monaqa/dial.nvim",
		lazy = true,
		keys = { "<C-a>", "<C-x>" },
		config = function()
			-- dial.nvim config
			require("dial.config").augends:register_group({
				default = {
					-- number
					require("dial.augend").integer.alias.decimal,
					require("dial.augend").integer.alias.hex,
					-- boolean
					require("dial.augend").constant.alias.bool,
					-- version
					require("dial.augend").semver.alias.semver,
					-- date
					require("dial.augend").date.alias["%Y/%m/%d"],
					require("dial.augend").date.alias["%Y-%m-%d"],
					require("dial.augend").date.alias["%Y年%m月%d日"],
					require("dial.augend").date.alias["%m月%d日"],
				},
			})
			-- keymaps
			vim.keymap.set(
				"n",
				"<C-a>",
				require("dial.map").inc_normal(),
				{ desc = "dial increment", silent = true, noremap = true }
			)
			vim.keymap.set(
				"n",
				"<C-x>",
				require("dial.map").dec_normal(),
				{ desc = "dial decrement", silent = true, noremap = true }
			)
		end,
	},
}
