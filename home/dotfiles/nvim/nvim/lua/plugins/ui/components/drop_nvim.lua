-- screensaver
return {
  {
    "folke/drop.nvim",
    lazy = true,
    event = "VeryLazy",
    config = function()
      require("drop").setup({
        theme = "leaves",
        max = 20,
        interval = 250,
      })
    end,
  },
}
