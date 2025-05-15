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
        -- if lazydev is not installed, use the default library paths
        workspace = not pcall(require, "lazydev")
            and {
              -- library paths
              library = {
                vim.env.VIMRUNTIME,
                "${3rd}/luv/library",
                "${3rd}/busted/library",
              },
            }
          or nil,
      },
    },
  })
end
return M
