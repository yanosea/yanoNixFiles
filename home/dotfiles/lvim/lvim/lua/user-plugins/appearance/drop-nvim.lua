-- screensaver
table.insert(lvim.plugins, {
  "folke/drop.nvim",
  event = "VimEnter",
  init = function()
    require("drop").setup({
      theme = "leaves",
      max = 20,
      interval = 250,
    })
  end,
})
