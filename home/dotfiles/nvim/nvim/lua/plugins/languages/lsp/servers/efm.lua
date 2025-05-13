-- efm lsp config
local M = {}
function M.setup()
  vim.lsp.config("efm", {
    init_options = {
      documentFormatting = true,
      documentRangeFormatting = true,
    },
    settings = {
      root_markers = {
        ".git",
        ".luacheckrc",
        ".luarc.json",
        ".stylua.toml",
        "stylua.toml",
      },
      languages = {
        lua = {
          require("efmls-configs.formatters.stylua"),
        },
      },
    },
  })
end
return M
