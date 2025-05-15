-- update lua_ls config
return {
  {
    "folke/lazydev.nvim",
    lazy = true,
    event = { "BufReadPost", "BufNewFile" },
    ft = { "lua" },
    opts = {
      library = {
        vim.env.VIMRUNTIME,
        "${3rd}/luv/library",
        "${3rd}/busted/library",
        { path = "wezterm-types", mods = { "wezterm" } },
      },
      enabled = function(root_dir)
        return not vim.uv.fs_stat(root_dir .. "/.luarc.json")
      end,
    },
  },
}
