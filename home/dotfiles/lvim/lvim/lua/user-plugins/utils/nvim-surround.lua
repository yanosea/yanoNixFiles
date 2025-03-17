-- surround selection with brackets, quotes, etc.
table.insert(lvim.plugins, {
  "kylechui/nvim-surround",
  event = { "BufRead", "BufEnter" },
  config = function()
    require("nvim-surround").setup({
      -- Configuration here, or leave empty to use defaults
    })
  end,
})
