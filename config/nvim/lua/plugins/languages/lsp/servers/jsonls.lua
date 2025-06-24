-- jsonls lsp config
local M = {}
function M.setup()
	vim.lsp.config("jsonls", {
		init_options = {
			schemas = require("schemastore").json.schemas(),
			provideFormatter = true,
			validate = {
				enable = true,
			},
		},
	})
end
return M
