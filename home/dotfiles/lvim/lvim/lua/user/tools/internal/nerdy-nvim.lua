-- search nerd fonts icons with telescope
table.insert(lvim.plugins, {
  "2kabhishek/nerdy.nvim",
  cmd = { "Nerdy" },
  dependencies = {
    "folke/snacks.nvim",
  },
  config = function()
    require("telescope").load_extension("nerdy")
  end,
})
