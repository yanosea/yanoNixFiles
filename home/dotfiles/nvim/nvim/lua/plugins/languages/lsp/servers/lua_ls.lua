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
          -- libraries to include
          library = {
            vim.env.VIMRUNTIME,
            "${3rd}/luv/library",
            "${3rd}/busted/library",
          },
        },
      },
    },
  })
end
return M
