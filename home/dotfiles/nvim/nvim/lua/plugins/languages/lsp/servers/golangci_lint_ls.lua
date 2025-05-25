-- golangci-lint-ls lsp config
local M = {}
function M.setup()
	vim.lsp.config("golangci-lint-ls", {
		init_options = {
			command = {
				"golangci-lint",
				"run",
				"--output.json.path=stdout",
				"--show-stats=false",
				"--issues-exit-code=1",
			},
		},
	})
end
return M
