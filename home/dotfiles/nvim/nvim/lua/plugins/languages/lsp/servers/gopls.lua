-- gopls lsp config
local M = {}
function M.setup()
	vim.lsp.config("gopls", {
		init_options = {
			usePlaceholders = true,
			analyses = {
				shadow = true,
			},
			staticcheck = true,
			hints = {
				-- show variable types in assignment statements
				assignVariableTypes = true,
				-- display inferred types for struct literal fields
				compositeLiteralFields = true,
				-- show types for composite literals
				compositeLiteralTypes = true,
				-- show values for constants
				constantValues = true,
				-- display types of function parameters
				functionTypeParameters = true,
				-- show parameter names in function calls
				parameterNames = true,
				-- show types for variables in range statements
				rangeVariableTypes = true,
			},
		},
	})
end
return M
