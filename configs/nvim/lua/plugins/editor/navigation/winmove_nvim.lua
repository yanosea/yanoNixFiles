-- window resize, move, and swap modes
return {
	{
		"MisanthropicBit/winmove.nvim",
		lazy = true,
		keys = {
			{
				"<C-w>r",
				function()
					require("winmove").start_mode("resize")
				end,
				desc = "window: resize mode",
			},
			{
				"<C-w>m",
				function()
					require("winmove").start_mode("move")
				end,
				desc = "window: move mode",
			},
			{
				"<C-w>x",
				function()
					require("winmove").start_mode("swap")
				end,
				desc = "window: swap mode",
			},
		},
		config = function()
			require("winmove").configure()
		end,
	},
}
