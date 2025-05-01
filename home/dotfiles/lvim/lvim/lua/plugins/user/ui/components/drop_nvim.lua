-- screensaver
table.insert(lvim.plugins, {
  "folke/drop.nvim",
  event = "VeryLazy",
  config = function()
    require("drop").setup({
      theme = "leaves",
      max = 20,
      interval = 250,
    })
  end,
})
