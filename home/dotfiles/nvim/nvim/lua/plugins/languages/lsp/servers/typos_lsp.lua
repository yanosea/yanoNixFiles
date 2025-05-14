-- typos lsp config
local M = {}
function M.setup()
  vim.lsp.config("*", {
    init_options = {
      config = vim.fn.stdpath("config") .. "/lua/plugins/languages/lsp/servers/config/typos.toml",
      diagnosticSeverity = "hint",
    },
  })
end
return M
