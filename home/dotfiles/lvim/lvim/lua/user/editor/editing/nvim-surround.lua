-- surround selection with brackets, quotes, etc.
table.insert(lvim.plugins, {
  "kylechui/nvim-surround",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    require("nvim-surround").setup()
  end,
})
