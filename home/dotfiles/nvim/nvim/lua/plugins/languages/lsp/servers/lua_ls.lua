-- lua lsp config
local M = {}
function M.setup()
  vim.lsp.config("lua_ls", {
    settings = {
      Lua = {
        runtime = {
          version = "LuaJIT",
        },
        workspace = {
          vim.env.VIMRUNTIME,
          "${3rd}/luv/library",
          "${3rd}/busted/library",
        },
        completion = {
          callSnippet = "Both",
          displayContext = 1,
          keywordSnippet = "Both",
        },
        hint = {
          enable = true,
        },
        telemetry = { enable = false },
      },
    },
  })
end
return M
