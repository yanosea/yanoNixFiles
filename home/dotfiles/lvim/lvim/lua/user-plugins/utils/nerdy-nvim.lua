-- search nerd fonts icons with telescope
table.insert(lvim.plugins, {
  "2kabhishek/nerdy.nvim",
  dependencies = {
    "folke/snacks.nvim",
  },
  cmd = "Nerdy",
  config = function()
    require("telescope").load_extension("nerdy")
  end,
})
