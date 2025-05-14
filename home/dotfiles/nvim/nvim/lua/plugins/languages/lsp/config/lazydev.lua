-- update lua_ls config
return {
  {
    "folke/lazydev.nvim",
    lazy = true,
    ft = "lua",
    opts = {
      library = {
        "lazy.nvim",
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "wezterm-types", mods = { "wezterm" } },
      },
      enabled = function(root_dir)
        return not vim.uv.fs_stat(root_dir .. "/.luarc.json")
      end,
    },
  },
}
