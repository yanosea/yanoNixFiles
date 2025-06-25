-- yamlls lsp config
local M = {}
function M.setup()
	vim.lsp.config("yamlls", {
		settings = {
			redhat = {
				telemetry = {
					enabled = false,
				},
			},
			schemaStore = {
				enable = false,
				url = "",
			},
			schemas = require("schemastore").yaml.schemas(),
		},
	})
end
return M
