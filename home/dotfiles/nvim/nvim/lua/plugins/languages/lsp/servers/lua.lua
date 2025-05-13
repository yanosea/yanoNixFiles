-- lua lsp config
local M = {}
function M.setup()
  local helpers = require("plugins.languages.lsp.utils.helpers")
  vim.lsp.config("lua_ls", {
    settings = {
      Lua = {
        diagnostics = {
          globals = {
            "vim",
            "nvim",
          },
        },
        hint = { enable = true },
        root_markers = {
          ".git",
          ".luacheckrc",
          ".luarc.json",
          ".stylua.toml",
          "stylua.toml",
        },
        runtime = {
          version = "LuaJIT",
          special = {
            reload = "require",
          },
        },
        telemetry = { enable = false },
        workspace = helpers.default_workspace,
      },
    },
  })
end
return M
