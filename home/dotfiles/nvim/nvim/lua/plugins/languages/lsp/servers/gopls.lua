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
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
    },
  })
end
return M
