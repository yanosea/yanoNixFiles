-- lua lsp config
-- lua_ls
require("lvim.lsp.manager").setup("lua_ls", {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = {
    ".git",
    ".luacheckrc",
    ".luarc.json",
    ".stylua.toml",
    "stylua.toml",
  },
  init_options = {
    settings = {
      Lua = {
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
  },
})
