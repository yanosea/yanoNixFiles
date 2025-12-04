-- extend increment and decrement
return {
	{
		"monaqa/dial.nvim",
		lazy = true,
		keys = {
			{
				"<C-a>",
				function()
					require("dial.map").manipulate("increment", "normal")
				end,
				desc = "dial: increment",
			},
			{
				"<C-x>",
				function()
					require("dial.map").manipulate("decrement", "normal")
				end,
				desc = "dial: decrement",
			},
		},
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
		end,
	},
}
