-- go dap config
return {
	{
		"leoluz/nvim-dap-go",
		lazy = true,
		ft = { "go" },
		config = function()
			-- dap-go config
			require("dap-go").setup({
				delve = {
					path = "dlv",
					initialize_timeout_sec = 20,
					port = "${port}",
					build_flags = "",
				},
			})
		end,
	},
}
