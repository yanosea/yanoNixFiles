-- lua lsp config
local M = {}
function M.setup()
	vim.lsp.config("lua_ls", {
		settings = {
			Lua = {
				completion = {
					-- snippets support
					callSnippet = "Both",
					-- lines to show in completion
					displayContext = 1,
					-- keyword completion support
					keywordSnippet = "Both",
				},
				diagnostics = {
					disable = {
						-- disable diagnostics for missing fields
						"missing-fields",
					},
					-- define global variables
					globals = {
						-- hammerspoon
						"hs",
						-- vim
						"vim",
					},
				},
				hint = {
					-- show inline hints
					enable = true,
				},
				runtime = {
					-- lua version
					version = "LuaJIT",
				},
				workspace = {
					-- enable library
					library = vim.api.nvim_get_runtime_file("", true),
					-- enable library for 3rd party libraries
					checkThirdParty = false,
				},
			},
		},
	})
end
return M
